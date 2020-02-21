# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
from src.models.layers import *
import tensorflow as tf
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                               Global Variables                               #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
num_classes = 10
SEED = 1234
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Models definition                                #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
class CNN_NonPruned(tf.keras.Model):
    def __init__(self, depth_res, depth_conv, start_f, num_classes):
        super(CNN_NonPruned, self).__init__()

        self.feature_extractor = tf.keras.Sequential()

        for i in range(depth_res):
            self.feature_extractor.add(ResConvBlock(num_filters=start_f))
            start_f *= 2
        for i in range(depth_conv):
            self.feature_extractor.add(ConvBlock(num_filters=start_f))
            start_f *= 2
        self.flatten = tf.keras.layers.Flatten()
        self.classifier = tf.keras.Sequential()
        self.classifier.add(tf.keras.layers.Dense(units=256, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.3, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=128, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.25, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=64, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.25, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=num_classes, activation='softmax'))
        self.classifier.add(tf.keras.layers.Dropout(0.2, seed=SEED))

    def call(self, inputs):
        x = self.feature_extractor(inputs)
        x = self.flatten(x)
        x = self.classifier(x)
        return x
