remove_design -all
set_host_options -max_cores 16

set topp "conv"

analyze -format sverilog  "../src/conv.sv"

elaborate conv

current_design ${topp}

link

source -echo -verbose "../script/DC.sdc"

set high_fanout_net_threshold 0

uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

set_structure -timing true

compile

optimize_registers

compile -map_effort high
compile -map_effort high -inc

write_sdf "../dc/${topp}_syn.sdf"
write_file -format verilog -hierarchy -output "../dc/${topp}_syn.v"
report_area   > area.log
report_timing > timing.log
report_qor    > ${topp}_syn.qor