`ifndef __IDEX__
`define __IDEX__ 
`include "../../include/CPU_def.svh"

interface inf_ID_EX;
  logic [`ADDR_BITS  -1:0] pc;
  logic [`ALUOP_BITS -1:0] aluop;
  logic [`FUNC3_BITS -1:0] func3;
  logic [`FUNC7_BITS -1:0] func7;
  logic [`IMM_BITS   -1:0] imm;
  logic [`TYPE_BITS  -1:0] datatype;
  logic [`BRANCH_BITS-1:0] branch_ctrl;
  logic [`REG_BITS   -1:0] rs1_addr, rs2_addr, rd_addr;
  logic [`DATA_BITS  -1:0] rs1_data, rs2_data;
  logic alu_src;
  logic pc2reg_src;
  logic reg_wr;
  logic rd_src;
  logic dm2reg, dm_rd, dm_wr;
  // CSR
  logic [`CSRADDR_BITS-1:0] csr_addr;
  logic csr;
  logic csr_src;
  logic csr_wr;
  logic csr_set;
  logic csr_clr;
  logic csr_mret;
  logic csr_wfi;

  modport ID2EX(
      output pc,
      output aluop,
      output func3, func7,
      output imm,
      output datatype,
      output rs1_addr, rs2_addr, rd_addr,
      output rs1_data, rs2_data,
      output branch_ctrl,
      output alu_src,
      output pc2reg_src,
      output reg_wr,
      output rd_src,
      output dm2reg, dm_rd, dm_wr,
      // CSR
      output csr_addr,
      output csr,
      output csr_src,
      output csr_wr,
      output csr_set,
      output csr_clr,
      output csr_mret,
      output csr_wfi
  );
  modport EX2ID(
      input pc,
      input aluop,
      input func3, func7,
      input imm,
      input datatype,
      input rs1_addr, rs2_addr, rd_addr,
      input rs1_data, rs2_data,
      input branch_ctrl,
      input alu_src,
      input pc2reg_src,
      input reg_wr,
      input rd_src,
      input dm2reg, dm_rd, dm_wr,
      // CSR
      input csr_addr,
      input csr,
      input csr_src,
      input csr_wr,
      input csr_set,
      input csr_clr,
      input csr_mret,
      input csr_wfi
  );

endinterface : inf_ID_EX
`endif
