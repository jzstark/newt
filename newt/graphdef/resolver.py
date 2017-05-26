import sys
from . import caffe_pb2

class ProtoResolver(object):
    def __init__(self):
        self.pb = caffe_pb2
        self.NetParameter = self.pb.NetParameter

def get_proto_resolver():
    return ProtoResolver()
