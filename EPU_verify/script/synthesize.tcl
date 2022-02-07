set top top

# Don't change anything below this line
set_host_options -max_cores 16

# Read all Files
read_file -autoread -top ${top} -recursive {../src ../include} -library ${top}
current_design [get_designs ${top}]
link
uniquify

# Setting Clock Constraits
source -echo -verbose ../script/${top}.sdc

compile -map_effort high
compile -map_effort high -inc

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]
 
# set bus_inference_style {%s[%d]}
# set bus_naming_style {%s[%d]}
# set hdlout_internal_busses true
# change_names -hierarchy -rule verilog
# define_name_rules name_rule -allowed {a-z A-Z 0-9 _}   -max_length 255 -type cell
# define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
# define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
# define_name_rules name_rule -case_insensitive
# change_names -hierarchy -rules name_rule

# Write
write -format ddc -hierarchy -output "${top}_syn.ddc"
write_file -format verilog -hier -output ../syn/${top}_syn.v
write_sdf -version 2.0 -context verilog  ../syn/${top}_syn.sdf
write_sdc -version 2.0 ${top}.sdc
report_area -h > area.log
report_timing > timing.log
report_qor > ${top}_syn.qor

exit