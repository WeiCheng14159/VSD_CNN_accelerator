`ifndef __INFEPUIN__
`define __INFEPUIN__ 
`include "../../include/EPU_def.svh"
`include "../../include/AXI_define.svh"

interface inf_EPUIN;
  logic OE, CS;
  logic arhns, awhns, whns, rhns;
  logic rdfin, wrfin;
  // logic rready;
  logic [`EPU_ADDR_BITS-1:0] addr;
  logic [`AXI_DATA_BITS-1:0] wdata;

  modport EPUin(
      input OE, CS,
      input arhns, awhns,
      input whns, rhns,
      input rdfin, wrfin,
      input addr,
      input wdata
  );
endinterface : inf_EPUIN
`endif
