`ifndef __EXCSR__
`define __EXCSR__
`include "../../include/CPU_def.svh"

interface inf_EX_CSR;
  logic [`ADDR_BITS   -1:0] pc;
  logic [`CSRADDR_BITS-1:0] csr_addr;
  logic [`DATA_BITS   -1:0] rs1_rdata, rd_wdata;
  logic reg_wr;
  logic wr, set, clr, mret, wfi;

  modport EX2CSR(
      input rd_wdata,
      output pc,
      output csr_addr,
      output rs1_rdata,
      output reg_wr,
      output wr, set, clr, mret, wfi
  );
  modport CSR2EX(
      input pc,
      input csr_addr,
      input rs1_rdata,
      input reg_wr,
      input wr, set, clr, mret, wfi,
      output rd_wdata
  );

endinterface : inf_EX_CSR
`endif
