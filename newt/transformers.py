from __future__ import absolute_import

'''
A collection of graph transforms.
A transformer is a callable that accepts a graph and returns a transformed version.
'''

import numpy as np

class NodeRenamer(object):
    '''
    Renames nodes in the graph using a given unary function that
    accepts a node and returns its new name.
    '''

    def __init__(self, renamer):
        self.renamer = renamer

    def __call__(self, graph):
        for node in graph.nodes:
            node.name = self.renamer(node)
        return graph
