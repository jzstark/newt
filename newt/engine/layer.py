# -*- coding: utf-8 -*-
from __future__ import print_function
from __future__ import absolute_import
from __future__ import division

import numpy as np
import json
import yaml
import warnings
import copy
import os
import re
import inspect
from six.moves import zip
try:
    import h5py
except ImportError:
    h5py = None

# Provide unique id for each layer
from collections import defaultdict
_UID_PREFIXES = defaultdict(int)

# Namespace for Layer.__call__()
from contextlib import contextmanager
NAME_SCOPE_STACK = []

class InputSpec(object):
    """Specifies the ndim, dtype and shape of every input to a layer.

    Every layer should expose (if appropriate) an `input_spec` attribute:
    a list of instances of InputSpec (one per input tensor).

    A None entry in a shape is compatible with any dimension,
    a None shape is compatible with any shape.

    # Arguments
        dtype: Expected datatype of the input.
        shape: Shape tuple, expected shape of the input
            (may include None for unchecked axes).
        ndim: Integer, expected rank of the input.
        max_ndim: Integer, maximum rank of the input.
        min_ndim: Integer, minimum rank of the input.
        axes: Dictionary mapping integer axes to
            a specific dimension value.
    """

    def __init__(self, dtype = None,
                shape = None,
                ndim = None,
                max_dim = None,
                min_dim = None,
                axes = None):
        self.dtype = dtype
        self.shape = shape
        if shape is not None:
            self.ndim = len(shape)
        else:
            self.ndim = ndim
        self.max_ndim = max_ndim
        self.min_ndim = min_ndim
        self.axes = axes or {}

class Node(object):
    '''
    A `Node` describes the connectivity between two layers.

    Each time a layer is connected to some new input,
    a node is added to `layer.inbound_nodes`.
    Each time the output of a layer is used by another layer,
    a node is added to `layer.outbound_nodes`.

    `input_tensors[i] == inbound_layers[i]
                        .inbound_nodes[node_indices[i]]
                        .output_tensors[tensor_indices[i]]`
    '''

    def __init__(sefl, outbound_layer,
                inbound_layers, node_indices, tensor_indices,
                input_tensors, output_tensors,
                input_masks, output_masks,
                input_shapes, output_shapes,
                arguments = None):
        # f.call(): input_tensors --> output_tensors
        self.outbound_layer = outbound_layer
        # List: layer instance
        self.inbound_layers = inbound_layers
        # Lists: integer
        self.node_indices = node_indices
        self.tensor_indices = tensor_indices
        # List: tensors
        self.input_tensors = input_tensors
        self.output_tensors = output_tensors
        # List: tensors
        self.input_masks = input_masks
        self.output_masks = output_masks # outbound_layer.compute_mask()
        # List: shape tuples for input/output_tensors
        self.input_shapes = input_shapes
        self.output_shapes = output_shapes
        # arguments to f.call
        self.arguments = arguments

        # Link this node to both inbound and outbound layer(s)
        for layer in inbound_layers:
            if layer is not None:
                layer.outbound_nodes.append(self)
        outbound_layer.inbound_nodes.append(self)

    def get_config(self):
        inbound_names = []
        for layer in self.inbound_layers:
            if layer:
                inbound_names.append(layer.name)
            else:
                inbound_names.append(None)
        return {
            'outbound_layer': self.outbound_layer.name if self.outbound_layer else None,
            'inbound_layers': inbound_names,
            'node_indices': self.node_indices,
            'tensor_indices': self.tensor_indices
        }

