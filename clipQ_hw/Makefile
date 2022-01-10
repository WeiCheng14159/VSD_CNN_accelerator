ROOT_DIR           =$(PWD)
BUILD              =build
BUILD_DIR          =$(ROOT_DIR)/$(BUILD)
SRC_DIR            =$(ROOT_DIR)/src
SIM_DIR            =$(ROOT_DIR)/sim
SYN_DIR            =$(ROOT_DIR)/syn
APR_DIR            =$(ROOT_DIR)/pr
INC_DIR            =$(ROOT_DIR)/include
SCRIPT_DIR         =$(ROOT_DIR)/script
REPORT_DIR         =$(ROOT_DIR)/report
SV_DIR             =$(ROOT_DIR)/conf/simvision_conf
NC_DIR             =$(ROOT_DIR)/conf/nWave_conf

TB_TOP             =conv_tb
TOP                =conv

TB_SRC=$(shell ls $(ROOT_DIR)/data/*.hex)

FSDB_DEF :=
ifeq ($(FSDB),1)
FSDB_DEF := +FSDB
else ifeq ($(FSDB),2)
FSDB_DEF := +FSDB_ALL
endif

.PHONY: default init rtl0 nw sv syn0 synthesize syn_init pr_init clean

# Show available all command
default:
	@echo "clean      => Clean previous build"
	@echo "init       => Create necessary directory"
	@echo "rtl0       => Run RTL simulation"
	@echo "nw         => Run nWave"
	@echo "sv         => Run Simvision"
	@echo "synthesize => Run synthesize in interactive mode"
	@echo "syn0       => Run gate-level simulation"
	
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

# Check HDL syntax
superlint:
	jg -superlint $(SCRIPT_DIR)/superlint.tcl &

# Run RTL simulation
rtl0: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer0 \

rtl1: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer1 \

rtl2: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer2 \


rtl3: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer3 \


rtl4: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer4 \

rtl5: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer5 \

rtl6: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer6 \

rtl7: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer7 \

rtl8: $(BUILD)
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(INC_DIR) \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer8 \

# Run synthesize with Design Compiler
synthesize: $(BUILD) syn_init
	cd $(BUILD_DIR); \
	cp $(SCRIPT_DIR)/synopsys_dc.setup $(BUILD_DIR)/.synopsys_dc.setup; \
	dcnxt_shell -f $(SCRIPT_DIR)/synthesize.tcl;

# Run gate-level simulation (nWave)
syn0: $(BUILD) syn_init
	cd $(BUILD_DIR); \
	ncverilog $(SIM_DIR)/$(TB_TOP).sv \
	-sdf_file $(SYN_DIR)/$(TOP)_syn.sdf \
	+incdir+$(SRC_DIR)+$(SIM_DIR)+$(SYN_DIR)+$(INC_DIR) \
	+define+SYN \
	+nc64bit \
	+access+r \
	+define+FSDB_FILE=\"$(TOP).fsdb\"$(FSDB_DEF) \
	+prog_path=../data/layer0 \

# Remove all files
clean:
	rm -rf $(BUILD_DIR) $(SYN_DIR) $(APR_DIR) $(REPORT_DIR) *.log
