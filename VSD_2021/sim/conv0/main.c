unsigned int *copy_addr; // = &_test_start;
unsigned int copy_count = 0;
const unsigned int sensor_size = 64;
volatile unsigned int *sensor_addr          = (int *) 0x10000000;
volatile unsigned int *epu_in_buff_addr     = (int *) 0x50000000;

volatile unsigned int *epu_out_buff_addr    = (int *) 0x60000000;
volatile unsigned int *epu_weight_buff_addr = (int *) 0x70000000;
volatile unsigned int *epu_bias_buff_addr   = (int *) 0x71000000;
volatile unsigned int *epu_param_buff_addr  = (int *) 0x72000000;
volatile unsigned int *epu_w8_addr          = (int *) 0x80000000;
volatile unsigned int *epu_ctrl_addr        = (int *) 0x80000004;

extern void dma_move(unsigned int *source, unsigned int *dest, unsigned int quantity);

// void dma_move(int *source, int *dest, int quantity);
void cpu_move(int *source, int *dest, int quantity);

void cpu_move(int *source, int *dest, int quantity) {
  int i;
  for (i = 0; i < quantity; i++) {
    dest[i] = source[i];
  }
};

int main(void) {
  extern unsigned int _test_start;
  /* EPU data address */
  // input data address
  extern unsigned int __in8_start;
  extern unsigned int __in8_end;
  extern unsigned int __in8_data_in_dram_start;
  // w2 data address
  extern unsigned int __w2_start;
  extern unsigned int __w2_end;
  extern unsigned int __w2_data_in_dram_start;
  // bias data address
  extern unsigned int __bias_start;
  extern unsigned int __bias_end;
  extern unsigned int __bias_data_in_dram_start;
  // param data address 
  extern unsigned int __param_start;
  extern unsigned int __param_end;
  extern unsigned int __param_data_in_dram_start;
  // output data address 
  extern unsigned int __out8_start;
  extern unsigned int __out8_end;
  extern unsigned int __out8_data_in_dram_start;

  int quantity;

  // Move input data
  quantity = (&__in8_end - &__in8_start);
  dma_move(&__in8_data_in_dram_start, &__in8_start, quantity);
  // Move param data
  quantity = (&__param_end - &__param_start);
  dma_move(&__param_data_in_dram_start, &__param_start, quantity);
  // Move w2 data
  quantity = (&__w2_end - &__w2_start);
  dma_move(&__w2_data_in_dram_start, &__w2_start, quantity);
  // Move bias data
  quantity = (&__bias_end - &__bias_start);
  dma_move(&__bias_data_in_dram_start, &__bias_start, quantity);




  // // Move param data
  // quantity = (&__param_end - &__param_start);
  // dma_move(&__param_data_in_dram_start, &__param_start, quantity);
  // dma_move(&__param_start, &__param_data_in_dram_start, quantity);
  // // Move w2 data
  // quantity = (&__w2_end - &__w2_start);
  // dma_move(&__w2_data_in_dram_start, &__w2_start, quantity);
  // // Move bias data
  // quantity = (&__bias_end - &__bias_start);
  // dma_move(&__bias_data_in_dram_start, &__bias_start, quantity);

  // // Load W8 into EPU
  // *epu_w8_addr = 0x09F8EA00;

  // // Send EPU control signal
  // *epu_ctrl_addr = 0x1 | (0x3 << 1);
  // asm("wfi");

  // // Move output data back to DRAM
  // quantity = (&__out8_end - &__out8_start);
  // dma_move(&__out8_start, &_test_start, quantity);

  return 0;
}
