# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import numpy as np
from tensorflow_model_optimization.sparsity import keras as sparsity
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                               Global Varriables                              #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
batch_size = 64
epochs = 4
initial_sparsity=0.50
final_sparsity=0.90
begin_step=0
frequency=100
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def make_pruning(model, step_train):
    end_step = np.ceil(1.0 * step_train / batch_size).astype(np.int32) * epochs
    pruning_params = {
          'pruning_schedule': sparsity.PolynomialDecay(initial_sparsity=initial_sparsity,
                                                       final_sparsity=final_sparsity,
                                                       begin_step=begin_step,
                                                       end_step=end_step,
                                                       frequency=frequency)
    }
    #p_model = tf.keras.Sequential()
    #for layer in model.layers:
    #    if (isinstance(layer, sparsity.PrunableLayer)):
    #        p_model.add(sparsity.prune_low_magnitude(
    #        layer,
    #        **pruning_params
    #        ))
    #    else:
    #        p_model.add(layer)
    #model = sparsity.prune_low_magnitude(model, **pruning_params)
    #return p_model
    model.pruning(**pruning_params)
