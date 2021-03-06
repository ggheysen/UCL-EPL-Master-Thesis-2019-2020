# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
from math import floor, ceil
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
"""
Function make_measure to make various measurement of the model and save them in
exp_dir
"""
def make_dataset():
    # 1: We extract the CIFAR10 dataset
    (x_tr, y_tr), (x_te, y_te) = get_data()
    # 2: Normalization & 1-hot encoding
    (x_tr, y_tr), (x_te, y_te) = normalize_data(x_tr, y_tr, x_te, y_te)
    # 3: Validation set creation
    (x_tr, y_tr), (x_v, y_v) = make_validation(x_tr, y_tr)
    # 4: We create a dataset
    d_tr, d_v, d_te = make_dts(x_tr, y_tr, x_v, y_v, x_te, y_te)
    # 5: We apply data augmentaion
    data_augmentation(d_tr)
    data_augmentation(d_v)
    # 6: We compute the number of step per epoch
    step_tr = floor(len(x_tr)/config.batch_size)
    step_v = floor(len(x_v)/config.batch_size)
    step_te = floor(len(x_te)/config.batch_size)
    return d_tr, d_v, d_te, step_tr, step_v, step_te


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Additional functions                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def get_data():
    return tf.keras.datasets.cifar10.load_data()

def normalize_data(x_tr, y_tr, x_te, y_te):
    x_tr_n = x_tr / 255
    x_te_n = x_te  / 255
    y_tr_n = tf.keras.utils.to_categorical(y_tr, config.num_classes)
    y_te_n = tf.keras.utils.to_categorical(y_te, config.num_classes)
    return (x_tr_n, y_tr_n), (x_te_n, y_te_n)

def make_validation(x, y):
    x_v = x[:floor(0.2*len(x))]
    x_t = x[ceil(0.2*len(x)):]
    y_v = y[:floor(0.2*len(y))]
    y_t = y[ceil(0.2*len(y)):]
    return (x_t, y_t), (x_v, y_v)

def make_dts(x_tr, y_tr, x_v, y_v, x_te, y_te):
    d_tr = tf.data.Dataset.from_tensor_slices((x_tr, y_tr))\
                        .shuffle(buffer_size=floor(len(x_tr)/config.batch_size), seed=config.SEED, reshuffle_each_iteration=True)\
                        .repeat()\
                        .batch(config.batch_size)

    d_v = tf.data.Dataset.from_tensor_slices((x_v, y_v))\
                        .shuffle(buffer_size=floor(len(x_v)/config.batch_size), seed=config.SEED, reshuffle_each_iteration=True)\
                        .repeat()\
                        .batch(config.batch_size)
    d_te = tf.data.Dataset.from_tensor_slices((x_te, y_te)) \
                        .batch(config.batch_size)
    return d_tr, d_v, d_te

def data_augmentation(dt):
    dt.map(flip_image) \
      .map(color_image)

def flip_image(image, label):
    image =  tf.image.random_flip_left_right(image, seed=config.SEED)
    image =  tf.image.random_flip_up_down(image, seed=config.SEED)
    return image, label

def color_image(image, label):
    image = tf.image.random_hue(image, 0.08, seed=config.SEED)
    image = tf.image.random_saturation(image, 0.6, 1.6, seed=config.SEED)
    image = tf.image.random_brightness(image, 0.05, seed=config.SEED)
    image = tf.image.random_contrast(image, 0.7, 1.3, seed=config.SEED)
    return image, label
