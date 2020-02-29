# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import os
import shlex
import subprocess
from timeit import timeit
import src.config as config
import zipfile
import tempfile
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
"""
Function make_measure to make various measurement of the model and save them in
exp_dir
"""
def make_measure(model, test_dataset, n_step):
    # Start measure
    print("Start measurements")
    # 1 : save model summary and weights
    save_model(model)
    print("Model saved")
    # 2 : Save model perf
    save_metric(model, test_dataset)
    print("Metric saved")
    # 3 : Power consumption
    save_power(model, test_dataset, n_step)
    # 4 : Latency and Throughput
    save_time(model,test_dataset, n_step)
    print("Time saved")
    print("Measurement finished")


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Additional functions                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def save_model(model):
    # Path
    model_summary_log = os.path.join(config.exp_dir, 'model_summary.txt')
    _, weights_log_file = tempfile.mkstemp('.h5')
    weights_zip_log = os.path.join(config.exp_dir, 'weights.zip')
    weights_size_log = os.path.join(config.exp_dir, 'size.txt')
    model_summary_log_file = open(model_summary_log,'w')
    # Save model summary
    model.summary(print_fn=lambda x: model_summary_log_file.write(x + '\n'))
    model_summary_log_file.close()
    # Save model as zip
    tf.keras.models.save_model(model, weights_log_file, include_optimizer=False)
    with zipfile.ZipFile(weights_zip_log, 'w', compression=zipfile.ZIP_DEFLATED) as f:
      f.write(weights_log_file)
    with open(weights_size_log, 'w') as f:
        f.write("Size of the pruned model before compression: %.2f Mb"
              % (os.path.getsize(weights_log_file) / float(2**20)))
        f.write("Size of the pruned model after compression: %.2f Mb"
              % (os.path.getsize(weights_zip_log) / float(2**20)))

def save_metric(model, test_dataset):
    # Path
    metrics_log = os.path.join(config.exp_dir, 'metrics.csv')
    # Evaluate the model
    result = model.evaluate(test_dataset)
    dictionnary = dict(zip(model.metrics_names, result))
    metrics_log_file = open(metrics_log, "w")
    for key in dictionnary:
        str_metric = key + ', ' + str(dictionnary[key]) + '\n'
        metrics_log_file.write(str_metric)
    metrics_log_file.close()

def save_power(model, test_dataset, n_step):
    # Path
    log_power_consumption = os.path.join(config.exp_dir, 'power_consumption.csv')
    # Create cuda command
    command = 'nvidia-smi' + ' '
    command += '-i' + ' ' + str(config.gpu_i) + ' '
    command += '--query-gpu=power.draw --format=csv' + ' '
    command += '-lms' + ' ' + str(config.msec_msr) + ' '
    command += '-f' + ' ' + log_power_consumption + ' '
    # Start measure the power consumption
    args = shlex.split(command)
    p = subprocess.Popen(args)
    eval_out = model.predict(test_dataset, steps=n_step)
    p.terminate()

def save_time(model, test_dataset, n_step):
    # Path
    time_log = os.path.join(config.exp_dir, 'time.csv')
    # Measure Latency & throughput
    latency = timeit(lambda: model.predict(test_dataset, steps=1),
                            number=config.n_iteration_latency)
    throughput = timeit(lambda: model.predict(test_dataset, steps=n_step),
                              number=config.n_iteration_troughput)
    throughput = throughput / n_step
    # Save them into a file
    time_log_file = open(time_log, "w")
    str_latency = 'latency' + ', ' + str(latency) + '\n'
    str_throughput = 'throughput' + ', ' + str(throughput) + '\n'
    time_log_file.write(str_latency)
    time_log_file.write(str_throughput)
    time_log_file.close()
    print('Time file writen')
