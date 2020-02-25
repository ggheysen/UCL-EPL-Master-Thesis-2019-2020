# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
from src.models.layers import *
import tensorflow as tf
from tensorflow_model_optimization.sparsity import keras as sparsity
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                               Global Variables                               #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
num_classes = 10
SEED = 1234
img_h = 32
img_w = 32
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Models definition                                #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
class CNN_NonPruned(tf.keras.Model):
    def __init__(self, depth, start_f, num_classes):
        super(CNN_NonPruned, self).__init__()
        tf.keras.backend.set_floatx('float32')
        self.feature_extractor = tf.keras.Sequential()
        init_f = 3
        for i in range(depth):
            self.feature_extractor.add(ResConvBlock(num_filters=start_f))
            start_f = (start_f + init_f ) * 2
            init_f = start_f
        self.flatten = tf.keras.layers.Flatten()
        self.classifier = tf.keras.Sequential()
        self.classifier.add(tf.keras.layers.Dense(units=2048, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.3, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=512, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.3, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=128, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.25, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=32, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.25, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=num_classes, activation='softmax'))

    def call(self, inputs):
        x = self.feature_extractor(inputs)
        x = self.flatten(x)
        x = self.classifier(x)
        return x

    def model(self):
        x = tf.keras.layers.Input(shape=(img_h, img_w, 3))
        return tf.keras.Model(inputs=[x], outputs=self.call(x))

    def cl(self):
        ret = tf.keras.Sequential()
        shape = self.feature_extractor.output_shape[1] * self.feature_extractor.output_shape[2] * self.feature_extractor.output_shape[3]
        x = tf.keras.layers.Input(shape=shape)
        for layer in self.classifier.layers:
            ret.add(layer)
        return tf.keras.Model(inputs=[x], outputs=ret.call(x))

    def f_e(self):
        ret = tf.keras.Sequential()
        x = tf.keras.layers.Input(shape=(img_h, img_w, 3))
        for layer in self.feature_extractor.layers:
            ret.add(layer)
        return tf.keras.Model(inputs=[x], outputs=ret.call(x))

class CNN_UnstructuredPruning(CNN_NonPruned):
    def __init__(self, depth, start_f, num_classes):
        super(CNN_UnstructuredPruning, self).__init__(depth=depth, start_f=start_f, num_classes=num_classes)
        self.feature_extractor = tf.keras.Sequential()
        init_f = 3
        for i in range(depth):
            self.feature_extractor.add(PrunableResConvBlock(num_filters=start_f))
            start_f = (start_f + init_f ) * 2
            init_f = start_f


    def pruning(self, **kwargs):
        #self.feature_extractor = sparsity.prune_low_magnitude(self.feature_extractor, **kwargs)
        self.classifier = sparsity.prune_low_magnitude(self.classifier, **kwargs)

    def strip_prn(self):
        #self.feature_extractor = sparsity.strip_pruning(self.feature_extractor)
        self.classifier = sparsity.strip_pruning(self.classifier)