class Layer(object):
    """Abstract base layer class.

    # Properties
        name: String, must be unique within a model.
        input_spec: List of InputSpec class instances
            each entry describes one required input:
                - ndim
                - dtype
            A layer with `n` input tensors must have
            an `input_spec` of length `n`.
        trainable: Boolean, whether the layer weights
            will be updated during training.
        uses_learning_phase: Whether any operation
            of the layer uses `K.in_training_phase()`
            or `K.in_test_phase()`.
        input_shape: Shape tuple. Provided for convenience,
            but note that there may be cases in which this
            attribute is ill-defined (e.g. a shared layer
            with multiple input shapes), in which case
            requesting `input_shape` will raise an Exception.
            Prefer using `layer.get_input_shape_for(input_shape)`,
            or `layer.get_input_shape_at(node_index)`.
        output_shape: Shape tuple. See above.
        inbound_nodes: List of nodes.
        outbound_nodes: List of nodes.
        input, output: Input/output tensor(s). Note that if the layer is used
            more than once (shared layer), this is ill-defined
            and will raise an exception. In such cases, use
            `layer.get_input_at(node_index)`.
        input_mask, output_mask: Same as above, for masks.
        trainable_weights: List of variables.
        non_trainable_weights: List of variables.
        weights: The concatenation of the lists trainable_weights and
            non_trainable_weights (in this order).
        constraints: Dict mapping weights to constraints.

    # Methods
        call(x, mask=None): Where the layer's logic lives.
        __call__(x, mask=None): Wrapper around the layer logic (`call`).
            If x is a Keras tensor:
                - Connect current layer with last layer from tensor:
                    `self._add_inbound_node(last_layer)`
                - Add layer to tensor history
            If layer is not built:
                - Build from x._keras_shape
        get_weights()
        set_weights(weights)
        get_config()
        count_params()
        compute_output_shape(input_shape)
        compute_mask(x, mask)
        get_input_at(node_index)
        get_output_at(node_index)
        get_input_shape_at(node_index)
        get_output_shape_at(node_index)
        get_input_mask_at(node_index)
        get_output_mask_at(node_index)

    # Class Methods
        from_config(config)

    # Internal methods:
        build(input_shape)
        _add_inbound_node(layer, index=0)
        assert_input_compatibility()
    """
    def __init__(self, **kwargs):
        self.input_spec = None
        self.supports_masking = False

        # These properties will be set upon call of self.build()
        self._trainable_weights = []
        self._non_trainable_weights = []
        self._constraints = {} # dict[tensor/weight] = constra instance
        self._losses = []
        self._updates = []
        self._per_input_losses = {}
        self._per_input_updates = {}
        self._built = False

        # Filled by self._add_inbound_node()
        self.inbound_nodes = []
        self.outbound_nodes = []

        #
        allowed_kwargs = {'input_shape', 'batch_input_shape',
            'batch_size', 'dtype', 'name', 'trainable', 'weights'}

        for kwarg in kwargs:
            if kwarg not in allowed_kwargs:
                raise TypeError('Keyword argument not understood:', kwarg)

        # User provide or create a name for this layer
        name = kwarg.get('name')
        if not name:
            prefix = self.__class__.__name__
            name = _to_snake_case(prefix) + '_' + str(get_uid(prefix))
        self.name = name

        # trainable
        self.trainable = kwargs.get('trainable', True)

        # batch_input_shape
        if 'input_shape' in kwargs or 'batch_input_shape' in kwargs:
            if 'batch_input_shape' in kwargs:
                 batch_input_shape = tuple(kwargs['batch_input_shape'])
            elif 'input_shape' in kwargs:
                 if 'batch_size' in kwargs:
                     batch_size = kwargs['batch_size']
                 else:
                     batch_size = None
                 batch_input_shape = (batch_size, ) + tuple(kwargs['input_shape'])
        self.batch_input_shape = batch_input_shape

        # Datatype
        dtype = kwargs.get('dtype')
        self.dtype = dtype if dtype is not None else _floatx()

        # Weights
        if 'weights' in kwargs:
            self._initial_weights = kwargs['weights']
        else:
            self._initial_weights = None

    @property
    def losses(self):
        return self._losses

    @property
    def updates(self):
        return self._updates

    @property
    def built(self):
        return self._built

    @built.setter
    def built(self, value):
        self._built = value

    @property
    def constraints(self):
        return self._constraints

    @constraints.setter
    def constraints(self, constraints):
        self._constraints = constraints

    @property
    def trainable_weights(self):
        trainable = getattr(self, 'trainable', True)
        return self._trainable_weights if trainable else []

    @trainable_weights.setter
    def trainable_weights(self, weights):
        self._trainable_weights = weights

    @property
    def non_trainable_weights(self):
        trainable = getattr(self, 'trainable', True)
        if not trainable:
            return self._trainable_weights + self._non_trainable_weights
        else:
            return self._non_trainable_weights

    @non_trainable_weights.setter
    def non_trainable_weights(self, weights):
        self._non_trainable_weights = weights

    # Skip the legacy add_weight function here

    def assert_input_compatibility(self, inputs):
        """Check compatibility between the layer and provided inputs.
        Inputs: List of input tensor(s)
        """
        inputs = _to_list(inputs)
        # All input should be tensors, the definition of which should be delegated to
        # lower layer. For example, tensor definition in TF:
        # tf.Tensor, tf.SparseTensor, and tensorflow.python.ops.variables.Variable
        # assert all(is_tensor(i) for i in inputs)

        # input_spec format
        if not self.input_spec: return
        if not isinstance(self.input_spec, (list, tuple)):
            input_spec = _to_list(self.input_spec)
        else:
            input_spec = self.input_spec

        # Number of tensors.
        if len(inputs) != len(input_spec):
            raise ValueError('Layer ' + self.name + ' expects ' +
                             str(len(input_spec)) + ' inputs, '
                             'but it received ' + str(len(inputs)) +
                             ' input tensors. Input received: ' +
                             str(inputs))
        # Each input matches a input_spec
        for input_index, (x, spec) in enumerate(zip(inputs, input_spec)):
            if spec is None:
                continue
            # Compare spec.ndim/dtype/shape/axes with K.ndim/dtype/int_shape(x)
            # which again, relies on lower level

    def call(self, inputs, **kwargs):
        # To be overwritten in sub class
        return inputs

    def __call__(self, inputs, **kwargs):
        """Wrapper around self.call(), for handling internal references.

        inputs: list of tensors
        """

        with name_scope(self.name):
            if not self.buit:
                self.assert_input_compatibility(inputs)

                input_shapes = []
                for x in _to_list(inputs):
                    if hasattr(x, '_keras_shape'):
                        input_shapes.append(x._keras_shape)
                    #elif hasattr(x, 'input_shape'):
                    #    input_shape.append(K.input_shape(x))
                    else:
                        raise ValueError('You tried to call layer "' + self.name +
                                         '". This layer has no information'
                                         ' about its expected input shape, '
                                         'and thus cannot be built. '
                                         'You can build it manually via: '
                                         '`layer.build(batch_input_shape)`')
                # Build with tuple of integer
                self.build(_head_or_list(input_shapes))
                self.built = True

                # Load weight
                if self._initial_weights is not None:
                    self.set_weights(self._initial_weights)

            self.assert_input_compatibility(inputs)

            # Handle mask propagation
            previous_mask = _collect_previous_mask(inputs)
            user_kwargs = copy.copy(kwargs)
            if not _is_all_none(previous_mask):
                # The previous layer generated a mask
                # getargspect: Get the names and default values of a Python
                # function’s arguments
                if 'mask' in inspect.getargspect(self.call).args:
                    # If mask is explicitly passed to __call__,
                    # we should override the default mask.
                    if 'mask' not in kwargs:
                        kwargs['mask'] = previous_mask

            # Handle automatic shape inference
            input_shape = _collect_input_shape(inputs)

            # Actually call the layer, collecting output(s), mask(s), and shape(s).
            output = self.call(inputs, **kwargs)
            output_mask = self.compute_mask(inputs, previous_mask)

            # If the layer returns tensors from its inputs, unmodified,
            # we copy them to avoid loss of tensor metadata.
            output_ls = _to_list(output)
            inputs_ls = _to_list(inputs)
            output_ls_copy = []
            for x in output_ls:
                if x in inputs_ls:
                    output_ls_copy.append(x.copy())
            output = _head_or_list(output_ls_copy)

            # Infering the output shape (?)
            if _is_all_none(input_shape):
                output_shape = self.compute_output_shape(input_shape)
            else:
                if isinstance(input_shape, list):
                    output_shape = [None for _ in input_shape]
                else:
                    output_shape = None

            # Add an inbound node to the layer, so that it keeps track
            # of the call and of all new variables created during the call.
            # This also updates the layer history of the output tensor(s).
            # If the input tensor(s) had not previous Keras history,
            # this does nothing.
            self._add_inbound_node(input_tensors=inputs, output_tensors=output,
                                   input_masks=previous_mask, output_masks=output_mask,
                                   input_shapes=input_shape, output_shapes=output_shape,
                                   arguments=user_kwargs)

            # Apply activity regularizer if any (implemented per specific layer):
            if hasattr(self, 'activity_regularizer') and self.activity_regularizer is not None:
                regularization_losses = [self.activity_regularizer(x) for x in _to_list(output)]
                self.add_loss(regularization_losses, _to_list(inputs))
        return output


    def build(self, input_shape):
        """ Should be implemented on all layers that have weights
        """
        self.built = True

    def set_weights(self, weights):
        """Sets the weights of the layer, from Numpy arrays.

        # Arguments
            weights: a list of Numpy arrays.

        Note: self.weights is not weight number, but rather a collection of
        variables that has implemented the get/set_value methods
        """

        # this whole function is similar to:
        # for p, w in zip(self.weights, weights):
        #    p.set_value(np.asarray(w, dtype=p.dtype))

        params = self.weights
        if len(params) != len(weights):
            raise ValueError('You called `set_weights(weights)` on layer "' +
                             self.name +
                             '" with a  weight list of length ' +
                             str(len(weights)) +
                             ', but the layer was expecting ' +
                             str(len(params)) +
                             ' weights. Provided weights: ' +
                             str(weights)[:50] + '...')
        if not params:
            return

        weight_values = []
        params_values = batch_get_value(params)
        for pv, p, w in zip(param_values, params, weights):
            if pv.shape != w.shape:
                raise ValueError('Layer weight shape ' +
                                 str(pv.shape) +
                                 ' not compatible with '
                                 'provided weight shape ' + str(w.shape))
            weight_values.append((p, w))
        batch_set_value(weight_values)

    def get_weights(self):
        params = self.weights
        return batch_get_value(params)

    def compute_mask(self, inputs, mask=None):
        """Check if masking is supported
        """
        if self.supports_masking:
            # if masking is explictly supported, by default
            # carry over the input mask
            return mask

        if mask is not None:
            if isinstance(mask, list):
                if any(m is not None for m in mask):
                    raise TypeError('Layer ' + self.name +
                                    ' does not support masking, '
                                    'but was passed an input_mask: ' +
                                    str(mask))
            else:
                raise TypeError('Layer ' + self.name +
                                ' does not support masking, '
                                'but was passed an input_mask: ' +
                                str(mask))
            # masking not explicitly supported: return None as mask
            return None

    def compute_output_shape(self, input_shape):
        """Check the output shape of the layer.

        """
        if hasattr(self, 'get_output_shape_for'):
            msg = "Class `{}.{}` defines `get_output_shape_for` but does not override `compute_output_shape`. " + \
                  "If this is a Keras 1 layer, please implement `compute_output_shape` to support Keras 2."
            warnings.warn(msg.format(type(self).__module__, type(self).__name__), stacklevel=2)
        return input_shape

