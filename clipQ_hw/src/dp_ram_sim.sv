`ifndef DP_RAM_SIM_SV
`define DP_RAM_SIM_SV

`include "conv_acc.svh"
`include "sp_ram_intf.sv"

module dp_ram_sim (
    input logic            clk,
    input logic            rst,
          sp_ram_intf.memory p0_intf,
          sp_ram_intf.memory p1_intf
);

  logic [`DATA_BUS_WIDTH-1:0] content  [60000:0];
  logic [`ADDR_BUS_WIDTH-1:0] p0_addrW;
  logic [`ADDR_BUS_WIDTH-1:0] p1_addrW;

  assign p0_addrW = p0_intf.addr >> 2;
  assign p1_addrW = p1_intf.addr >> 2;

  always @(posedge clk or negedge rst) begin
    if (p0_intf.en && p0_intf.W_req == {`W_REQ_WIDTH{`WRITE_ENB}})
      content[p0_addrW] <= p0_intf.W_data;
    else if (p1_intf.en && p1_intf.W_req == {`W_REQ_WIDTH{`WRITE_ENB}})
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
