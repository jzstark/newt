# Examplar API. One thing that is not clear is the input/output spec of a model:
# What should be exposed to user?

import newt

'''
Load NN model and weights
'''
newt.pull_model('LeNet', '.')
model = newt.Model('model.json')
model.load_weights('weight.bin')

'''
1. Usage in Tensorflow
'''

import tensorflow as tf
from tensorflow.examples.tutorials.mnist import input_data
mnist = input_data.read_data_sets('.', one_hot=True)

with tf.Session() as sess:
    model.restore_tf_session(sess)

    # The required tensors are already loaed
    logits = tf.get_collection('logits')[0]
    labels = tf.get_collection('labels')[0]
    # Tensor "input_data" should also be presented to user

    correct_prediction = tf.equal(tf.argmax(logits, 1), tf.argmax(labels, 1))
    accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))
    print('test accuracy %g' % accuracy.eval(feed_dict={
        input_data: mnist.test.images, labels: mnist.test.labels, keep_prob: 1.0}))

'''
2. Usage in Keras
'''

import keras
from keras.datasets import mnist

k_model = model.to_keras_model()

_, (x_test, y_test) = mnist.load_data()
score = k_model.evaluate(x_test, y_test, verbose=0)

'''
Next Step:
- It is possible that newt format model just can NOT be converted. In that case,
provide interface for converting:
    + model definition file to a local-supported class file
    + weight file to a local-supported weight file (e.g. ckpt file for TF, params file for MxNet)

- Supposed a model is trained on a native framework. Provide interface to export
native data to the newt format graph definition and weight file.
'''
