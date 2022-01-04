ROOT_DIR           =$(PWD)
BUILD              =build
BUILD_DIR          =$(ROOT_DIR)/$(BUILD)
SRC_DIR            =$(ROOT_DIR)/src
SIM_DIR            =$(ROOT_DIR)/sim
SYN_DIR            =$(ROOT_DIR)/syn
APR_DIR            =$(ROOT_DIR)/pr
SCRIPT_DIR         =$(ROOT_DIR)/script
REPORT_DIR         =$(ROOT_DIR)/report
SV_DIR             =$(ROOT_DIR)/conf/simvision_conf
NC_DIR             =$(ROOT_DIR)/conf/nWave_conf

TB_TOP             =conv_tb
TOP                =conv

SRC=$(shell ls $(SRC_DIR)/*.v)

TB_SRC=$(shell ls $(ROOT_DIR)/data/*.hex)

.PHONY: default init check rtl nw sv syn syn_chip syn_init icc_init autosyn pre pre_chip pre_sv clean

# Show available all command
default:
	@echo "clean   => Clean previous build"
	@echo "init    => Create necessary directory"
	@echo "rtl     => Run RTL simulation"
	@echo "nw      => Run nWave"
	@echo "sv      => Run Simvision"
	@echo "syn     => Run synthesize in interactive mode"
	@echo "autosyn => Run synthesize in background"
	@echo "pre    => Run gate-level simulation"
	@echo "pre_sv => Run Simvision with pre sim"

$(BUILD):
	mkdir -p $(BUILD)

# Create folders
init: clean
	mkdir -p $(BUILD_DIR) $(SYN_DIR) $(REPORT_DIR)

# Syn directory init
syn_init:
	mkdir -p $(SYN_DIR);

# APR directory init
pr_init:
	mkdir -p $(APR_DIR);

cp_tb_src:
	cd $(BUILD_DIR); \
	cp $(TB_SRC) .;

# Check HDL syntax
superlint:
	jg -superlint $(SCRIPT_DIR)/superlint.tcl &

# Run RTL simulation
rtl0: $(BUILD) cp_tb_src
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv $(SRC) \
	+incdir+$(SRC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB \
	+define+FSDB_FILE=\"$(TOP).fsdb\" \

# Run synthesize with Design Compiler
syn: $(BUILD) syn_init
	cd $(BUILD_DIR); \
	cp $(SCRIPT_DIR)/synopsys_dc.setup $(BUILD_DIR)/.synopsys_dc.setup; \
	dcnxt_shell -f $(SCRIPT_DIR)/synthesize.tcl;

# Auto run synthesize with Design Compiler
autosyn: $(BUILD) syn_init
	cd $(BUILD_DIR); \
	cp $(SCRIPT_DIR)/synopsys_dc.setup $(BUILD_DIR)/.synopsys_dc.setup; \
	nohup dcnxt_shell -f $(SCRIPT_DIR)/synthesize.tcl &> $(ROOT_DIR)/nohup.log &

# Run gate-level simulation (nWave)
syn0: $(BUILD) cp_tb_src syn_init
	cd $(BUILD_DIR); \
	cp $(SYN_DIR)/$(TOP)_syn.sdf $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv $(SYN_DIR)/$(TOP)_syn.v \
	+nc64bit \
	+access+r \
	+define+FSDB \
	+define+FSDB_FILE=\"$(TOP).fsdb\" \

# Remove all files
clean:
	rm -rf $(BUILD_DIR) $(SYN_DIR) $(APR_DIR) $(REPORT_DIR) *.log
