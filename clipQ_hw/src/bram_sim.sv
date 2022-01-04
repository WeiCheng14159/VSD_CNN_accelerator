module bram_sim (
    input logic clk,
    input logic rst,
    bram_intf.memory intf
);

  logic [31:0] content[60000:0];
  logic [31:0] addrW;

  assign addrW = intf.addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (intf.en && intf.W_req == 4'b1111) content[addrW] <= intf.W_data;
  end

  always @(posedge clk or negedge rst) begin
    if (intf.en) intf.R_data <= content[addrW];
  end

endmodule
