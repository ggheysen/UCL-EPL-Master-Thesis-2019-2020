# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

import tensorflow as tf
import numpy as np
import os
from datetime import datetime
from math import floor, ceil
import shlex
import subprocess
from timeit import timeit
from tensorflow.keras.models import model_from_json

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Setup                                       #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

#    # 1: Constants
now = datetime.now().strftime('%b%d_%H-%M-%S')
model_name = 'CNN'
gpu_i = int(os.environ['CUDA_VISIBLE_DEVICES'])
SEED = 1234
tf.random.set_seed(SEED)
n_epoch = 100
msec_msr = 1

#    # 2: Paths
cwd = os.getcwd()
#Where we store the experiments
#To visualize the learning
tb_dir = os.path.join(exp_dir, 'tb_logs')
if not os.path.exists(tb_dir):
    os.makedirs(tb_dir)
#    # 3: Model parameters
depth = 4
start_f = 8
batch_size = 32
num_classes = 10
img_h = 32
img_w = 32

#    # 4: config
gpus = tf.config.experimental.list_physical_devices('GPU')
if gpus:
  for gpu in gpus:
    try:
        # Currently, memory growth needs to be the same across GPUs
        tf.config.experimental.set_memory_growth(gpu, True)
        logical_gpus = tf.config.experimental.list_logical_devices('GPU')
        print(len(gpus), "Physical GPUs,", len(logical_gpus), "Logical GPUs")
    except RuntimeError as e:
        # Memory growth must be set before GPUs have been initialized
        print(e)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Dataset Creation                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

# 1: We extract the CIFAR10 dataset
(x_train, y_train), (x_test, y_test) = tf.keras.datasets.cifar10.load_data()

# 2: Normalization & 1-hot encoding
x_train_n = x_train / 255
x_test_n = x_test  / 255
y_train_n = tf.keras.utils.to_categorical(y_train, num_classes)
y_test_n = tf.keras.utils.to_categorical(y_test, num_classes)

# 3: Validation set creation
x_validation_n = x_train_n[:floor(0.2*len(x_train_n))]
x_train_n = x_train_n[ceil(0.2*len(x_train_n)):]
y_validation_n = y_train_n[:floor(0.2*len(y_train_n))]
y_train_n = y_train_n[ceil(0.2*len(y_train_n)):]

# 4: We create a dataset
#train
train_dataset = tf.data.Dataset.from_tensor_slices((x_train_n, y_train_n)).batch(batch_size)
train_dataset = train_dataset.repeat()
#validation
validation_dataset = tf.data.Dataset.from_tensor_slices((x_validation_n, y_validation_n)).batch(batch_size)
validation_dataset = validation_dataset.repeat()
#test
test_dataset = tf.data.Dataset.from_tensor_slices((x_test_n, y_test_n)).batch(batch_size)
test_dataset = test_dataset

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Model Creation                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
param = 1e-3
# 1: Blocks definition
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
        self.activation = tf.keras.layers.LeakyReLU(alpha=0.3)
        self.pooling = tf.keras.layers.MaxPool2D(pool_size=(2, 2))

    def call(self, inputs):
        x = self.conv2d(inputs)
        x = self.activation(x)
        x = self.pooling(x)
        return x

# 2: Networks definition
class CNN_NonPruned(tf.keras.Model):
    def __init__(self, depth, start_f, num_classes):
        super(CNN_NonPruned, self).__init__()

        self.feature_extractor = tf.keras.Sequential()

        for i in range(depth):
            self.feature_extractor.add(ConvBlock(num_filters=start_f))
            start_f *= 2

        self.flatten = tf.keras.layers.Flatten()
        self.classifier = tf.keras.Sequential()
        self.classifier.add(tf.keras.layers.Dense(units=512, activation='relu'))
        self.classifier.add(tf.keras.layers.Dropout(0.3, seed=SEED))
        self.classifier.add(tf.keras.layers.Dense(units=num_classes, activation='softmax'))
        self.classifier.add(tf.keras.layers.Dropout(0.2, seed=SEED))

    def call(self, inputs):
        x = self.feature_extractor(inputs)
        x = self.flatten(x)
        x = self.classifier(x)
        return x


# 3: Model instance creation
model_np = CNN_NonPruned(depth=depth,
                      start_f=start_f,
                      num_classes=num_classes)
model_np.build(input_shape=(None, img_h, img_w, 3)) # Build Model (Required)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Model Training                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #

# 1: Setup
# Loss
loss = tf.keras.losses.CategoricalCrossentropy()
# learning rate
lr = 5e-4
optimizer = tf.keras.optimizers.Adam(learning_rate=lr)
# Validation metrics
metrics = ['accuracy']
# Compile Model
model_np.compile(optimizer=optimizer, loss=loss, metrics=metrics)
# 2: Training (with callbacks)
callbacks = []
tb_callback = tf.keras.callbacks.TensorBoard(log_dir=tb_dir,
                                             profile_batch=0,
                                             histogram_freq=1)  # if 1 shows weights histograms
callbacks.append(tb_callback)
es_callback = tf.keras.callbacks.EarlyStopping(monitor='my_IoU', patience=10, mode = 'max')
callbacks.append(es_callback)
lr_plateau = tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=4, mode='min') #To avoid plateau
callbacks.append(lr_plateau)

model_np.fit(train_dataset,
             epochs=n_epoch,
             callbacks=callbacks,
             validation_data=validation_dataset,
             steps_per_epoch=floor(len(x_train_n)/batch_size),
             validation_steps=floor(len(x_validation_n)/batch_size)
            )

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Measurement                                     #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
make_measure(model_np, exp_dir, test_dataset, len(x_test)/batch_size)