class InputLayer(Layer):
    pass


def _floatx(): return 'float32'

def Input(shape=None, batch_shape=None,
          name=None, dtype=_floatx(), sparse=False,
          tensor=None):
    pass

# General helper function
# ============================
def _to_snake_case(name):
    intermediate = re.sub('(.)([A-Z][a-z0-9]+)', r'\1_\2', name)
    insecure = re.sub('([a-z])([A-Z])', r'\1_\2', intermediate).lower()
    # If the class is private the name starts with "_" which is not secure
    # for creating scopes. We prefix the name with "private" in this case.
    if insecure[0] != '_':
        return insecure
    return 'private' + insecure

def _to_list(x):
    if isinstance(x, list):
        return x
    return [x]

def _is_all_none(iterable_or_element):
    if not isinstance(iterable_or_element, (list, tuple)):
        iterable = [iterable_or_element]
    else:
        iterable = iterable_or_element
    if any(ele is not None for ele in iterable):
        return False
    return True

def _head_or_list(xs):
    return xs[0] if len(xs) == 1 else xs


# ============================

# Helper function
# ============================
def _collect_previous_mask(input_tensors):
    """Retrieves the output mask(s) of the previous node.
    """
    inputs = _to_list(input_tensors)
    masks = []
    for x in inputs:
        if hasattr(x, '_keras_history'):
            inbound_layer, node_index, tensor_index = x._keras_history
            node = inbound_layer.inbound_nodes[node_index]
            mask = node.output_mask[tensor_index]
            mask.append(mask)
        else:
            masks.append(None)
    return _head_or_list(masks)

