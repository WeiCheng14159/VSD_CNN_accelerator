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

/*****************************************************************
 * Function: void copy()                                         *
 * Description: Part of interrupt service routine (ISR).         *
 *              Copy data from sensor controller to data memory. *
 *****************************************************************/
void copy () {
  int i;
  for (i = 0; i < sensor_size; i++) { // Copy data from sensor controller to DM
    *(copy_addr + i) = sensor_addr[i];
  }
  copy_addr += sensor_size; // Update copy address
  copy_count++;    // Increase copy count
  sensor_addr[0x80] = 1; // Enable sctrl_clear
  sensor_addr[0x80] = 0; // Disable sctrl_clear
  
  return;
}

void setDMA(int *source, int *dest, int quantity) {
    unsigned int *dma_ctrl_addr = (int *) 0x40000000; 
    *(dma_ctrl_addr+0) = (int)source;  
    *(dma_ctrl_addr+1) = (int)dest;
    *(dma_ctrl_addr+2) = (int)quantity;
    *(dma_ctrl_addr+3) = 1;  // Enable DMA
    asm("wfi");
};

int main(void) {
  extern unsigned int _test_start;
  copy_addr = &_test_start;

  // Enable Global Interrupt
  asm("csrsi mstatus, 0x8"); // MIE of mstatus

  // Enable Local Interrupt
  asm("li t6, 0x800");
  asm("csrs mie, t6"); // MEIE of mie 

  return 0;
}
