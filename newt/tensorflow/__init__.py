from __future__ import absolute_import
from .transformer import *
from .network import *

import os

def absolute_path(path):
    exp_path = os.path.expanduser(path)
    return os.path.realpath(exp_path)

def import_graph(path):
    path = path + '.prototxt'
    model = TensorFlowTransformer(path)
    class_path = model.code_to_file()
    return absolute_path(class_path), model.graph.name

def import_weight(path, net, sess):
    path = path + '.npy'
    net.load(path, sess)
    return net
