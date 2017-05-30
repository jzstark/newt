from newt.tensorflow import Network

class GoogleNet(Network):
    def setup(self):
        (self.feed('data')
             .conv(7, 7, 64, 2, 2, relu=False, name='conv1/7x7_s2')
             .relu(name='conv1/relu_7x7')
             .max_pool(3, 3, 2, 2, name='pool1/3x3_s2')
             .lrn(2, 1.99999994948e-05, 0.75, name='pool1/norm1')
             .conv(1, 1, 64, 1, 1, relu=False, name='conv2/3x3_reduce')
             .relu(name='conv2/relu_3x3_reduce')
             .conv(3, 3, 192, 1, 1, relu=False, name='conv2/3x3')
             .relu(name='conv2/relu_3x3')
             .lrn(2, 1.99999994948e-05, 0.75, name='conv2/norm2')
             .max_pool(3, 3, 2, 2, name='pool2/3x3_s2')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_3a/1x1')
             .relu(name='inception_3a/relu_1x1'))

        (self.feed('pool2/3x3_s2')
             .conv(1, 1, 96, 1, 1, relu=False, name='inception_3a/3x3_reduce')
             .relu(name='inception_3a/relu_3x3_reduce')
             .conv(3, 3, 128, 1, 1, relu=False, name='inception_3a/3x3')
             .relu(name='inception_3a/relu_3x3'))

        (self.feed('pool2/3x3_s2')
             .conv(1, 1, 16, 1, 1, relu=False, name='inception_3a/5x5_reduce')
             .relu(name='inception_3a/relu_5x5_reduce')
             .conv(5, 5, 32, 1, 1, relu=False, name='inception_3a/5x5')
             .relu(name='inception_3a/relu_5x5'))

        (self.feed('pool2/3x3_s2')
             .max_pool(3, 3, 1, 1, name='inception_3a/pool')
             .conv(1, 1, 32, 1, 1, relu=False, name='inception_3a/pool_proj')
             .relu(name='inception_3a/relu_pool_proj'))

        (self.feed('inception_3a/relu_1x1', 
                   'inception_3a/relu_3x3', 
                   'inception_3a/relu_5x5', 
                   'inception_3a/relu_pool_proj')
             .concat(3, name='inception_3a/output')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_3b/1x1')
             .relu(name='inception_3b/relu_1x1'))

        (self.feed('inception_3a/output')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_3b/3x3_reduce')
             .relu(name='inception_3b/relu_3x3_reduce')
             .conv(3, 3, 192, 1, 1, relu=False, name='inception_3b/3x3')
             .relu(name='inception_3b/relu_3x3'))

        (self.feed('inception_3a/output')
             .conv(1, 1, 32, 1, 1, relu=False, name='inception_3b/5x5_reduce')
             .relu(name='inception_3b/relu_5x5_reduce')
             .conv(5, 5, 96, 1, 1, relu=False, name='inception_3b/5x5')
             .relu(name='inception_3b/relu_5x5'))

        (self.feed('inception_3a/output')
             .max_pool(3, 3, 1, 1, name='inception_3b/pool')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_3b/pool_proj')
             .relu(name='inception_3b/relu_pool_proj'))

        (self.feed('inception_3b/relu_1x1', 
                   'inception_3b/relu_3x3', 
                   'inception_3b/relu_5x5', 
                   'inception_3b/relu_pool_proj')
             .concat(3, name='inception_3b/output')
             .max_pool(3, 3, 2, 2, name='pool3/3x3_s2')
             .conv(1, 1, 192, 1, 1, relu=False, name='inception_4a/1x1')
             .relu(name='inception_4a/relu_1x1'))

        (self.feed('pool3/3x3_s2')
             .conv(1, 1, 96, 1, 1, relu=False, name='inception_4a/3x3_reduce')
             .relu(name='inception_4a/relu_3x3_reduce')
             .conv(3, 3, 208, 1, 1, relu=False, name='inception_4a/3x3')
             .relu(name='inception_4a/relu_3x3'))

        (self.feed('pool3/3x3_s2')
             .conv(1, 1, 16, 1, 1, relu=False, name='inception_4a/5x5_reduce')
             .relu(name='inception_4a/relu_5x5_reduce')
             .conv(5, 5, 48, 1, 1, relu=False, name='inception_4a/5x5')
             .relu(name='inception_4a/relu_5x5'))

        (self.feed('pool3/3x3_s2')
             .max_pool(3, 3, 1, 1, name='inception_4a/pool')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_4a/pool_proj')
             .relu(name='inception_4a/relu_pool_proj'))

        (self.feed('inception_4a/relu_1x1', 
                   'inception_4a/relu_3x3', 
                   'inception_4a/relu_5x5', 
                   'inception_4a/relu_pool_proj')
             .concat(3, name='inception_4a/output')
             .conv(1, 1, 160, 1, 1, relu=False, name='inception_4b/1x1')
             .relu(name='inception_4b/relu_1x1'))

        (self.feed('inception_4a/output')
             .conv(1, 1, 112, 1, 1, relu=False, name='inception_4b/3x3_reduce')
             .relu(name='inception_4b/relu_3x3_reduce')
             .conv(3, 3, 224, 1, 1, relu=False, name='inception_4b/3x3')
             .relu(name='inception_4b/relu_3x3'))

        (self.feed('inception_4a/output')
             .conv(1, 1, 24, 1, 1, relu=False, name='inception_4b/5x5_reduce')
             .relu(name='inception_4b/relu_5x5_reduce')
             .conv(5, 5, 64, 1, 1, relu=False, name='inception_4b/5x5')
             .relu(name='inception_4b/relu_5x5'))

        (self.feed('inception_4a/output')
             .max_pool(3, 3, 1, 1, name='inception_4b/pool')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_4b/pool_proj')
             .relu(name='inception_4b/relu_pool_proj'))

        (self.feed('inception_4b/relu_1x1', 
                   'inception_4b/relu_3x3', 
                   'inception_4b/relu_5x5', 
                   'inception_4b/relu_pool_proj')
             .concat(3, name='inception_4b/output')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_4c/1x1')
             .relu(name='inception_4c/relu_1x1'))

        (self.feed('inception_4b/output')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_4c/3x3_reduce')
             .relu(name='inception_4c/relu_3x3_reduce')
             .conv(3, 3, 256, 1, 1, relu=False, name='inception_4c/3x3')
             .relu(name='inception_4c/relu_3x3'))

        (self.feed('inception_4b/output')
             .conv(1, 1, 24, 1, 1, relu=False, name='inception_4c/5x5_reduce')
             .relu(name='inception_4c/relu_5x5_reduce')
             .conv(5, 5, 64, 1, 1, relu=False, name='inception_4c/5x5')
             .relu(name='inception_4c/relu_5x5'))

        (self.feed('inception_4b/output')
             .max_pool(3, 3, 1, 1, name='inception_4c/pool')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_4c/pool_proj')
             .relu(name='inception_4c/relu_pool_proj'))

        (self.feed('inception_4c/relu_1x1', 
                   'inception_4c/relu_3x3', 
                   'inception_4c/relu_5x5', 
                   'inception_4c/relu_pool_proj')
             .concat(3, name='inception_4c/output')
             .conv(1, 1, 112, 1, 1, relu=False, name='inception_4d/1x1')
             .relu(name='inception_4d/relu_1x1'))

        (self.feed('inception_4c/output')
             .conv(1, 1, 144, 1, 1, relu=False, name='inception_4d/3x3_reduce')
             .relu(name='inception_4d/relu_3x3_reduce')
             .conv(3, 3, 288, 1, 1, relu=False, name='inception_4d/3x3')
             .relu(name='inception_4d/relu_3x3'))

        (self.feed('inception_4c/output')
             .conv(1, 1, 32, 1, 1, relu=False, name='inception_4d/5x5_reduce')
             .relu(name='inception_4d/relu_5x5_reduce')
             .conv(5, 5, 64, 1, 1, relu=False, name='inception_4d/5x5')
             .relu(name='inception_4d/relu_5x5'))

        (self.feed('inception_4c/output')
             .max_pool(3, 3, 1, 1, name='inception_4d/pool')
             .conv(1, 1, 64, 1, 1, relu=False, name='inception_4d/pool_proj')
             .relu(name='inception_4d/relu_pool_proj'))

        (self.feed('inception_4d/relu_1x1', 
                   'inception_4d/relu_3x3', 
                   'inception_4d/relu_5x5', 
                   'inception_4d/relu_pool_proj')
             .concat(3, name='inception_4d/output')
             .conv(1, 1, 256, 1, 1, relu=False, name='inception_4e/1x1')
             .relu(name='inception_4e/relu_1x1'))

        (self.feed('inception_4d/output')
             .conv(1, 1, 160, 1, 1, relu=False, name='inception_4e/3x3_reduce')
             .relu(name='inception_4e/relu_3x3_reduce')
             .conv(3, 3, 320, 1, 1, relu=False, name='inception_4e/3x3')
             .relu(name='inception_4e/relu_3x3'))

        (self.feed('inception_4d/output')
             .conv(1, 1, 32, 1, 1, relu=False, name='inception_4e/5x5_reduce')
             .relu(name='inception_4e/relu_5x5_reduce')
             .conv(5, 5, 128, 1, 1, relu=False, name='inception_4e/5x5')
             .relu(name='inception_4e/relu_5x5'))

        (self.feed('inception_4d/output')
             .max_pool(3, 3, 1, 1, name='inception_4e/pool')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_4e/pool_proj')
             .relu(name='inception_4e/relu_pool_proj'))

        (self.feed('inception_4e/relu_1x1', 
                   'inception_4e/relu_3x3', 
                   'inception_4e/relu_5x5', 
                   'inception_4e/relu_pool_proj')
             .concat(3, name='inception_4e/output')
             .max_pool(3, 3, 2, 2, name='pool4/3x3_s2')
             .conv(1, 1, 256, 1, 1, relu=False, name='inception_5a/1x1')
             .relu(name='inception_5a/relu_1x1'))

        (self.feed('pool4/3x3_s2')
             .conv(1, 1, 160, 1, 1, relu=False, name='inception_5a/3x3_reduce')
             .relu(name='inception_5a/relu_3x3_reduce')
             .conv(3, 3, 320, 1, 1, relu=False, name='inception_5a/3x3')
             .relu(name='inception_5a/relu_3x3'))

        (self.feed('pool4/3x3_s2')
             .conv(1, 1, 32, 1, 1, relu=False, name='inception_5a/5x5_reduce')
             .relu(name='inception_5a/relu_5x5_reduce')
             .conv(5, 5, 128, 1, 1, relu=False, name='inception_5a/5x5')
             .relu(name='inception_5a/relu_5x5'))

        (self.feed('pool4/3x3_s2')
             .max_pool(3, 3, 1, 1, name='inception_5a/pool')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_5a/pool_proj')
             .relu(name='inception_5a/relu_pool_proj'))

        (self.feed('inception_5a/relu_1x1', 
                   'inception_5a/relu_3x3', 
                   'inception_5a/relu_5x5', 
                   'inception_5a/relu_pool_proj')
             .concat(3, name='inception_5a/output')
             .conv(1, 1, 384, 1, 1, relu=False, name='inception_5b/1x1')
             .relu(name='inception_5b/relu_1x1'))

        (self.feed('inception_5a/output')
             .conv(1, 1, 192, 1, 1, relu=False, name='inception_5b/3x3_reduce')
             .relu(name='inception_5b/relu_3x3_reduce')
             .conv(3, 3, 384, 1, 1, relu=False, name='inception_5b/3x3')
             .relu(name='inception_5b/relu_3x3'))

        (self.feed('inception_5a/output')
             .conv(1, 1, 48, 1, 1, relu=False, name='inception_5b/5x5_reduce')
             .relu(name='inception_5b/relu_5x5_reduce')
             .conv(5, 5, 128, 1, 1, relu=False, name='inception_5b/5x5')
             .relu(name='inception_5b/relu_5x5'))

        (self.feed('inception_5a/output')
             .max_pool(3, 3, 1, 1, name='inception_5b/pool')
             .conv(1, 1, 128, 1, 1, relu=False, name='inception_5b/pool_proj')
             .relu(name='inception_5b/relu_pool_proj'))

        (self.feed('inception_5b/relu_1x1', 
                   'inception_5b/relu_3x3', 
                   'inception_5b/relu_5x5', 
                   'inception_5b/relu_pool_proj')
             .concat(3, name='inception_5b/output')
             .avg_pool(7, 7, 1, 1, padding='VALID', name='pool5/7x7_s1')
             .dropout(0.40000000596, name='pool5/drop_7x7_s1')
             .fc(5, relu=False, name='loss3/classifier-sos')
             .softmax(name='loss3/loss3'))