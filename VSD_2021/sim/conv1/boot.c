void dma_move(int *source, int *dest, int quantity) {
    unsigned int *dma_ctrl_addr = (int *) 0x40000000; 
    *(dma_ctrl_addr+0) = (int)source;  
    *(dma_ctrl_addr+1) = (int)dest;
    *(dma_ctrl_addr+2) = (int)quantity;
    *(dma_ctrl_addr+3) = 1;  // Enable DMA
    asm("wfi");
};

void boot() {
    extern int _dram_i_start; 
    extern int _dram_i_end; 
    extern int _imem_start;
    extern int __sdata_paddr_start;
    extern int __sdata_start;
    extern int __sdata_end;
    extern int __data_paddr_start;
    extern int __data_start;
    extern int __data_end;

    // Enable Global Interrupt
    asm("csrsi mstatus, 0x8"); // MIE of mstatus
    // Enable Local Interrupt
    asm("li t6, 0x800");
    asm("csrs mie, t6"); // MEIE of mie

    int quantity = (&_dram_i_end - &_dram_i_start);
    dma_move(&_dram_i_start,&_imem_start,quantity);
    quantity = (&__sdata_end - &__sdata_start );
    dma_move(&__sdata_paddr_start, &__sdata_start, quantity);
    quantity = (&__data_end - &__data_start);
    dma_move(&__data_paddr_start, &__data_start, quantity);

}