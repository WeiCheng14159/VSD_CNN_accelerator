ELF_NAME := main

export CROSS_PREFIX ?= riscv64-unknown-elf-
export RISCV_GCC ?= $(CROSS_PREFIX)gcc
export RISCV_OBJDUMP ?= $(CROSS_PREFIX)objdump -xsd
export RISCV_OBJCOPY ?= $(CROSS_PREFIX)objcopy -O verilog

LDFILE := link.ld
CFLAGS := -march=rv32i -mabi=ilp32
LDFLAGS := -static -nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -T$(LDFILE) -lgcc


SRC_C := $(wildcard *.c)
OBJ_C := $(patsubst %.c,%.o,$(SRC_C))
SRC_S := $(wildcard *.S)
OBJ_S := $(patsubst %.S,%.o,$(SRC_S))
SRC := $(SRC_C) $(SRC_S)
OBJ := $(OBJ_C) $(OBJ_S)

.SUFFIXES: .o .S .c

.PHONY: all

all: build_elf build_log build_hex append_hex

build_elf: $(OBJ) | $(LDFILE)
	$(RISCV_GCC) $^ $(LDFLAGS) -o $(ELF_NAME)

build_log: $(ELF_NAME)
	$(RISCV_OBJDUMP) $< > $(ELF_NAME).log

build_hex: $(ELF_NAME)
	$(RISCV_OBJCOPY) $< -i 4 -b 0 -j .text0 --change-addresses 0 rom0.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 1 -j .text0 --change-addresses 0 rom1.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 2 -j .text0 --change-addresses 0 rom2.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 3 -j .text0 --change-addresses 0 rom3.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 0 -R .text0 --change-addresses -0x20000000 dram0.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 1 -R .text0 --change-addresses -0x20000000 dram1.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 2 -R .text0 --change-addresses -0x20000000 dram2.hex
	$(RISCV_OBJCOPY) $< -i 4 -b 3 -R .text0 --change-addresses -0x20000000 dram3.hex

append_hex: $(ELF_NAME)
	/usr/bin/python3 conv4dram.py 
	# In8
	echo "@50000000" >> dram0.hex
	cat In8_0.hex >> dram0.hex 
	echo "@50000000" >> dram1.hex
	cat In8_1.hex >> dram1.hex 
	echo "@50000000" >> dram2.hex
	cat In8_2.hex >> dram2.hex 
	echo "@50000000" >> dram3.hex
	cat In8_3.hex >> dram3.hex
	# W2
	echo "@70000000" >> dram0.hex
	cat W2_0.hex >> dram0.hex 
	echo "@70000000\n" >> dram1.hex
	cat W2_1.hex >> dram1.hex 
	echo "@70000000\n" >> dram2.hex
	cat W2_2.hex >> dram2.hex 
	echo "@70000000\n" >> dram3.hex
	cat W2_3.hex >> dram3.hex
	# Bias
	echo "@71000000" >> dram0.hex
	cat Bias32_0.hex >> dram0.hex 
	echo "@71000000\n" >> dram1.hex
	cat Bias32_1.hex >> dram1.hex 
	echo "@71000000\n" >> dram2.hex
	cat Bias32_2.hex >> dram2.hex 
	echo "@71000000\n" >> dram3.hex
	cat Bias32_3.hex >> dram3.hex
	# Param
	echo "@72000000" >> dram0.hex
	cat param_0.hex >> dram0.hex 
	echo "@72000000" >> dram1.hex
	cat param_1.hex >> dram1.hex 
	echo "@72000000" >> dram2.hex
	cat param_2.hex >> dram2.hex 
	echo "@72000000" >> dram3.hex
	cat param_3.hex >> dram3.hex

%.o: %.S
	$(RISCV_GCC) -c $(CFLAGS) $^

%.o: %.c
	$(RISCV_GCC) -c $(CFLAGS) $^

.PHONY: clean

clean: clean_gen_hex
	rm -rf $(ELF_NAME) $(ELF_NAME).log rom*.hex dram*.hex *.o *.txt

clean_gen_hex:
	rm -rf In8_*.hex Bias32_*.hex param_*.hex W2_*.hex
