`include "Interface/sp_ram_intf.sv"

module Param_SRAM_16B (
    input logic              rst,
    input logic              clk,
          sp_ram_intf.memory mem
);

  parameter AddressSize = 3;
  parameter Bits = 32;
  parameter Words = 5;
  parameter Bytes = 1;
  logic   [       Bits-1:0] Memory     [Words-1:0];

  logic                     CS;
  logic                     OE;
  logic                     WEB;
  logic   [ Bytes*Bits-1:0] DI;
  logic   [ Bytes*Bits-1:0] DO;
  logic   [ Bytes*Bits-1:0] latched_DO;
  logic   [AddressSize-1:0] A;
  integer                   i;

  assign A = mem.addr[AddressSize-1:0];
  assign CS = mem.cs;
  assign OE = mem.oe;
  assign DI = mem.W_data;
  assign WEB = mem.W_req;
  assign mem.R_data = DO;

  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      latched_DO <= {(Bytes * Bits) {1'b0}};
      for (i = 0; i < Words; i = i + 1) begin
        Memory[i] <= {(Bytes * Bits) {1'b0}};
      end
    end else if (CS) begin
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
