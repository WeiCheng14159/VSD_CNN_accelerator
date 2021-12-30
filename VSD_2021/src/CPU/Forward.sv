`include "../../include/CPU_def.svh"

module Forward (
    input        [`REG_BITS    -1:0] exe_rs1_addr_i,
    input        [`REG_BITS    -1:0] exe_rs2_addr_i,
    input                            mem_reg_wr_i,
    input        [`REG_BITS    -1:0] mem_rd_addr_i,
    input                            wb_reg_wr_i,
    input        [`REG_BITS    -1:0] wb_rd_addr_i,
    output logic [`FORWARD_BITS-1:0] forward_rs1_o,
    forward_rs2_o
);
  bit exe_hazard1, exe_hazard2;
  bit mem_hazard1, mem_hazard2;
  assign exe_hazard1 = mem_reg_wr_i & |mem_rd_addr_i & (exe_rs1_addr_i == mem_rd_addr_i);
  assign exe_hazard2 = mem_reg_wr_i & |mem_rd_addr_i & (exe_rs2_addr_i == mem_rd_addr_i);
  assign mem_hazard1 = wb_reg_wr_i  & |wb_rd_addr_i  & (exe_rs1_addr_i == wb_rd_addr_i);
  assign mem_hazard2 = wb_reg_wr_i  & |wb_rd_addr_i  & (exe_rs2_addr_i == wb_rd_addr_i);
  always_comb begin
    if (exe_hazard1) forward_rs1_o = `FORWARD_MEMRD;  // 2'h1
    else if (mem_hazard1) forward_rs1_o = `FORWARD_WBRD;  // 2'h2
    else forward_rs1_o = `FORWARD_IDRS;  // 2'h0
  end
  always_comb begin
    if (exe_hazard2) forward_rs2_o = `FORWARD_MEMRD;  // 2'h1
    else if (mem_hazard2) forward_rs2_o = `FORWARD_WBRD;  // 2'h2
    else forward_rs2_o = `FORWARD_IDRS;  // 2'h0
  end

endmodule
