`ifndef DUAL_BRAM_SV
`define DUAL_BRAM_SV

module dual_bram (
    input logic clk,
    input logic rst,
    bram_intf.memory p0_intf,
    bram_intf.memory p1_intf
);

  reg  [31:0] content  [60000:0];
  wire [31:0] p0_addrW;
  wire [31:0] p1_addrW;

  assign p0_addrW = p0_intf.addr >> 2;
  assign p0_addrW = p1_intf.addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (p0_intf.en && p0_intf.W_req == 4'b1111)
      content[p0_addrW] <= p0_intf.W_data;
    else if (p1_intf.en && p1_intf.W_req == 4'b1111)
      content[p1_addrW] <= p1_intf.W_data;
  end

  always @(posedge clk or negedge rst) begin
    if (p0_intf.en) p0_intf.R_data <= content[p0_addrW];
  end

  always @(posedge clk or negedge rst) begin
    if (p1_intf.en) p1_intf.R_data <= content[p1_addrW];
  end

endmodule
`endif
