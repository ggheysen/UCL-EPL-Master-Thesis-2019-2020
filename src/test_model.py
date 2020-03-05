# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import os
from datetime import datetime
from src.functions.make_train import make_train
from src.functions.make_measure import make_measure
from src.functions.make_dataset import make_dataset
from src.functions.make_model import make_model
from src.functions.make_pruning import make_pruning
import src.config as config
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def test_model(model_n, model_maker, pruning):
    # Setup
    setup_path(model_n, pruning)
    tf.random.set_seed(config.SEED)
    # GPU config memory growth
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
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    #                              Dataset Creation                            #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    train_dataset, validation_dataset, test_dataset, \
            train_step, validation_step, test_step = make_dataset()

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    #                          Model Creation                                  #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    model = make_model(model_maker)

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    #                          Model Training                                  #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
    make_train(model, train_dataset, validation_dataset,
                train_step, validation_step, False)

    if(pruning):
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        #                              Pruning                                 #
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        model = make_pruning(model, train_dataset, validation_dataset, train_step, validation_step)
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        #                           Model Training                             #
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        make_train(model, train_dataset, validation_dataset,
                    train_step, validation_step, pruning)

        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        #                             Measurement                              #
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        #make_measure(model, test_dataset, test_step)
    else:
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        #                             Measurement                              #
        # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
        print('yo')
        #make_measure(model, test_dataset, test_step)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Additional functions                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def setup_path(model_n, pruning):
    config.model_name = model_n
    config.now = datetime.now().strftime('%b%d_%H-%M-%S')
    config.cwd = os.getcwd()
    config.measurements_path = os.path.join(config.cwd, "measurements", config.model_name)
    if not os.path.isdir(config.measurements_path):
        os.makedirs(config.measurements_path)
    config.exp_dir = os.path.join(config.measurements_path, config.model_name + '_' + str(config.now))
    if not os.path.exists(config.exp_dir):
        os.makedirs(config.exp_dir)
    config.tb_dir = os.path.join(config.exp_dir, 'tb_logs')
    if not os.path.exists(config.tb_dir):
        os.makedirs(config.tb_dir)
    if (pruning):
        config.tb_prune_dir = os.path.join(config.exp_dir, 'tb_prune_logs')
        if not os.path.exists(config.tb_prune_dir):
            os.makedirs(config.tb_prune_dir)
        config.tb_dir2 = os.path.join(config.exp_dir, 'tb_logs2')
        if not os.path.exists(config.tb_dir2):
            os.makedirs(config.tb_dir2)
