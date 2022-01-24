OUTPUT_ARCH( "riscv" )

_STACK_SIZE = DEFINED(_STACK_SIZE) ? _STACK_SIZE : 0x1000;
_TEST_SIZE = DEFINED(_TEST_SIZE) ? _TEST_SIZE : 0x10;

/*****************************************************************************
 * Define memory layout
 ****************************************************************************/
MEMORY {
  rom    : ORIGIN = 0x00000000, LENGTH = 0x00004000
  imem   : ORIGIN = 0x00010000, LENGTH = 0x00010000
  dmem   : ORIGIN = 0x00020000, LENGTH = 0x00010000
  dram_i : ORIGIN = 0x20000000, LENGTH = 0x00400000
  dram_d : ORIGIN = 0x20400000, LENGTH = 0x00400000
  in8_d  : ORIGIN = 0x50000000, LENGTH = 0x00100000
  out8_d : ORIGIN = 0x60000000, LENGTH = 0x00100000
  w2_d   : ORIGIN = 0x70000000, LENGTH = 0x00100000
  bias_d : ORIGIN = 0x71000000, LENGTH = 0x00100000
  param_d: ORIGIN = 0x72000000, LENGTH = 0x00100000
  epu_d  : ORIGIN = 0x80000000, LENGTH = 0x00100000
}

/* Specify the default entry point to the program */

ENTRY(_start)

/*****************************************************************************
 * Define the sections, and where they are mapped in memory 
 ****************************************************************************/
SECTIONS {
  .text0 : {
    setup.o(.text);
    boot.o(.text);
    . = 0x00001000;
    isr0.o(.text);
  } > rom

  .text1 : {
    _imem_start = .;
    *(.text);
    *(.text.*);
  } > imem AT > dram_i

  .init : {
    KEEP (*(.init))
  } > imem AT > dram_i

  .fini : {
    KEEP (*(.fini))
  } > imem AT > dram_i

  .rodata : {
    __rodata_start = .;
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
    __rodata_end = .;
  } > imem AT > dram_i

  _dram_i_start = ORIGIN(dram_i);
  _dram_i_end = ORIGIN(dram_i) + . - ORIGIN(imem);

  _test : {
    . = ALIGN(4);
    _test_start = .;
    . += _TEST_SIZE;
    _test_end = .;
  } > dram_d

  .sbss : {
    __sbss_start = .;
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    __sbss_end = .;
  } > dmem

  .sdata : {
    __sdata_paddr_start = LOADADDR(.sdata);
    __sdata_start = .;
    _gp = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    __sdata_end = .;
  } > dmem AT > dram_d

/* Convolution data begin */
/* conv0 */
  .in8_conv0_dat : {
    . = ALIGN(4);
    __in8_conv0_data_in_dram_start = LOADADDR(.in8_conv0_dat);
    __in8_conv0_start = .;
    In8_conv0.o(.data)
    __in8_conv0_end = .;
  } > in8_d AT > dram_d

  .w2_conv0_dat : {
    . = ALIGN(4);
    __w2_conv0_data_in_dram_start = LOADADDR(.w2_conv0_dat);
    __w2_conv0_start = .;
    W2_conv0.o(.data)
    __w2_conv0_end = .;
  } > w2_d AT > dram_d

  .bias_conv0_dat : {
    . = ALIGN(4);
    __bias_conv0_data_in_dram_start = LOADADDR(.bias_conv0_dat);
    __bias_conv0_start = .;
    Bias32_conv0.o(.data)
    __bias_conv0_end = .;
  } > bias_d AT > dram_d

  .param_conv0_dat : {
    . = ALIGN(4);
    __param_conv0_data_in_dram_start = LOADADDR(.param_conv0_dat);
    __param_conv0_start = .;
    param_conv0.o(.data)
    __param_conv0_end = .;
  } > param_d AT > dram_d

/* conv1 */
  .w2_conv1_dat : {
    . = ALIGN(4);
    __w2_conv1_data_in_dram_start = LOADADDR(.w2_conv1_dat);
    __w2_conv1_start = .;
    W2_conv1.o(.data)
    __w2_conv1_end = .;
  } > w2_d AT > dram_d

  .bias_conv1_dat : {
    . = ALIGN(4);
    __bias_conv1_data_in_dram_start = LOADADDR(.bias_conv1_dat);
    __bias_conv1_start = .;
    Bias32_conv1.o(.data)
    __bias_conv1_end = .;
  } > bias_d AT > dram_d

  .param_conv1_dat : {
    . = ALIGN(4);
    __param_conv1_data_in_dram_start = LOADADDR(.param_conv1_dat);
    __param_conv1_start = .;
    param_conv1.o(.data)
    __param_conv1_end = .;
  } > param_d AT > dram_d

/* pool0 */
  .out8_pool0_dat : {
    . = ALIGN(4);
    __out8_pool0_data_in_dram_start = LOADADDR(.out8_pool0_dat);
    __out8_pool0_start = .;
    Out8_pool0.o(.data)
    __out8_pool0_end = .;
  } > out8_d AT > dram_d

  .param_pool0_dat : {
    . = ALIGN(4);
    __param_pool0_data_in_dram_start = LOADADDR(.param_pool0_dat);
    __param_pool0_start = .;
    param_pool0.o(.data)
    __param_pool0_end = .;
  } > param_d AT > dram_d
/* Convolution data end */

  .data1 : {
    . = ALIGN(4);
    __data_paddr_start = LOADADDR(.data1);
    __data_start = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    __data_end = .;
  } > dmem AT > dram_d

  .bss : {
    . = ALIGN(4);
    __bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > dmem

  .stack : {
    . = ALIGN(4);
    _stack_end = .;
    . += _STACK_SIZE;
    _stack = .;
    __stack = _stack;
  } > dmem

  . = ORIGIN(dmem) + LENGTH(dmem) - 4;
  _sim_end = .;
  . += 4;
  _end = .;
}
