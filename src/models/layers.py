# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                               Global Variables                               #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
param = 1e-3
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Layer definition                                 #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
class ConvBlock(tf.keras.Model):
    def __init__(self, num_filters):
        super(ConvBlock, self).__init__()
        self.conv2d = tf.keras.layers.Conv2D(filters=num_filters,
                                             kernel_size=(3, 3),
                                             strides=(1, 1),
                                             padding='same',
                                             kernel_regularizer=tf.keras.regularizers.l2(param), #To limit overfitting
                                             bias_regularizer=tf.keras.regularizers.l2(param)
                                             )
        self.Normalization = tf.keras.layers.BatchNormalization()
        self.activation = tf.keras.layers.LeakyReLU(alpha=0.3)
        self.pooling = tf.keras.layers.MaxPool2D(pool_size=(2, 2))

    def call(self, inputs):
        x = self.conv2d(inputs)
        x = self.Normalization(x)
        x = self.activation(x)
        x = self.pooling(x)
        return x

class ResConvBlock(tf.keras.Model):
    def __init__(self, num_filters):
        super(ResConvBlock, self).__init__()
        self.conv2d = tf.keras.layers.Conv2D(filters=num_filters,
                                             kernel_size=(5, 5),
                                             strides=(1, 1),
                                             padding='same',
                                             kernel_regularizer=tf.keras.regularizers.l2(param), #To limit overfitting
                                             bias_regularizer=tf.keras.regularizers.l2(param)
                                             )
        self.activation = tf.keras.layers.LeakyReLU(alpha=0.3)
        self.pooling = tf.keras.layers.MaxPool2D(pool_size=(2, 2))
        self.add = tf.keras.layers.Concatenate()

    def call(self, inputs):
        x = self.conv2d(inputs)
        x = self.activation(x)
        x = self.add([x, inputs])
        x = self.pooling(x)
        return x
