# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                                  Import                                      #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
import tensorflow as tf
import os
import shlex
import subprocess
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Main functions                                  #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
"""
Function make_measure to make various measurement of the model and save them in
exp_dir
"""
def make_measure(model, model_name, cwd, test_dataset, n_step):
    # Path
    measurements_path = os.path.join(cwd, "..", "measurements", model_name)
    if not os.path.isdir(measurements_path):
        os.makedirs(measurements_path)
    #one folder for each new experiment
    exp_dir = os.path.join(measurements_path, model_name + '_' + str(now))
    if not os.path.exists(exp_dir):
        os.makedirs(exp_dir)
    # Start measure
    print("Start measurements")
    # 1 : save model summary and weights
    save_model(model, exp_dir)
    # 2 : Save model perf
    save_metric(model, exp_dir, test_dataset)
    # 3 : Power consumption
    save_power(model, exp_dir, test_datasetp, n_step)
    # 4 : Latency and Throughput
    save_time(model, exp_dir, test_dataset, n_step)
    print("Measurement finished")


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
#                              Additional functions                            #
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% #
def save_model(model, exp_dir):
    # Path
    model_summary_log = os.path.join(exp_dir, 'model_summary.txt')
    weights_log = os.path.join(exp_dir, 'weights.h5')
    # Save model summary
    model_summary_log_file = open(model_summary_log,'w')
    model.summary(print_fn=lambda x: model_summary_log_file.write(x + '\n'))
    model.feature_extractor.summary(print_fn=lambda x: model_summary_log_file.write(x + '\n'))
    model.classifier.summary(print_fn=lambda x: model_summary_log_file.write(x + '\n'))
    model_summary_log_file.close()
    # Save model weights
    model.save_weights(weights_log)

def save_metric(model, exp_dir, test_dataset):
    # Path
    metrics_log = os.path.join(exp_dir, 'metrics.csv')
    # Evaluate the model
    result = model.evaluate(test_dataset)
    dictionnary = dict(zip(model.metrics_names, result))
    metrics_log_file = open(metrics_log, "w")
    for key in dictionnary:
        str_metric = key + ', ' + str(dictionnary[key]) + '\n'
        metrics_log_file.write(str_metric)
    metrics_log_file.close()

def save_power(model, exp_dir, test_datasetp, n_step):
    # Path
    log_power_consumption = os.path.join(exp_dir, 'power_consumption.csv')
    # Create cuda command
    command = 'nvidia-smi' + ' '
    command += '-i' + ' ' + str(gpu_i) + ' '
    command += '--query-gpu=power.draw --format=csv' + ' '
    command += '-lms' + ' ' + str(msec_msr) + ' '
    command += '-f' + ' ' + log_power_consumption + ' '
    # Start measure the power consumption
    args = shlex.split(command)
    p = subprocess.Popen(args)
    eval_out = model_np.predict(test_dataset, steps=len(x_test)/batch_size)
    p.terminate()

def save_time(model, exp_dir, test_dataset, n_step):
    # Path
    time_log = os.path.join(exp_dir, 'time.csv')
    # Measure Latency & throughput
    latency = timeit(lambda: model_np.predict(test_dataset, steps=1),
                            number=100)
    throughput = timeit(lambda: model_np.predict(test_dataset, steps=n_step,
                              number=100)
    throughput /= n_step
    # Save them into a file
    time_log_file = open(time_log, "w")
    str_latency = 'latency' + ', ' + str(latency) + '\n'
    str_throughput = 'throughput' + ', ' + str(throughput) + '\n'
    time_log_file.write(str_latency)
    time_log_file.write(str_throughput)
    time_log_file.close()
    print('Time file writen')
