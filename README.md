# UCL-EPL-Master-Thesis-2019-2020
Guillaume Gheysen's Master Thesis : Deep Learning on FPGA

# Usefull command
first launch a python script to measure metrics about that one. 

python3.7 network.py

Then go to measurement folder (will be created) to observe the different files created.
To see the the learning, open the logs using tensorboard

 tensorboard --logdir=tb_logs

Retrieve weights from a measurement
model.load _ weights(weights _ log)
