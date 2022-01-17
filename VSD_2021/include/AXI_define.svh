`ifndef __AXIBITS_DEF__
`define __AXIBITS_DEF__

    `define AXI_ADDR_BITS 32
    `define AXI_DATA_BITS 32
    
    // define MASTER
    `define AXI_MASTER_NUM     3
    `define AXI_MASTER_BITS    4
    `define AXI_DEFAULT_MASTER `AXI_MASTER_BITS'h0
    `define AXI_MASTER0        `AXI_MASTER_BITS'h1
    `define AXI_MASTER1        `AXI_MASTER_BITS'h2
    `define AXI_MASTER2        `AXI_MASTER_BITS'h3

    // define SLAVE
    `define AXI_SLAVE_BITS    8
    // `define AXI_SLAVE_BITS    7
    `define AXI_SLAVE0        `AXI_SLAVE_BITS'b1
    `define AXI_SLAVE1        `AXI_SLAVE_BITS'b10
    `define AXI_SLAVE2        `AXI_SLAVE_BITS'b100
    `define AXI_SLAVE3        `AXI_SLAVE_BITS'b1000
    `define AXI_SLAVE4        `AXI_SLAVE_BITS'b10000
    `define AXI_SLAVE5        `AXI_SLAVE_BITS'b100000
    `define AXI_SLAVE6        `AXI_SLAVE_BITS'b1000000
    // `define AXI_DEFAULT_SLAVE `AXI_SLAVE_BITS'b1000000
    `define AXI_DEFAULT_SLAVE `AXI_SLAVE_BITS'b10000000
    `define d                 `AXI_SLAVE_BITS-1

    `define AXI_ID_BITS   4
    `define AXI_IDS_BITS  8
    `define AXI_M0_ID     `AXI_ID_BITS'h0
    `define AXI_M1_ID     `AXI_ID_BITS'h1
    `define AXI_DMA_ID    `AXI_ID_BITS'h2


    `define AXI_SIZE_BITS  3
    `define AXI_SIZE_BYTE  `AXI_SIZE_BITS'b000
    `define AXI_SIZE_HWORD `AXI_SIZE_BITS'b001
    `define AXI_SIZE_WORD  `AXI_SIZE_BITS'b010

    `define AXI_STRB_BITS  4
    `define AXI_STRB_WORD  `AXI_STRB_BITS'b1111
    `define AXI_STRB_HWORD `AXI_STRB_BITS'b0011
    `define AXI_STRB_BYTE  `AXI_STRB_BITS'b0001


    `define AXI_BURST_BITS  2
	`define AXI_BURST_FIXED `AXI_BURST_BITS'h0
    `define AXI_BURST_INC   `AXI_BURST_BITS'h1
	`define AXI_BURST_WRAP  `AXI_BURST_BITS'h2

    `define AXI_RESP_BITS   2
    `define AXI_RESP_OKAY   2'h0
    `define AXI_RESP_SLVERR 2'h2
    `define AXI_RESP_DECERR 2'h3

    `define AXI_LEN_BITS 8
    `define AXI_LEN_ONE  `AXI_LEN_BITS'h0
	`define AXI_LEN_FOUR `AXI_LEN_BITS'h3

`endif 