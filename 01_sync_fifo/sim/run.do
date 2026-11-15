# Local simulation (ModelSim/Questa). From this folder:  vsim -c -do run.do
# Or in the GUI transcript:  do run.do
if {[file exists work]} { vdel -lib work -all }
vlib work
vlog -sv ../rtl/design.sv ../tb/testbench.sv
vsim -voptargs=+acc work.fifo_tb
add wave -r /fifo_tb/*
run -all
