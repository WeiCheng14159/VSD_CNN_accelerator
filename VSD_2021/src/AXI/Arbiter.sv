`ifndef __AXIARB__
`define __AXIARB__
`include "../../include/AXI_define.svh"

module Arbiter (
    input                              clk,
    rst,
    // M0
    input        [`AXI_ID_BITS   -1:0] id_m0_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m0_i,
    input        [`AXI_LEN_BITS  -1:0] len_m0_i,
    input        [`AXI_SIZE_BITS -1:0] size_m0_i,
    input        [`AXI_BURST_BITS-1:0] burst_m0_i,
    input                              valid_m0_i,
    // M1
    input        [`AXI_ID_BITS   -1:0] id_m1_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m1_i,
    input        [`AXI_LEN_BITS  -1:0] len_m1_i,
    input        [`AXI_SIZE_BITS -1:0] size_m1_i,
    input        [`AXI_BURST_BITS-1:0] burst_m1_i,
    input                              valid_m1_i,
    // M2
    input        [`AXI_ID_BITS   -1:0] id_m2_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m2_i,
    input        [`AXI_LEN_BITS  -1:0] len_m2_i,
    input        [`AXI_SIZE_BITS -1:0] size_m2_i,
    input        [`AXI_BURST_BITS-1:0] burst_m2_i,
    input                              valid_m2_i,
    // S
    input                              readys_i,
    // output Master
    output logic [`AXI_IDS_BITS  -1:0] id_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_o,
    output logic [`AXI_LEN_BITS  -1:0] len_o,
    output logic [`AXI_SIZE_BITS -1:0] size_o,
    output logic [`AXI_BURST_BITS-1:0] burst_o,
    output logic                       valid_o,
    output logic                       ready_m0_o,
    output logic                       ready_m1_o,
    output logic                       ready_m2_o
);

  logic [`AXI_MASTER_BITS-1:0] master;
  logic [`AXI_MASTER_NUM -1:0] readyout_m;

  always_comb begin
    if (valid_m2_i) master = `AXI_MASTER2;
    else if (valid_m1_i) master = `AXI_MASTER1;
    else if (valid_m0_i) master = `AXI_MASTER0;
    else master = `AXI_DEFAULT_MASTER;
  end

  assign {ready_m2_o, ready_m1_o, ready_m0_o} = readyout_m;
  always_comb begin
    id_o       = {`AXI_DEFAULT_MASTER, `AXI_ID_BITS'b0};
    addr_o     = `AXI_ADDR_BITS'h0;
    len_o      = `AXI_LEN_BITS'h0;
    size_o     = `AXI_SIZE_BITS'h0;
    burst_o    = `AXI_BURST_BITS'h0;
    valid_o    = 1'b0;
    readyout_m = 3'b0;
    case (master)
      `AXI_MASTER0: begin
        id_o          = {`AXI_MASTER0, id_m0_i};
        addr_o        = addr_m0_i;
        len_o         = len_m0_i;
        size_o        = size_m0_i;
        burst_o       = burst_m0_i;
        valid_o       = valid_m0_i;
        readyout_m[0] = readys_i & valid_m0_i;
      end
      `AXI_MASTER1: begin
        id_o          = {`AXI_MASTER1, id_m1_i};
        addr_o        = addr_m1_i;
        len_o         = len_m1_i;
        size_o        = size_m1_i;
        burst_o       = burst_m1_i;
        valid_o       = valid_m1_i;
        readyout_m[1] = readys_i & valid_m1_i;
      end
      `AXI_MASTER2: begin
        id_o          = {`AXI_MASTER2, id_m1_i};
        addr_o        = addr_m2_i;
        len_o         = len_m2_i;
        size_o        = size_m2_i;
        burst_o       = burst_m2_i;
        valid_o       = valid_m2_i;
        readyout_m[2] = readys_i & valid_m2_i;
      end
    endcase
  end

endmodule
`endif
