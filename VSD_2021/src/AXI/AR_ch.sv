`include "../../include/AXI_define.svh"
`include "./Arbiter.sv"
`include "./Decoder.sv"

module AR_ch (
    input                              clk,
    rst,
    // M0
    input        [`AXI_ID_BITS   -1:0] id_m0_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m0_i,
    input        [`AXI_LEN_BITS  -1:0] len_m0_i,
    input        [`AXI_SIZE_BITS -1:0] size_m0_i,
    input        [`AXI_BURST_BITS-1:0] burst_m0_i,
    input                              valid_m0_i,
    output logic                       ready_m0_o,
    // M1
    input        [`AXI_ID_BITS   -1:0] id_m1_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m1_i,
    input        [`AXI_LEN_BITS  -1:0] len_m1_i,
    input        [`AXI_SIZE_BITS -1:0] size_m1_i,
    input        [`AXI_BURST_BITS-1:0] burst_m1_i,
    input                              valid_m1_i,
    output logic                       ready_m1_o,
    // M2
    input        [`AXI_ID_BITS   -1:0] id_m2_i,
    input        [`AXI_ADDR_BITS -1:0] addr_m2_i,
    input        [`AXI_LEN_BITS  -1:0] len_m2_i,
    input        [`AXI_SIZE_BITS -1:0] size_m2_i,
    input        [`AXI_BURST_BITS-1:0] burst_m2_i,
    input                              valid_m2_i,
    output logic                       ready_m2_o,
    // S0
    output logic [`AXI_IDS_BITS  -1:0] id_s0_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s0_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s0_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s0_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s0_o,
    output logic                       valid_s0_o,
    input                              ready_s0_i,
    // S1
    output logic [`AXI_IDS_BITS  -1:0] id_s1_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s1_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s1_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s1_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s1_o,
    output logic                       valid_s1_o,
    input                              ready_s1_i,
    // S2
    output logic [`AXI_IDS_BITS  -1:0] id_s2_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s2_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s2_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s2_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s2_o,
    output logic                       valid_s2_o,
    input                              ready_s2_i,
    // S3
    output logic [`AXI_IDS_BITS  -1:0] id_s3_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s3_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s3_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s3_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s3_o,
    output logic                       valid_s3_o,
    input                              ready_s3_i,
    // S4
    output logic [`AXI_IDS_BITS  -1:0] id_s4_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s4_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s4_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s4_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s4_o,
    output logic                       valid_s4_o,
    input                              ready_s4_i,
    // S5
    output logic [`AXI_IDS_BITS  -1:0] id_s5_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s5_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s5_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s5_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s5_o,
    output logic                       valid_s5_o,
    input                              ready_s5_i,
    // S6
    output logic [`AXI_IDS_BITS  -1:0] id_s6_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_s6_o,
    output logic [`AXI_LEN_BITS  -1:0] len_s6_o,
    output logic [`AXI_SIZE_BITS -1:0] size_s6_o,
    output logic [`AXI_BURST_BITS-1:0] burst_s6_o,
    output logic                       valid_s6_o,
    input                              ready_s6_i,
    // SD
    output logic [`AXI_IDS_BITS  -1:0] id_sd_o,
    output logic [`AXI_ADDR_BITS -1:0] addr_sd_o,
    output logic [`AXI_LEN_BITS  -1:0] len_sd_o,
    output logic [`AXI_SIZE_BITS -1:0] size_sd_o,
    output logic [`AXI_BURST_BITS-1:0] burst_sd_o,
    output logic                       valid_sd_o,
    input                              ready_sd_i
);

  logic [`AXI_IDS_BITS  -1:0] id_m;
  logic [`AXI_ADDR_BITS -1:0] addr_m;
  logic [`AXI_LEN_BITS  -1:0] len_m;
  logic [`AXI_SIZE_BITS -1:0] size_m;
  logic [`AXI_BURST_BITS-1:0] burst_m;
  logic valid_m;
  logic [`AXI_SLAVE_BITS-1:0] valid_s, validout_s, readyin_s;
  logic ready_s;

  assign readyin_s = {
    ready_sd_i,
    ready_s6_i,
    ready_s5_i,
    ready_s4_i,
    ready_s3_i,
    ready_s2_i,
    ready_s1_i,
    ready_s0_i
  };
  assign {valid_sd_o,
            valid_s6_o,
            valid_s5_o,
            valid_s4_o,
            valid_s3_o,
            valid_s2_o,
            valid_s1_o,
            valid_s0_o} = validout_s;

  assign validout_s = readyin_s & valid_s;
  // S0
  assign id_s0_o = id_m;
  assign addr_s0_o = addr_m;
  assign len_s0_o = len_m;
  assign size_s0_o = size_m;
  assign burst_s0_o = burst_m;
  // S1
  assign id_s1_o = id_m;
  assign addr_s1_o = addr_m;
  assign len_s1_o = len_m;
  assign size_s1_o = size_m;
  assign burst_s1_o = burst_m;
  // S2
  assign id_s2_o = id_m;
  assign addr_s2_o = addr_m;
  assign len_s2_o = len_m;
  assign size_s2_o = size_m;
  assign burst_s2_o = burst_m;
  // S3
  assign id_s3_o = id_m;
  assign addr_s3_o = addr_m;
  assign len_s3_o = len_m;
  assign size_s3_o = size_m;
  assign burst_s3_o = burst_m;
  // S4
  assign id_s4_o = id_m;
  assign addr_s4_o = addr_m;
  assign len_s4_o = len_m;
  assign size_s4_o = size_m;
  assign burst_s4_o = burst_m;
  // S5
  assign id_s5_o = id_m;
  assign addr_s5_o = addr_m;
  assign len_s5_o = len_m;
  assign size_s5_o = size_m;
  assign burst_s5_o = burst_m;
  // S6
  assign id_s6_o = id_m;
  assign addr_s6_o = addr_m;
  assign len_s6_o = len_m;
  assign size_s6_o = size_m;
  assign burst_s6_o = burst_m;
  // SD
  assign id_sd_o = id_m;
  assign addr_sd_o = addr_m;
  assign len_sd_o = len_m;
  assign size_sd_o = size_m;
  assign burst_sd_o = burst_m;

  Arbiter ar_arbiter (
      .clk       (clk),
      .rst       (rst),
      // M0
      .id_m0_i   (id_m0_i),
      .addr_m0_i (addr_m0_i),
      .len_m0_i  (len_m0_i),
      .size_m0_i (size_m0_i),
      .burst_m0_i(burst_m0_i),
      .valid_m0_i(valid_m0_i),
      // M1
      .id_m1_i   (id_m1_i),
      .addr_m1_i (addr_m1_i),
      .len_m1_i  (len_m1_i),
      .size_m1_i (size_m1_i),
      .burst_m1_i(burst_m1_i),
      .valid_m1_i(valid_m1_i),
      // M2
      .id_m2_i   (id_m2_i),
      .addr_m2_i (addr_m2_i),
      .len_m2_i  (len_m2_i),
      .size_m2_i (size_m2_i),
      .burst_m2_i(burst_m2_i),
      .valid_m2_i(valid_m2_i),
      // S 
      .readys_i  (ready_s),
      // 
      .id_o      (id_m),
      .addr_o    (addr_m),
      .len_o     (len_m),
      .size_o    (size_m),
      .burst_o   (burst_m),
      .valid_o   (valid_m),
      .ready_m0_o(ready_m0_o),
      .ready_m1_o(ready_m1_o),
      .ready_m2_o(ready_m2_o)
  );

  Decoder ar_decoder (
      .addr_i    (addr_m),
      .validm_i  (valid_m),
      .ready_s0_i(ready_s0_i),
      .ready_s1_i(ready_s1_i),
      .ready_s2_i(ready_s2_i),
      .ready_s3_i(ready_s3_i),
      .ready_s4_i(ready_s4_i),
      .ready_s5_i(ready_s5_i),
      .ready_s6_i(ready_s6_i),
      .ready_sd_i(ready_sd_i),
      .valid_s0_o(valid_s[0]),
      .valid_s1_o(valid_s[1]),
      .valid_s2_o(valid_s[2]),
      .valid_s3_o(valid_s[3]),
      .valid_s4_o(valid_s[4]),
      .valid_s5_o(valid_s[5]),
      .valid_s6_o(valid_s[6]),
      .valid_sd_o(valid_s[`d]),
      .readys_o  (ready_s)
  );

endmodule
