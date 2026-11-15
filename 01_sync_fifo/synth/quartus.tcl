# Run from this folder:  quartus_sh -t quartus.tcl
# Then open the project in the Quartus GUI: Tools > Netlist Viewers > RTL Viewer / Technology Map Viewer,
# and Tools > Timing Analyzer for the critical path.
# Edit DEVICE to match the board/family you have installed (needs that device family's support files).
set PROJ   fifo
set TOP    fifo
set DEVICE 5CSEMA5F31C6   ;# Cyclone V (DE1-SoC); change if your install differs

package require ::quartus::project
package require ::quartus::flow

project_new $PROJ -overwrite
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE $DEVICE
set_global_assignment -name TOP_LEVEL_ENTITY $TOP
set_global_assignment -name SYSTEMVERILOG_FILE ../rtl/design.sv
set_global_assignment -name SDC_FILE fifo.sdc

execute_flow -compile
project_close
