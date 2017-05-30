from __future__ import absolute_import

from google.protobuf import text_format
from graphdef import get_proto_resolver # relative import?
from layers import LayerAdapter, LayerType, NodeKind, NodeDispatch
from shapes import TensorShape

class GraphBuilder(object):
    '''Constructs a model graph from a Caffe protocol buffer definition.'''
    def __init__(self, def_path, phase='test'):
        '''
        def_path: Path to the model definition (.prototxt)
        data_path: Path to the model data (.caffemodel)
        phase: Either 'test' or 'train'. Used for filtering phase-specific nodes.
        '''
        self.def_path = def_path
        self.phase = phase
        self.load()
        self.print_layers() # for debugging
    def load(self):
        '''Load the layer definitions from the prototxt.'''
        self.params = get_proto_resolver().NetParameter()
        with open(self.def_path, 'rb') as def_file:
            text_format.Merge(def_file.read(), self.params)

    def print_layers(self):
        '''Print the loaded layers '''
        layers = self.params.layers or self.params.layer
        for l in layers: print "new Layer:\n", l

    # Not quite understand why this function is here.
    def filter_layers(self, layers):
        '''Filter out layers based on the current phase.'''
        return layers

    def make_node(self, layer):
        '''Create a graph node for the given layer.'''
        kind = NodeKind.map_raw_kind(layer.type)
        if kind is None:
            raise ValueError('Unknown layer type encountered: %s' % layer.type)
        # We want to use the layer's top names (the "output" names), rather than the
        # name attribute, which is more of readability thing than a functional one.
        # Other layers will refer to a node by its "top name".
        return Node(layer.name, kind, layer=layer)

    def build(self):
        '''
        Builds the graph from the Caffe layer definitions.
        '''
        # Get the layers
        layers = self.params.layers or self.params.layer
        layers = self.filter_layers(layers)
        # Get any separately-specified input layers
        # nodes = self.make_input_nodes() -- no need to consider the old-style input nodes
        nodes = [self.make_node(layer) for layer in layers]
        graph = Graph(nodes=nodes, name=self.params.name)

        # The current implementation only supports single-output nodes (note that a node can still
        # have multiple children, since multiple child nodes can refer to the single top's name).

        # Sorry, but what's the purpose here?
        node_outputs = {}
        for layer in layers:
            node = graph.get_node(layer.name)
            for input_name in layer.bottom:
                assert input_name != layer.name # why?
                parent_node = node_outputs.get(input_name)
                if (parent_node is None) or (parent_node == node):
                    parent_node = graph.get_node(input_name)
                node.add_parent(parent_node)
            if len(layer.top)>1:
                raise ValueError('Multiple top nodes are not supported.')
            for output_name in layer.top:
                if output_name == layer.name:
                    # Output is named the same as the node. No further action required.
                    continue
                # There are two possibilities here:
                #
                # Case 1: output_name refers to another node in the graph.
                # This is an "in-place operation" that overwrites an existing node.
                # This would create a cycle in the graph. We'll undo the in-placing
                # by substituting this node wherever the overwritten node is referenced.
                #
                # Case 2: output_name violates the convention layer.name == output_name.
                # Since we are working in the single-output regime, we will can rename it to
                # match the layer name.
                #
                # For both cases, future references to this top re-routes to this node.
                node_outputs[output_name] = node

                # print node_outputs ---> ???
        graph.compute_output_shapes() #???

        return graph


class Node(object):

    def __init__(self, name, kind, layer=None):
        self.name = name
        self.kind = kind
        self.layer = LayerAdapter(layer, kind) if layer else None
        self.parents = []
        self.children = []
        self.data = None
        self.output_shape = None
        self.metadata = {}

    def add_parent(self, parent_node):
        assert parent_node not in self.parents
        self.parents.append(parent_node)
        if self not in parent_node.children:
            parent_node.children.append(self)

    def add_child(self, child_node):
        assert child_node not in self.children
        self.children.append(child_node)
        if self not in child_node.parents:
            child_node.parents.append(self)

    def get_only_parent(self):
        if len(self.parents) != 1:
            raise ValueError('Node (%s) expected to have 1 parent. Found %s.' %
                             (self, len(self.parents)))
        return self.parents[0]

    @property
    def parameters(self):
        if self.layer is not None:
            return self.layer.parameters
        return None

    def __str__(self):
        return '[%s] %s' % (self.kind, self.name)

    def __repr__(self):
        return '%s (0x%x)' % (self.name, id(self))

