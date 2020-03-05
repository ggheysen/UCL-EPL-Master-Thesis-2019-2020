# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import os
from tensorflow_model_optimization.sparsity import keras as sparsity
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def make_train(model, train_dataset,
               validation_dataset, n_step, v_step, pruning):
    # Training
    model_setup(model)
    callbacks = callbacks_init(pruning)
    model.fit(train_dataset,
                 epochs=config.t_epoch,
                 callbacks=callbacks,
                 validation_data=validation_dataset,
                 steps_per_epoch= n_step,
                 validation_steps= v_step
                )
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Additional functions                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def model_setup(model):
    # Loss
    loss = tf.keras.losses.CategoricalCrossentropy()
    optimizer = tf.keras.optimizers.Adam(learning_rate=config.lr)
    # Validation metrics
    metrics = ['accuracy']
    # Compile Model
    model.compile(optimizer=optimizer, loss=loss, metrics=metrics)

def callbacks_init(pruning):
    callbacks = []
    if (pruning):
        logdir = config.tb_dir2
    else:
        logdir = config.tb_dir
    tb_callback = tf.keras.callbacks.TensorBoard(log_dir=logdir,
                                             profile_batch=0,
                                             histogram_freq=1)  # if 1 shows weights histograms
    callbacks.append(tb_callback)
    es_callback = tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=15, mode = 'max')
    callbacks.append(es_callback)
    lr_plateau = tf.keras.callbacks.ReduceLROnPlateau(monitor='val_accuracy', factor=0.1, patience=2, mode='max', verbose=1) #To avoid plateau
    callbacks.append(lr_plateau)
    return callbacks
