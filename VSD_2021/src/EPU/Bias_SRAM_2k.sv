`include "EPU/SRAM_32b_384w_2k.sv"
`include "Interface/sp_ram_intf.sv"

// One 2kB SRAM

module Bias_SRAM_2k (
    input logic              clk,
          sp_ram_intf.memory mem
);

  logic        CS;
  logic        OE;
  logic        WEB;
  logic [ 8:0] A;
  logic [31:0] DI;
  logic [31:0] DO;

  assign CS = mem.cs;
  assign OE = mem.oe;
  assign A = mem.addr[8:0];
  assign DI = mem.W_data;
  assign WEB = mem.W_req;
  assign mem.R_data = DO;

  SRAM_32b_384w_2k i_SRAM_32b_384w_2k (
      .CK (clk),
      .CS (CS),
      .OE (OE),
      .WEB(WEB),
      .A  (A),
      .DI (DI),
      .DO (DO)
  );

endmodule
