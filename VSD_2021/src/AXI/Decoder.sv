`ifndef __AXIDEC__
`define __AXIDEC__
`include "../../include/AXI_define.svh"

module Decoder (
    input        [`AXI_ADDR_BITS-1:0] addr_i,
    input                             validm_i,
    input                             ready_s0_i,
    input                             ready_s1_i,
    input                             ready_s2_i,
    input                             ready_s3_i,
    input                             ready_s4_i,
    input                             ready_s5_i,
    input                             ready_s6_i,
    input                             ready_sd_i,
    output logic                      valid_s0_o,
    output logic                      valid_s1_o,
    output logic                      valid_s2_o,
    output logic                      valid_s3_o,
    output logic                      valid_s4_o,
    output logic                      valid_s5_o,
    output logic                      valid_s6_o,
    output logic                      valid_sd_o,
    output logic                      readys_o
);

  logic ready_s;
  logic [`AXI_SLAVE_BITS-1:0] valid_s;

  assign readys_o = validm_i & ready_s;
  assign {valid_sd_o,
            valid_s6_o,
            valid_s5_o,
            valid_s4_o,
            valid_s3_o,
            valid_s2_o,
            valid_s1_o,
            valid_s0_o} = valid_s;

  always_comb begin
    valid_s = `AXI_SLAVE_BITS'b0;
    // ROM
    if (addr_i >= `AXI_ADDR_BITS'h0 && addr_i < `AXI_ADDR_BITS'h4000) begin
      ready_s    = ready_s0_i;
      valid_s[0] = validm_i;
    end
        // IM
        else
    if (addr_i > `AXI_ADDR_BITS'hffff && addr_i < `AXI_ADDR_BITS'h2_0000) begin
      ready_s    = ready_s1_i;
      valid_s[1] = validm_i;
    end
        // DM
        else
    if (addr_i > `AXI_ADDR_BITS'h1_ffff && addr_i < `AXI_ADDR_BITS'h3_0000) begin
      ready_s    = ready_s2_i;
      valid_s[2] = validm_i;
    end
        // sensor_ctrl
        else
    if (addr_i > `AXI_ADDR_BITS'hfff_ffff && addr_i < `AXI_ADDR_BITS'h1000_0400) begin
      ready_s    = ready_s3_i;
      valid_s[3] = validm_i;
    end
        // DRAM
        else
    if (addr_i > `AXI_ADDR_BITS'h1fff_ffff && addr_i < `AXI_ADDR_BITS'h2080_0000) begin
      ready_s    = ready_s4_i;
      valid_s[4] = validm_i;
    end
        // DMA
        else
    if (addr_i > `AXI_ADDR_BITS'h3fff_ffff && addr_i < `AXI_ADDR_BITS'h4001_0000) begin
      ready_s    = ready_s5_i;
      valid_s[5] = validm_i;
    end
        // EPU
        else
    if (addr_i > `AXI_ADDR_BITS'h4fff_ffff && addr_i < `AXI_ADDR_BITS'h8fff_ffff) begin
      ready_s    = ready_s6_i;
      valid_s[6] = validm_i;
    end else begin
      ready_s     = ready_sd_i;
      valid_s[`d] = validm_i;
    end
  end

endmodule
`endif
