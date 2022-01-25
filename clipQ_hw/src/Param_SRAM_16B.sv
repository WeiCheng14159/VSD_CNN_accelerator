`include "sp_ram_intf.sv"

module Param_SRAM_16B (
    input logic              clk,
          sp_ram_intf.memory mem
);

  parameter AddressSize = 32;
  parameter Bits = 32;
  parameter Words = 4;
  parameter Bytes = 1;
  logic [       Bits-1:0] Memory     [Words-1:0];

  logic                   CK;
  logic                   CS;
  logic                   OE;
  logic                   WEB;
  logic [ Bytes*Bits-1:0] DI;
  logic [ Bytes*Bits-1:0] DO;
  logic [ Bytes*Bits-1:0] latched_DO;
  logic [AddressSize-1:0] A;

  assign A = mem.addr;
  assign CK = clk;
  assign CS = mem.cs;
  assign OE = mem.oe;
  assign DI = mem.W_data;
  assign WEB = mem.W_req;
  assign mem.R_data = DO;

  always_ff @(posedge CK) begin
    if (CS) begin
      if (~WEB) begin
        Memory[A]  <= DI;
        latched_DO <= DI;
      end else begin
        latched_DO <= Memory[A];
      end
    end
  end

  always_comb begin
    DO = (OE) ? latched_DO : {(Bytes * Bits) {1'bz}};
  end

endmodule
