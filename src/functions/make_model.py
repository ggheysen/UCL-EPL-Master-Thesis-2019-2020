# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Models definition                                #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
"""
make_model function returns a keras functional Model corresponding to the model
returned by the function model_maker (found in src/models/models.py)
"""
def make_model(model_maker):
    # Input layer
    input = tf.keras.layers.Input(shape=(config.img_h, config.img_w, config.img_d))
    # Create the model
    out = model_maker(config.start_f, config.depth, config.num_classes, input)
    # Build the network
    model = tf.keras.models.Model(inputs=input, outputs=out)
    return model
