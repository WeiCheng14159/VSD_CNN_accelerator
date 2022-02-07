`ifndef __EXMEM__
`define __EXMEM__ 
`include "../../include/CPU_def.svh"

interface inf_EX_MEM;
  logic [`TYPE_BITS-1:0] datatype;
  logic [`DATA_BITS-1:0] aluout;
  logic [`DATA_BITS-1:0] dm_data;
  logic [`ADDR_BITS-1:0] pc2reg;
  logic [`REG_BITS -1:0] rd_addr;
  logic reg_wr;
  logic rd_src;
  logic dm2reg, dm_rd, dm_wr;

  modport EX2MEM(
      output datatype,
      output aluout,
      output dm_data,
      output pc2reg,
      output rd_addr,
      output reg_wr,
      output rd_src,
      output dm2reg, dm_rd, dm_wr
  );
  modport MEM2EX(
      input datatype,
      input aluout,
      input dm_data,
      input pc2reg,
      input rd_addr,
      input reg_wr,
      input rd_src,
      input dm2reg, dm_rd, dm_wr
  );

endinterface : inf_EX_MEM
`endif
