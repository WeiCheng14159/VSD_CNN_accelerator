/*
void boot() {
	extern unsigned int _dram_i_start;   // instruction start address in DRAM
	extern unsigned int _dram_i_end;     // instruction end address in DRAM
	extern unsigned int _imem_start;     // instruction start address in IM

	extern unsigned int __sdata_start;        // Main_data start address in DM
	extern unsigned int __sdata_end;          // Main_data end address in DM
	extern unsigned int __sdata_paddr_start;  // Main_data start address in DRAM

	extern unsigned int __data_start;        // Main_data start address in DM
	extern unsigned int __data_end;          // Main_data end address in DM
	extern unsigned int __data_paddr_start;  // Main_data start address in DRAM

	int i;
	int len ;

	len = (&_dram_i_end) - (&_dram_i_start) + 1;
	for(i = 0; i < len; i++)
		(&_imem_start)[i] = (&_dram_i_start)[i];

	len = (&__sdata_end) - (&__sdata_start) + 1;
	for(i = 0; i < len; i++)
		(&__sdata_start)[i] = (&__sdata_paddr_start)[i];

	len = (&__data_end) - (&__data_start) + 1;
	for(i = 0; i < len; i++)
		(&__data_start)[i] = (&__data_paddr_start)[i];
}
*/

extern void setDMA(int *source, int *dest, int quantity);

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
    setDMA(&_dram_i_start,&_imem_start,quantity);
    quantity = (&__sdata_end - &__sdata_start );
    setDMA(&__sdata_paddr_start, &__sdata_start, quantity);
    quantity = (&__data_end - &__data_start);
    setDMA(&__data_paddr_start, &__data_start, quantity);

}