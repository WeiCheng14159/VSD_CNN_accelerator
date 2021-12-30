`ifndef BRAM_SIM_V
`define BRAM_SIM_V
module bram_sim (
    clk,
    rst,
    en,
    addr,
    R_data,
    W_req,
    W_data
);

  input clk, rst;
  input en;
  input [31:0] addr;
  output [31:0] R_data;
  input [3:0] W_req;
  input [31:0] W_data;

  reg [31:0] bram[60000:0];
  reg [31:0] R_data;

  wire [31:0] addrW;

  integer i;

  assign addrW = addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (en && W_req == 4'b1111) bram[addrW] <= W_data;
  end

  always @(posedge clk or negedge rst) begin
    if (en) R_data <= bram[addrW];
  end

endmodule

`endif