class Graph(object):

    def __init__(self, nodes=None, name=None):
        self.nodes = nodes or []
        self.node_lut = {node.name: node for node in self.nodes}
        self.name = name

    def add_node(self, node):
        self.nodes.append(node)
        self.node_lut[node.name] = node

    def get_node(self, name):
        try:
            return self.node_lut[name]
        except KeyError:
            raise ValueError('Layer not found: %s' % name)

    def get_input_nodes(self):
        return [node for node in self.nodes if len(node.parents) == 0]

    def get_output_nodes(self):
        return [node for node in self.nodes if len(node.children) == 0]

    def topologically_sorted(self):
        sorted_nodes = []
        unsorted_nodes = list(self.nodes)
        temp_marked = set()
        perm_marked = set()

        def visit(node):
            if node in temp_marked:
                raise ValueError('Graph is not a DAG.')
            if node in perm_marked:
                return
            temp_marked.add(node)
            for child in node.children:
                visit(child)
            perm_marked.add(node)
            temp_marked.remove(node)
            sorted_nodes.insert(0, node)

        while len(unsorted_nodes):
            visit(unsorted_nodes.pop())
        return sorted_nodes

    def compute_output_shapes(self):
        sorted_nodes = self.topologically_sorted()
        for node in sorted_nodes:
            node.output_shape = TensorShape(*NodeKind.compute_output_shape(node))

    def replaced(self, new_nodes):
        return Graph(nodes=new_nodes, name=self.name)

    def transformed(self, transformers):
        graph = self
        for transformer in transformers:
            graph = transformer(graph)
            if graph is None:
                raise ValueError('Transformer failed: {}'.format(transformer))
            assert isinstance(graph, Graph)
        return graph

    def __contains__(self, key):
        return key in self.node_lut

    def __str__(self):
        hdr = '{:<20} {:<30} {:>20} {:>20}'.format('Type', 'Name', 'Param', 'Output')
        s = [hdr, '-' * 94]
        for node in self.topologically_sorted():
            # If the node has learned parameters, display the first one's shape.
            # In case of convolutions, this corresponds to the weights.
            data_shape = node.data[0].shape if node.data else '--'
            out_shape = node.output_shape or '--'
            s.append('{:<20} {:<30} {:>20} {:>20}'.format(node.kind, node.name, data_shape,
                                                          tuple(out_shape)))
        return '\n'.join(s)


class NodeMapper(NodeDispatch):
    '''Load Node and Decompose DAG into chains,  and map each node in each chains
    with specific mapper functions, e.g. TensorFlowMapper.
    '''

    def __init__(self, graph):
        self.graph = graph

    def map(self):
        nodes = self.graph.topologically_sorted()
        # Remove input nodes - we'll handle them separately.
        input_nodes = self.graph.get_input_nodes()
        nodes = [t for t in nodes if t not in input_nodes]
        # Decompose DAG into chains.
        chains = []
        for node in nodes:
            attach_to_chain = None
            if len(node.parents) == 1:
                parent = node.get_only_parent()
                for chain in chains:
                    if chain[-1] == parent:
                        # Node is part of an existing chain.
                        attach_to_chain = chain
                        break
            if attach_to_chain is None:
                # Start a new chain for this node.
                attach_to_chain = []
                chains.append(attach_to_chain)
            attach_to_chain.append(node)
        # Map each chain.
        mapped_chains = []
        for chain in chains:
            mapped_chains.append(self.map_chain(chain))
        return self.commit(mapped_chains)

    def map_chain(self, chain):
        return [self.map_node(node) for node in chain]

    def map_node(self, node):

        map_func = self.get_handler(node.kind, 'map') # get the "right" name
        mapped_node = map_func(node) # map_funcs implemented in TFMapper
        assert mapped_node is not None
        mapped_node.node = node
        return mapped_node

    def commit(self, mapped_chains):
        raise NotImplementedError('Must be implemented by subclass.')


#test
#path = '/home/stark/models/lenet/lenet.prototxt'
#foo = GraphBuilder(path).build()
