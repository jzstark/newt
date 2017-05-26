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
        return nodes


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


#test
path = '/home/stark/models/lenet/lenet.prototxt'
foo = GraphBuilder(path).build()
