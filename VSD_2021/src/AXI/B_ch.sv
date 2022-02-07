`include "../../include/AXI_define.svh"

module B_ch (
    input                             clk,
    rst,
    // M1
    output       [`AXI_ID_BITS  -1:0] id_m1_o,
    output       [`AXI_RESP_BITS-1:0] resp_m1_o,
    output logic                      valid_m1_o,
    input                             ready_m1_i,
    // M2
    output       [`AXI_ID_BITS  -1:0] id_m2_o,
    output       [`AXI_RESP_BITS-1:0] resp_m2_o,
    output logic                      valid_m2_o,
    input                             ready_m2_i,
    // S0
    input        [`AXI_IDS_BITS -1:0] ids_s0_i,
    input        [`AXI_RESP_BITS-1:0] resp_s0_i,
    input                             valid_s0_i,
    output logic                      ready_s0_o,
    // S1
    input        [`AXI_IDS_BITS -1:0] ids_s1_i,
    input        [`AXI_RESP_BITS-1:0] resp_s1_i,
    input                             valid_s1_i,
    output logic                      ready_s1_o,
    // S2
    input        [`AXI_IDS_BITS -1:0] ids_s2_i,
    input        [`AXI_RESP_BITS-1:0] resp_s2_i,
    input                             valid_s2_i,
    output logic                      ready_s2_o,
    // S3
    input        [`AXI_IDS_BITS -1:0] ids_s3_i,
    input        [`AXI_RESP_BITS-1:0] resp_s3_i,
    input                             valid_s3_i,
    output logic                      ready_s3_o,
    // S4
    input        [`AXI_IDS_BITS -1:0] ids_s4_i,
    input        [`AXI_RESP_BITS-1:0] resp_s4_i,
    input                             valid_s4_i,
    output logic                      ready_s4_o,
    // S5
    input        [`AXI_IDS_BITS -1:0] ids_s5_i,
    input        [`AXI_RESP_BITS-1:0] resp_s5_i,
    input                             valid_s5_i,
    output logic                      ready_s5_o,
    // S6
    input        [`AXI_IDS_BITS -1:0] ids_s6_i,
    input        [`AXI_RESP_BITS-1:0] resp_s6_i,
    input                             valid_s6_i,
    output logic                      ready_s6_o,
    // SD
    input        [`AXI_IDS_BITS -1:0] ids_sd_i,
    input        [`AXI_RESP_BITS-1:0] resp_sd_i,
    input                             valid_sd_i,
    output logic                      ready_sd_o
);

  logic [`AXI_MASTER_BITS-1:0] master;
  logic [`AXI_SLAVE_BITS -1:0] slave;
  logic ready_m;
  logic [`AXI_IDS_BITS   -1:0] ids_s;
  logic [`AXI_RESP_BITS  -1:0] resp_s;
  logic valid_s;
  logic [`AXI_SLAVE_BITS-1:0] readyout_s;

  // {{{ Master
  // M0
  logic [`AXI_ID_BITS  -1:0] id_m0;
  logic [`AXI_RESP_BITS-1:0] resp_m0;
  logic valid_m0, ready_m0;
  assign id_m0    = `AXI_ID_BITS'h0;
  assign resp_m0  = `AXI_RESP_BITS'h0;
  assign ready_m0 = 1'b0;
  // M1
  assign id_m1_o   = ids_s[`AXI_ID_BITS-1:0];
  assign resp_m1_o = resp_s;
  //
  assign master = ids_s[`AXI_IDS_BITS-1:`AXI_ID_BITS];
  always_comb begin
    case (master)
      `AXI_MASTER1: ready_m = ready_m1_i;
      `AXI_MASTER2: ready_m = ready_m2_i;
      default:      ready_m = 1'b1;
    endcase
  end
  // output
  logic [`AXI_MASTER_NUM -1:0] validout_m;
  assign {valid_m2_o, valid_m1_o, valid_m0} = {
    validout_m[`AXI_MASTER_NUM-1:1], 1'b0
  };
  always_comb begin
    validout_m = `AXI_MASTER_NUM'b0;
    case (master)
      `AXI_MASTER1: validout_m[1] = valid_s;
      `AXI_MASTER2: validout_m[2] = valid_s;
    endcase
  end
  // }}}
  // Slave
  assign slave = {
    valid_sd_i,
    valid_s6_i,
    valid_s5_i,
    valid_s4_i,
    valid_s3_i,
    valid_s2_i,
    valid_s1_i,
    valid_s0_i
  };
  always_comb begin
    ids_s   = `AXI_IDS_BITS'h0;
    resp_s  = `AXI_RESP_BITS'b0;
    valid_s = 1'b0;
    case (slave)
      `AXI_SLAVE0: {ids_s, resp_s, valid_s} = {ids_s0_i, resp_s0_i, valid_s0_i};
      `AXI_SLAVE1: {ids_s, resp_s, valid_s} = {ids_s1_i, resp_s1_i, valid_s1_i};
      `AXI_SLAVE2: {ids_s, resp_s, valid_s} = {ids_s2_i, resp_s2_i, valid_s2_i};
      `AXI_SLAVE3: {ids_s, resp_s, valid_s} = {ids_s3_i, resp_s3_i, valid_s3_i};
      `AXI_SLAVE4: {ids_s, resp_s, valid_s} = {ids_s4_i, resp_s4_i, valid_s4_i};
      `AXI_SLAVE5: {ids_s, resp_s, valid_s} = {ids_s5_i, resp_s5_i, valid_s5_i};
      `AXI_SLAVE6: {ids_s, resp_s, valid_s} = {ids_s6_i, resp_s6_i, valid_s6_i};
      `AXI_DEFAULT_SLAVE:
      {ids_s, resp_s, valid_s} = {ids_sd_i, resp_sd_i, valid_sd_i};
    endcase
  end

  assign {ready_sd_o,
            ready_s6_o,
            ready_s5_o,
            ready_s4_o, 
            ready_s3_o, 
            ready_s2_o, 
            ready_s1_o, 
            ready_s0_o} = readyout_s;
  assign readyout_s = {`AXI_SLAVE_BITS{ready_m}} & slave;


endmodule
