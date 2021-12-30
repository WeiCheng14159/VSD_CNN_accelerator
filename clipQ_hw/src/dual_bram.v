`ifndef DUAL_BRAM_V
`define DUAL_BRAM_V

module dual_bram (
    clk,
    rst,
    p0_en,
    p0_addr,
    p0_R_data,
    p0_W_req,
    p0_W_data,
    p1_en,
    p1_addr,
    p1_R_data,
    p1_W_req,
    p1_W_data
);

  input clk, rst;
  input p0_en;
  input [31:0] p0_addr;
  output [31:0] p0_R_data;
  input [3:0] p0_W_req;
  input [31:0] p0_W_data;

  input p1_en;
  input [31:0] p1_addr;
  output [31:0] p1_R_data;
  input [3:0] p1_W_req;
  input [31:0] p1_W_data;


  reg [31:0] bram[60000:0];
  reg [31:0] p0_R_data;
  reg [31:0] p1_R_data;
  wire [31:0] p0_addrW;
  wire [31:0] p1_addrW;

  integer i;

  assign p0_addrW = p0_addr >> 2;
  assign p1_addrW = p1_addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (p0_en && p0_W_req == 4'b1111) bram[p0_addrW] <= p0_W_data;
    else if (p1_en && p1_W_req == 4'b1111) bram[p1_addrW] <= p1_W_data;
  end

  always @(posedge clk or negedge rst) begin
    if (p0_en) p0_R_data <= bram[p0_addrW];
  end

  always @(posedge clk or negedge rst) begin
    if (p1_en) p1_R_data <= bram[p1_addrW];
  end

endmodule
`endif
