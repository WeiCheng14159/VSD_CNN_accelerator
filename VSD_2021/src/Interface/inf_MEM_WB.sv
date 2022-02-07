`ifndef __MEMWB__
`define __MEMWB__ 
`include "../../include/CPU_def.svh"

interface inf_MEM_WB;
  logic [`DATA_BITS-1:0] rd_data;
  logic [`REG_BITS -1:0] rd_addr;
  logic [`DATA_BITS-1:0] dm_out;
  logic reg_wr;
  logic dm2reg;

  modport MEM2WB(
      output rd_data,
      output rd_addr,
      output reg_wr,
      output dm_out,
      output dm2reg
  );
  modport WB2MEM(
      input rd_data,
      input rd_addr,
      input reg_wr,
      input dm_out,
      input dm2reg
  );

endinterface : inf_MEM_WB
`endif
