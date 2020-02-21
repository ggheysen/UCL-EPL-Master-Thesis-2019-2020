# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import os
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                               Global Varriables                              #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
n_epoch = 100
lr = 1e-3
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def make_train(model, exp_dir, train_dataset,
               validation_dataset, n_step, v_step):
    # Training
    model_setup(model)
    callbacks = callbacks_init(exp_dir)
    model.fit(train_dataset,
                 epochs=n_epoch,
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
    optimizer = tf.keras.optimizers.Adam(learning_rate=lr)
    # Validation metrics
    metrics = ['accuracy']
    # Compile Model
    model.compile(optimizer=optimizer, loss=loss, metrics=metrics)

def callbacks_init(exp_dir):
    # Path
    tb_dir = os.path.join(exp_dir, 'tb_logs')
    if not os.path.exists(tb_dir):
        os.makedirs(tb_dir)
    # callbacks creation
    callbacks = []
    tb_callback = tf.keras.callbacks.TensorBoard(log_dir=tb_dir,
                                                 profile_batch=0,
                                                 histogram_freq=1)  # if 1 shows weights histograms
    callbacks.append(tb_callback)
    es_callback = tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=10, mode = 'max')
    callbacks.append(es_callback)
    lr_plateau = tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=3, mode='max') #To avoid plateau
    callbacks.append(lr_plateau)
    return callbacks
