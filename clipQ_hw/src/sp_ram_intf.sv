`ifndef SP_RAM_INTF_SV
`define SP_RAM_INTF_SV
`include "conv_acc.svh"

interface sp_ram_intf;

  logic en;
  logic [`ADDR_BUS_WIDTH-1:0] addr;
  logic [`DATA_BUS_WIDTH-1:0] R_data;
  logic [`W_REQ_WIDTH-1:0]    W_req;
  logic [`DATA_BUS_WIDTH-1:0] W_data;

  // To memory
  modport memory(output R_data, input en, addr, W_req, W_data);
  // To compute unit
  modport compute(input R_data, output en, addr, W_req, W_data);

endinterface
`endif