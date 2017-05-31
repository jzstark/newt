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


def process_image(img, scale, isotropic, crop, mean):
    '''Crops, scales, and normalizes the given image.
    scale : The image wil be first scaled to this size.
            If isotropic is true, the smaller side is rescaled to this,
            preserving the aspect ratio.
    crop  : After scaling, a central crop of this size is taken.
    mean  : Subtracted from the image
    '''
    # Rescale
    if isotropic:
        img_shape = tf.to_float(tf.shape(img)[:2])
        min_length = tf.minimum(img_shape[0], img_shape[1])
        new_shape = tf.to_int32((scale / min_length) * img_shape)
    else:
        new_shape = tf.stack([scale, scale])

    # Errors here.
    img = tf.image.resize_images(img, new_shape[0], new_shape[1])
    # Center crop
    # Use the slice workaround until crop_to_bounding_box supports deferred tensor shapes
    # See: https://github.com/tensorflow/tensorflow/issues/521
    offset = (new_shape - crop) / 2
    img = tf.slice(img, begin=tf.stack([offset[0], offset[1], 0]), size=tf.stack([crop, crop, -1]))
    # Mean subtraction
    return tf.to_float(img) - mean

# These information should be transparent to users
crop_size = 224
scale_size = 256
channels = 3

model_dir = newt.model.pull_model('googlenet')
class_path, class_name = newtf.import_graph(model_dir)
mynet = importlib.import_module(class_name)

input_node = tf.placeholder(tf.float32,
    shape=(None, crop_size, crop_size, channels))

net = mynet.GoogleNet({'data': input_node})

#def run_inference_on_image(image):

image = osp.expanduser('~/Downloads/panda.jpg')
if not tf.gfile.Exists(image):
    tf.logging.fatal('File does not exist %s', image)

#image_data = tf.gfile.FastGFile(image, 'rb').read()
image_data = process_image(image, crop_size, False, )

with tf.Session() as sess:
    sess.run(tf.global_variables_initializer())

    newtf.import_weight(model_dir, net, sess)

    # op = sess.graph.get_operations()
    softmax_tensor = net.get_output() # net.layers['loss3_loss3']
    predictions = sess.run(softmax_tensor, feed_dict={input_node: image_data})
    #predictions = sess.run(softmax_tensor,
    #                       {'DecodeJpeg/contents:0': image_data})
    #predictions = np.squeeze(predictions)
