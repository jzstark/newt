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
class_path, class_name = newtf.import_graph(model_dir)
#mynet = importlib.import_module(class_name)
mynet = importlib.import_module('mynet')

input_node = tf.placeholder(tf.float32,
    shape=(None, crop_size, crop_size, channels))

net = mynet.GoogleNet({'data': input_node})

#def run_inference_on_image(image):

image = osp.expanduser('~/Downloads/panda.jpg')
if not tf.gfile.Exists(image):
    tf.logging.fatal('File does not exist %s', image)
image_data = tf.gfile.FastGFile(image, 'rb').read()

with tf.Session() as sess:
    # Some useful tensors:
    # 'softmax:0': A tensor containing the normalized prediction across
    #   1000 labels.
    # 'pool_3:0': A tensor containing the next-to-last layer containing 2048
    #   float description of the image.
    # 'DecodeJpeg/contents:0': A tensor containing a string providing JPEG
    #   encoding of the image.
    # Runs the softmax tensor by feeding the image_data as input to the graph.
    sess.run(tf.global_variables_initializer())

    newtf.import_weight(model_dir, net, sess)

    #softmax_tensor = sess.graph.get_tensor_by_name('softmax:0')
    #predictions = sess.run(softmax_tensor,
    #                       {'DecodeJpeg/contents:0': image_data})
    #predictions = np.squeeze(predictions)

#image = '~/Downloads/panda.jpg'
#run_inference_on_image(image)
