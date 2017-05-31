import numpy as np
import random
import tensorflow as tf
from tensorflow.examples.tutorials.mnist import input_data
import importlib

import newt.model
import newt.tensorflow as newtf

# TF helper functions
def gen_data(source):
    while True:
        indices = range(len(source.images))
        random.shuffle(indices)
        for i in indices:
            image = np.reshape(source.images[i], (28, 28, 1))
            label = source.labels[i]
            yield image, label

def gen_data_batch(source):
    data_gen = gen_data(source)
    while True:
        image_batch = []
        label_batch = []
        for _ in range(batch_size):
            image, label = next(data_gen)
            image_batch.append(image)
            label_batch.append(label)
        yield np.array(image_batch), np.array(label_batch)

# Pull the Model
model_dir = newt.model.pull_model('lenet')

# Load the Model - graph
class_path = newtf.import_graph(model_dir)

if class_name is not None:
    try:
        mynet = importlib.import_module(class_name)
    except:
        raise ValueError("Class file %s does not exist!" % class_name + '.py')

# Visulize the model in TF: how?
# ????

# Use the model -- depend on programmer, of course
mnist = input_data.read_data_sets('MNIST_data', one_hot=True)
batch_size = 32
images = tf.placeholder(tf.float32, [batch_size, 28, 28, 1])
labels = tf.placeholder(tf.float32, [batch_size, 10])

net = mynet.LeNet({'data': images})

ip2 = net.layers['ip2'] # Depend of programmer's knowledge to manipulate layers
pred = tf.nn.softmax(ip2)
loss = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=ip2, labels=labels), 0)
opt = tf.train.RMSPropOptimizer(0.001)
train_op = opt.minimize(loss)

with tf.Session() as sess:
    sess.run(tf.global_variables_initializer())

    # Load the Model - Weights
    #net.load(model_dir, sess) # .npy data
    newtf.import_weight(model_dir, net, sess)

    data_gen = gen_data_batch(mnist.train)
    for i in range(1000):
        np_images, np_labels = next(data_gen)
        feed = {images: np_images, labels: np_labels}

        np_loss, np_pred, _ = sess.run([loss, pred, train_op], feed_dict=feed)
        if i % 10 == 0:
            print('Iteration: ', i, np_loss)
