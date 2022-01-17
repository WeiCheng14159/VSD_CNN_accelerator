read_file -autoread -top top {../src ../include ../src/AXI}
current_design top
link
uniquify

source ../script/DC.sdc

compile

write_file -format verilog -hier -output ../syn/top_syn.v
write_sdf -version 2.1 -context verilog -load_delay net ../syn/top_syn.sdf
report_timing -delay max > setup.log
report_timing -delay min >  hold.log


