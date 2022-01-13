`ifndef __INFEPUIN__
`define __INFEPUIN__
`include "../../include/EPU_def.svh"
`include "../../include/AXI_define.svh"

interface inf_EPUIN;
    logic enb, OE, CS;
    logic mode;
    logic arhns, awhns, rdfin, wrfin;
    // logic [`WEB_BITS     -1:0] web;
    logic [`EPU_ADDR_BITS-1:0] addr;
    logic [`AXI_DATA_BITS-1:0] wdata;

    modport EPUin (
        input OE, CS,
        input arhns, awhns, rdfin, wrfin,
        input addr,
        // input web,
        input wdata
    );
endinterface: inf_EPUIN
`endif