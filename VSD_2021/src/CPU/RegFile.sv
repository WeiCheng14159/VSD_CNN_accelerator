`include "../../include/CPU_def.svh"

module RegFile (
    input                   clk,
    rst,
    input                   wb_reg_wr_i,
    input  [`REG_BITS -1:0] rs1_addr_i,
    rs2_addr_i,
    rd_addr_i,
    input  [`DATA_BITS-1:0] rd_data_i,
    output [`DATA_BITS-1:0] rs1_data_o,
    rs2_data_o
);

  logic [`DATA_BITS-1:0] x[0:`REG_NUMS-1];
  integer i;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < `REG_NUMS; i = i + 1) x[i] <= 32'h0;
    end
        // else if (wb_reg_wr_i) begin
        else
    if (wb_reg_wr_i && |rd_addr_i) x[rd_addr_i] <= rd_data_i;
  end

  assign rs1_data_o = x[rs1_addr_i];
  assign rs2_data_o = x[rs2_addr_i];

endmodule

/*
	x0     : zero
	x1     : ra
	x2     : sp
	x3     : gp
	x4     : tp
	x5     : t0
	x6-7   : t1 - 2
	x8     : s0 / fp
	x9     : s1
	x10-11 : a0 - 1
	x12-17 : a2 - 7
	x18-27 : s2 - 11
	x28-31 : t3 - 6
*/
