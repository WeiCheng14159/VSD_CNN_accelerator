interface bram_intf;

  logic en;
  logic [31:0] addr;
  logic [31:0] R_data;
  logic [3:0] W_req;
  logic [31:0] W_data;

  // To memory
  modport memory(output R_data, input en, addr, W_req, W_data);
  // To compute unit
  modport compute(input R_data, output en, addr, W_req, W_data);

endinterface