def _collect_input_shape(input_tensors):
    """Collects the output shape(s) of a list of tensors.
    # Returns: List of shape tuple(s), one tuple per input.
    """
    input_tensors = _to_list(input_tensors)
    shapes = []
    for x in input_tensors:
        try:
            shapes.append(x.int_shape())
        except TypeError:
            shapes.append(None)
    return _head_or_list(shapes)
# ============================


# Lower Level functions
# ===========================
def get_uid(prefix=''):
    # Provides a unique UID given a string prefix.
    _UID_PREFIXES[prefix] += 1
    return _UID_PREFIXES[prefix]

def reset_uids():
    global _UID_PREFIXES
    _UID_PREFIXES = defaultdict(int)

@contextmanager
def name_scope(name):
    global NAME_SCOPE_STACK
    NAME_SCOPE_STACK.append(name)
    yield
    NAME_SCOPE_STACK.pop()

def batch_get_value(xs):
    if not hasattr(x, 'get_value'):
        raise TypeError('get_value() can only be called on a variable. '
                        'If you have an expression instead, use eval().')
    return [x.get_value() for x in xs]
    # for TF:
    # return get_session().run(xs) # xs are ops

def batch_set_value(tuples):
    for x, value in tuples:
        x.set_value(np.asarray(value, dtype=x.dtype))
