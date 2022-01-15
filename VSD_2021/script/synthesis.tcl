set_host_options -max_cores 16

read_file -autoread -top top {../src ../include ../src/AXI}
current_design top
link
uniquify

source ../script/DC.sdc

# compile
compile -map_effort high
compile -map_effort high -inc
# optimize_registers

remove_unconnected_ports -blast_buses [get_cells * -hier]

set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _}   -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule

write -format ddc -hierarchy -output ../syn/top_syn.ddc
write_file -format verilog -hier -output ../syn/top_syn.v
write_sdf -version 2.1 -context verilog -load_delay net ../syn/top_syn.sdf
write_sdc -version 2.1 top.sdc
report_timing > ../syn/timing.log
report_area -h > ../syn/area.log

