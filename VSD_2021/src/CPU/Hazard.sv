`include "../../include/CPU_def.svh"

module Hazard (
    input  [`REG_BITS   -1:0] id_rs1_addr_i,
    id_rs2_addr_i,
    input  [`BRANCH_BITS-1:0] exe_branch_ctrl_i,
    input                     exe_zero_flag_i,
    input                     exe_dm_rd_i,
    input  [`REG_BITS   -1:0] exe_rd_addr_i,
    output                    stall_o,
    flush_o,

    input csr_wfi_i,
    csr_mret_i,
    csr_int_i
);
  // Load
  bit rd_rs1, rd_rs2;
  assign rd_rs1  = exe_rd_addr_i == id_rs1_addr_i;
  assign rd_rs2  = exe_rd_addr_i == id_rs2_addr_i;
  assign stall_o = exe_dm_rd_i & (rd_rs1 | rd_rs2);
  // Jump 
  bit jalr, jal;
  bit flush_j;
  assign jalr    = exe_branch_ctrl_i == `BRANCH_JALR;
  assign jal     = exe_branch_ctrl_i == `BRANCH_JAL;
  assign flush_j = jalr | jal;
  // Control
  bit beq;
  bit flush_beq;
  assign beq       = exe_branch_ctrl_i == `BRANCH_BEQ;
  assign flush_beq = ~beq ? 1'b0 : ~exe_zero_flag_i;

  // Flush
  logic flush_csr;
  assign flush_csr = csr_wfi_i | csr_mret_i | csr_int_i;
  assign flush_o   = flush_beq | flush_j | flush_csr;

endmodule
