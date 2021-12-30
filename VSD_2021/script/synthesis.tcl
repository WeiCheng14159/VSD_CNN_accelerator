read_file -autoread -top top {../src ../include ../src/AXI}
current_design top
link
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

source ../script/DC.sdc

compile
compile -map_effort high
compile -map_effort high -inc


remove_unconnected_ports -blast_buses [get_cells * -hier]
write_file -format verilog -hier -output ../syn/top_syn.v
write_sdf -version 2.1 -context verilog -load_delay net ../syn/top_syn.sdf
report_timing > ../syn/timing.log
report_area > ../syn/area.log

exit
