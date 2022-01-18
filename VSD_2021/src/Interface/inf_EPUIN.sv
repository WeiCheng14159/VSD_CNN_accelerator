`ifndef __INFEPUIN__
`define __INFEPUIN__
`include "../../include/EPU_def.svh"
`include "../../include/AXI_define.svh"

interface inf_EPUIN;
    logic OE, CS;
    logic arhns, awhns, rlast, wrfin, whns;
    logic [`EPU_ADDR_BITS-1:0] addr;
    logic [`AXI_DATA_BITS-1:0] wdata;

    modport EPUin (
        input OE, CS,
        input arhns, awhns, rlast, wrfin, whns,
        input addr,
        input wdata
    );
endinterface: inf_EPUIN
`endif