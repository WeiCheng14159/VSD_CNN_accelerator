int * dma_ctrl_addr = (int *) 0x40000000; 

void setDMA(int *source, int *dest, int quantity);

void setDMA(int *source, int *dest, int quantity) {
    *(dma_ctrl_addr+0) = (int)source;  
    *(dma_ctrl_addr+1) = (int)dest;
    *(dma_ctrl_addr+2) = (int)quantity;
    *(dma_ctrl_addr+3) = 1;  // Enable DMA
    asm("wfi");
};