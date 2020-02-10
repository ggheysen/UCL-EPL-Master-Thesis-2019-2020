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
measurements_path = os.path.join(cwd, "..", "measurements", "Unpruned_network")
if not os.path.isdir(measurements_path):
    os.makedirs(measurements_path)
#one folder for each new experiment
exp_dir = os.path.join(measurements_path, model_name + '_' + str(now))
if not os.path.exists(exp_dir):
    os.makedirs(exp_dir)
#To visualize the learning
tb_dir = os.path.join(exp_dir, 'tb_logs')
if not os.path.exists(tb_dir):
    os.makedirs(tb_dir)
log_power_consumption = os.path.join(exp_dir, 'power_consumption.csv')
#Time measurement file
time_log = os.path.join(exp_dir, 'time.csv')
#
metrics_log = os.path.join(exp_dir, 'metrics.csv')

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
  try:
    # Currently, memory growth needs to be the same across GPUs
    tf.config.experimental.set_memory_growth(gpus[gpu_i], True)
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
# 1: Blocks definition
class ConvBlock(tf.keras.Model):
    def __init__(self, num_filters):
        super(ConvBlock, self).__init__()
        self.conv2d = tf.keras.layers.Conv2D(filters=num_filters,
                                             kernel_size=(3, 3),
                                             strides=(1, 1),
                                             padding='same')
        self.activation = tf.keras.layers.ReLU()  # we can specify the activation function directly in Conv2D
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
        self.classifier.add(tf.keras.layers.Dense(units=num_classes, activation='softmax'))

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
lr = 1e-3
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
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Measurement                                     #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
print("Start measurements")

# 1 : Power consumption
command = 'nvidia-smi' + ' '
command += '-i' + ' ' + str(gpu_i) + ' '
command += '--query-gpu=power.draw --format=csv' + ' '
command += '-lms' + ' ' + str(msec_msr) + ' '
command += '-f' + ' ' + log_power_consumption + ' '
args = shlex.split(command)
p = subprocess.Popen(args)
eval_out = model_np.predict(test_dataset, steps=len(x_test)/batch_size)
p.terminate()
print('Power Consumption measured')

# 2 : Accuracy
result = model_np.evaluate(test_dataset)
print('metrics measured')
dictionnary = dict(zip(model_np.metrics_names, result))
metrics_log_file = open(metrics_log, "w")
for key in dictionnary:
    str_metric = key + ', ' + str(dictionnary[key]) + '\n'
    metrics_log_file.write(str_metric)
metrics_log_file.close()
print('metrics file written')

# 3 : Latency and Throughput
latency = timeit(lambda: model_np.predict(test_dataset, steps=1),
                        number=100)
print('Latency measured')
throughput = timeit(lambda: model_np.predict(test_dataset, steps=len(x_test)/batch_size),
                          number=100)
print('Throughput measured')
time_log_file = open(time_log, "w")
str_latency = 'latency' + ', ' + str(latency) + '\n'
str_throughput = 'throughput' + ', ' + str(throughput) + '\n'
time_log_file.write(str_latency)
time_log_file.write(str_throughput)
time_log_file.close()
print('Time file writen')

# 4 : Training (in logs)
