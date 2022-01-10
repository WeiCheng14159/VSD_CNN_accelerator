`ifndef SP_RAM_SIM_SV
`define SP_RAM_SIM_SV

`include "conv_acc.svh"

module sp_ram_sim (
    input logic clk,
    input logic rst,
    sp_ram_intf.memory intf
);

  logic [`DATA_BUS_WIDTH-1:0] content[200000:0];
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
`endif
