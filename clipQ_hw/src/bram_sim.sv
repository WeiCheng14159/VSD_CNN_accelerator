`include "conv_acc.svh"

module bram_sim (
    input logic clk,
    input logic rst,
    bram_intf.memory intf
);

  logic [`DATA_BUS_WIDTH-1:0] content[60000:0];
  logic [`ADDR_BUS_WIDTH-1:0] addrW;

  assign addrW = intf.addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (intf.en && intf.W_req == {`W_REQ_WIDTH{`WRITE_ENB}})
      content[addrW] <= intf.W_data;
  end

  always @(posedge clk or negedge rst) begin
    if (intf.en) intf.R_data <= content[addrW];
  end

endmodule
