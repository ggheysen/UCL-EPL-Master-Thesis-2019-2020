transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/irb_pkg.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/inverted_residual_block.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/Main_Controller.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/DMA.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/Convolution_1_1.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/Convolution_dsc.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_FMI.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_FMINT.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_FMO.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_KEX.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_KDW.sv}
vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/RAM_KPW.sv}

vlog -sv -work work +incdir+D:/GitRepo/Memoire/src/Simulation_code {D:/GitRepo/Memoire/src/Simulation_code/testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  testbench

add wave *
view structure
view signals
run -all
