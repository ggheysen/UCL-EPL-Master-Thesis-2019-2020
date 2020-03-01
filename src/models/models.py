# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
from src.models.layers import *
import tensorflow as tf
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Models definition                                #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def CNN(start_f, depth, num_classes, input):
    f_e = feature_extractor(start_f, config.img_d, depth, input)
    flatten = tf.keras.layers.Flatten()(f_e)
    cl = classifier(num_classes, flatten)
    return cl

def CNN_res(start_f, depth, num_classes, input):
    f_e = resnet_feature_extractor(start_f, config.img_d, depth, input)
    flatten = tf.keras.layers.Flatten()(f_e)
    cl = classifier(num_classes, flatten)
    return cl
