`ifndef RAM_INTF_SV
`define RAM_INTF_SV
`include "conv_acc.svh"

interface ram_intf;

  logic cs;
  logic oe;
  logic [`ADDR_BUS_WIDTH-1:0] addr;
  logic [`DATA_BUS_WIDTH-1:0] R_data;
  logic                       W_req;
  logic [`DATA_BUS_WIDTH-1:0] W_data;

  // To memory
  modport memory(output R_data, input cs, oe, addr, W_req, W_data);
  // To compute unit
  modport compute(input R_data, output cs, oe, addr, W_req, W_data);

endinterface
`endif
