# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import numpy as np
from tensorflow_model_optimization.sparsity import keras as sparsity
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def make_pruning(model, train_dataset, validation_dataset, n_step, v_step):
    end_step = np.ceil(1.0 * n_step / config.batch_size).astype(np.int32) * config.p_epochs
    pruning_params = {
          'pruning_schedule': sparsity.PolynomialDecay(initial_sparsity=config.initial_sparsity,
                                                       final_sparsity=config.final_sparsity,
                                                       begin_step=config.p_begin_step,
                                                       end_step=end_step,
                                                       frequency=config.p_frequency)
    }
    p_model = sparsity.prune_low_magnitude(model, **pruning_params)
    model_setup(p_model)
    callbacks = callbacks_init()
    p_model.fit(train_dataset,
              epochs= config.p_epochs,
              verbose=1,
              callbacks=callbacks,
              validation_data=validation_dataset,
              steps_per_epoch= n_step,
              validation_steps= v_step)
    p_model = sparsity.strip_pruning(p_model)
    return p_model

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Additional Functions                             #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def model_setup(model):
    # Loss
    loss = tf.keras.losses.CategoricalCrossentropy()
    optimizer = tf.keras.optimizers.Adam(learning_rate=config.lr)
    # Validation metrics
    metrics = ['accuracy']
    # Compile Model
    model.compile(optimizer=optimizer, loss=loss, metrics=metrics)

def callbacks_init():
    callbacks = []
    callbacks.append(sparsity.UpdatePruningStep())
    callbacks.append(sparsity.PruningSummaries(log_dir=config.tb_dir, profile_batch=0))
    return callbacks
