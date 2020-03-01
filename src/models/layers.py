# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                             Layer definition                                 #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def classifier(num_classes, input):
    ret = input
    ret = tf.keras.layers.Dense(units=2048, activation='relu')(ret)
    ret = tf.keras.layers.Dropout(0.3, seed=config.SEED)(ret)
    ret = tf.keras.layers.Dense(units=512, activation='relu')(ret)
    ret = tf.keras.layers.Dropout(0.3, seed=config.SEED)(ret)
    ret = tf.keras.layers.Dense(units=128, activation='relu')(ret)
    ret = tf.keras.layers.Dropout(0.25, seed=config.SEED)(ret)
    ret = tf.keras.layers.Dense(units=32, activation='relu')(ret)
    ret = tf.keras.layers.Dropout(0.25, seed=config.SEED)(ret)
    ret = tf.keras.layers.Dense(units=config.num_classes, activation='softmax')(ret)
    return ret

def feature_extractor(start_f, init_f, depth, input):
    s_f = start_f
    i_f = init_f
    ret = input
    for i in range(depth):
        ret = tf.keras.layers.Conv2D(filters=s_f,
                                             kernel_size=(3, 3),
                                             strides=(1, 1),
                                             padding='same',
                                             kernel_regularizer=tf.keras.regularizers.l2(config.l2_param), #To limit overfitting
                                             bias_regularizer=tf.keras.regularizers.l2(config.l2_param)
                                             )(ret)
        ret = tf.keras.layers.BatchNormalization()(ret)
        ret = tf.keras.layers.LeakyReLU(alpha=0.2)(ret)
        ret = tf.keras.layers.MaxPool2D(pool_size=(2, 2))(ret)
        s_f = (s_f + i_f ) * 2
        i_f = s_f
    return ret

def resnet_feature_extractor(start_f, init_f, depth, input):
    s_f = start_f
    i_f = init_f
    ret = input
    for i in range(depth):
        conv = tf.keras.layers.Conv2D(filters=s_f,
                                             kernel_size=(3, 3),
                                             strides=(1, 1),
                                             padding='same',
                                             kernel_regularizer=tf.keras.regularizers.l2(config.l2_param), #To limit overfitting
                                             bias_regularizer=tf.keras.regularizers.l2(config.l2_param)
                                             )(ret)
        conv = tf.keras.layers.BatchNormalization()(conv)
        conv = tf.keras.layers.LeakyReLU(alpha=0.2)(conv)
        ret = tf.keras.layers.Concatenate()([conv, ret])
        ret = tf.keras.layers.MaxPool2D(pool_size=(2, 2))(ret)
        s_f = (s_f + i_f ) * 2
        i_f = s_f
    return ret
