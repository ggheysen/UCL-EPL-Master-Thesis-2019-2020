# UCL-EPL-Master-Thesis-2019-2020
Guillaume Gheysen's Master Thesis : Deep Learning on FPGA

# Useful command
Launch the tests on various network

python3.7 main.py

Then go to measurement folder (will be created) to observe the different files created.
To see the the learning, open the logs using tensorboard

 tensorboard --logdir=tb_logs

Retrieve weights from a measurement
model.load _ weights(weights _ log)
