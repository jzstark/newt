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

from .layer import Layer

class Graph(Layer):
    pass
