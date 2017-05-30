#!/usr/bin/env python
import argparse
import numpy as np
import tensorflow as tf
import os.path as osp
import importlib

#import models
#import dataset

import newt.model
import newt.tensorflow as newtf

# These information should be transparent to users
crop_size = 224
channels = 3

model_dir = newt.model.pull_model('googlenet')
class_name = newtf.import_graph(model_dir)
if class_name is not None:
    try:
        mynet = importlib.import_module(class_name)
    except:
        raise ValueError("Class file %s does not exist!" % class_name + '.py')

input_node = tf.placeholder(tf.float32,
    shape=(None, crop_size, crop_size, channels))

net = mynet.GoogleNet({'data': input_node})
