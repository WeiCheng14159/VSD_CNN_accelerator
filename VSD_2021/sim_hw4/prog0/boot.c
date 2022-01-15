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


// void setDMA(int *source,int *dest,int length){
//     volatile int *_dma_i_start = (int *) 0x40000000;
//     int tmpSource = (int)source;
//     int tmpdest = (int)dest;
//     while(length){
//         int x = length >= 255 ? 255: length;
//         length -= x;
//         *(_dma_i_start+0) = tmpSource;  
//         *(_dma_i_start+1) = tmpdest;
//         *(_dma_i_start+2) = x;
//         *(_dma_i_start+3) = 1;
//         while(1)
//             if(*(_dma_i_start+4) == 1) break;
//         tmpSource =  tmpSource + (x << 2) + 4;
//         tmpdest  = tmpdest + (x << 2 )+ 4;
//     }
// }

// int boot(){
//     extern int _dram_i_start; 
//     extern int _dram_i_end; 
//     extern int _imem_start;
//     extern int __sdata_paddr_start;
//     extern int __sdata_start;
//     extern int __sdata_end;
//     extern int __data_paddr_start;
//     extern int __data_start;
//     extern int __data_end;
//     int length = (&_dram_i_end - &_dram_i_start);
//     setDMA(&_dram_i_start,&_imem_start,length);
//     length = (&__sdata_end - &__sdata_start );
//     setDMA(&__sdata_start,&__sdata_paddr_start,length);
//     length = (&__data_end - &__data_start);
//     setDMA(&__data_start,&__data_paddr_start,length);
//     return 0;
// }


