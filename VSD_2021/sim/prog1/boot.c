void boot() {
	extern unsigned int _dram_i_start; //instruction start address in DRAM
	extern unsigned int _dram_i_end;//instruction end address in DRAM
	extern unsigned int _imem_start;//instruction start address in IM

	extern unsigned int __sdata_start;//Main_data start address in DM
	extern unsigned int __sdata_end;//Main_data end address in DM
	extern unsigned int __sdata_paddr_start;//= Main_data start address in DRAM

	extern unsigned int __data_start;//Main_data start address in DM
	extern unsigned int __data_end;//Main_data end address in DM
	extern unsigned int __data_paddr_start;//Main_data start address in DRAM

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
