from __future__ import absolute_import
from .transformer import *
from .network import *


def import_graph(path):
    path = path + '.prototxt'
    model = TensorFlowTransformer(path)
    model.code_to_file()
    return model.graph.name

def import_weight(path, net, sess):
    path = path + '.npy'
    net.load(path, sess)
    return net
