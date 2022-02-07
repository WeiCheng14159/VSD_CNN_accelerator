`include "../../include/AXI_define.svh"

module R_ch (
    input                             clk,
    rst,
    output       [`AXI_ID_BITS  -1:0] id_m0_o,
    output       [`AXI_DATA_BITS-1:0] data_m0_o,
    output       [`AXI_RESP_BITS-1:0] resp_m0_o,
    output logic                      last_m0_o,
    output logic                      valid_m0_o,
    input                             ready_m0_i,
    // M1
    output       [`AXI_ID_BITS  -1:0] id_m1_o,
    output       [`AXI_DATA_BITS-1:0] data_m1_o,
    output       [`AXI_RESP_BITS-1:0] resp_m1_o,
    output logic                      last_m1_o,
    output logic                      valid_m1_o,
    input                             ready_m1_i,
    // M2
    output       [`AXI_ID_BITS  -1:0] id_m2_o,
    output       [`AXI_DATA_BITS-1:0] data_m2_o,
    output       [`AXI_RESP_BITS-1:0] resp_m2_o,
    output logic                      last_m2_o,
    output logic                      valid_m2_o,
    input                             ready_m2_i,
    // S0
    input        [`AXI_IDS_BITS -1:0] id_s0_i,
    input        [`AXI_DATA_BITS-1:0] data_s0_i,
    input        [`AXI_RESP_BITS-1:0] resp_s0_i,
    input                             last_s0_i,
    input                             valid_s0_i,
    output logic                      ready_s0_o,
    // S1
    input        [`AXI_IDS_BITS -1:0] id_s1_i,
    input        [`AXI_DATA_BITS-1:0] data_s1_i,
    input        [`AXI_RESP_BITS-1:0] resp_s1_i,
    input                             last_s1_i,
    input                             valid_s1_i,
    output logic                      ready_s1_o,
    // S2
    input        [`AXI_IDS_BITS -1:0] id_s2_i,
    input        [`AXI_DATA_BITS-1:0] data_s2_i,
    input        [`AXI_RESP_BITS-1:0] resp_s2_i,
    input                             last_s2_i,
    input                             valid_s2_i,
    output logic                      ready_s2_o,
    // S3
    input        [`AXI_IDS_BITS -1:0] id_s3_i,
    input        [`AXI_DATA_BITS-1:0] data_s3_i,
    input        [`AXI_RESP_BITS-1:0] resp_s3_i,
    input                             last_s3_i,
    input                             valid_s3_i,
    output logic                      ready_s3_o,
    // S4
    input        [`AXI_IDS_BITS -1:0] id_s4_i,
    input        [`AXI_DATA_BITS-1:0] data_s4_i,
    input        [`AXI_RESP_BITS-1:0] resp_s4_i,
    input                             last_s4_i,
    input                             valid_s4_i,
    output logic                      ready_s4_o,
    // S5
    input        [`AXI_IDS_BITS -1:0] id_s5_i,
    input        [`AXI_DATA_BITS-1:0] data_s5_i,
    input        [`AXI_RESP_BITS-1:0] resp_s5_i,
    input                             last_s5_i,
    input                             valid_s5_i,
    output logic                      ready_s5_o,
    // S6
    input        [`AXI_IDS_BITS -1:0] id_s6_i,
    input        [`AXI_DATA_BITS-1:0] data_s6_i,
    input        [`AXI_RESP_BITS-1:0] resp_s6_i,
    input                             last_s6_i,
    input                             valid_s6_i,
    output logic                      ready_s6_o,
    // SD
    input        [`AXI_IDS_BITS -1:0] id_sd_i,
    input        [`AXI_DATA_BITS-1:0] data_sd_i,
    input        [`AXI_RESP_BITS-1:0] resp_sd_i,
    input                             last_sd_i,
    input                             valid_sd_i,
    output logic                      ready_sd_o
);

  logic [`AXI_SLAVE_BITS -1:0] slave;
  logic [`AXI_MASTER_BITS-1:0] master;
  logic [`AXI_IDS_BITS -1:0] ids_s;
  logic [`AXI_DATA_BITS-1:0] data_s;
  logic [`AXI_RESP_BITS-1:0] resp_s;
  logic last_s;
  logic valid_s;
  logic [`AXI_SLAVE_BITS-1:0] sel, grant, validin_s, readyout_s;
  logic ready_m;
  logic [`AXI_MASTER_NUM-1:0] validout_m;

  assign validin_s = {
    valid_sd_i,
    valid_s6_i,
    valid_s5_i,
    valid_s4_i,
    valid_s3_i,
    valid_s2_i,
    valid_s1_i,
    valid_s0_i
  };
  always_ff @(posedge clk or negedge rst) begin
    if (~rst) sel <= `AXI_SLAVE_BITS'b0;
    else begin
      sel[ 0] <= (sel[ 0] & ready_m & last_s0_i) ? 1'b0 : (             validin_s[ 0] & ~|validin_s[`d:1] & ~ready_m) ? 1'b1 : sel[ 0];
      sel[ 1] <= (sel[ 1] & ready_m & last_s1_i) ? 1'b0 : (~sel[0]    & validin_s[ 1] & ~|validin_s[`d:2] & ~ready_m) ? 1'b1 : sel[ 1];
      sel[ 2] <= (sel[ 2] & ready_m & last_s2_i) ? 1'b0 : (~|sel[1:0] & validin_s[ 2] & ~|validin_s[`d:3] & ~ready_m) ? 1'b1 : sel[ 2];
      sel[ 3] <= (sel[ 3] & ready_m & last_s3_i) ? 1'b0 : (~|sel[2:0] & validin_s[ 3] & ~|validin_s[`d:4] & ~ready_m) ? 1'b1 : sel[ 3];
      sel[ 4] <= (sel[ 4] & ready_m & last_s4_i) ? 1'b0 : (~|sel[3:0] & validin_s[ 4] & ~|validin_s[`d:5] & ~ready_m) ? 1'b1 : sel[ 4];
      sel[ 5] <= (sel[ 5] & ready_m & last_s5_i) ? 1'b0 : (~|sel[4:0] & validin_s[ 5] & ~|validin_s[`d:6] & ~ready_m) ? 1'b1 : sel[ 5];
      sel[ 6] <= (sel[ 6] & ready_m & last_sd_i) ? 1'b0 : (~|sel[5:0] & validin_s[ 6] & ~|validin_s[`d]   & ~ready_m) ? 1'b1 : sel[ 6];
      sel[`d] <= (sel[`d] & ready_m & last_sd_i) ? 1'b0 : (~|sel[6:0] & validin_s[`d]                     & ~ready_m) ? 1'b1 : sel[`d];
    end
  end
  assign grant[0]  = validin_s[0] | sel[0];
  assign grant[1]  = validin_s[1] & ~sel[0] | sel[1];
  assign grant[2]  = validin_s[2] & (~|sel[1:0]) | sel[2];
  assign grant[3]  = validin_s[3] & (~|sel[2:0]) | sel[3];
  assign grant[4]  = validin_s[4] & (~|sel[3:0]) | sel[4];
  assign grant[5]  = validin_s[5] & (~|sel[4:0]) | sel[5];
  assign grant[6]  = validin_s[6] & (~|sel[5:0]) | sel[6];
  assign grant[`d] = validin_s[`d] & (~|sel[6:0]) | sel[`d];

  always_comb begin
    if (grant[`d]) slave = `AXI_DEFAULT_SLAVE;
    else if (grant[5]) slave = `AXI_SLAVE5;
    else if (grant[6]) slave = `AXI_SLAVE6;
    else if (grant[4]) slave = `AXI_SLAVE4;
    else if (grant[2]) slave = `AXI_SLAVE2;
    else if (grant[3]) slave = `AXI_SLAVE3;
    else if (grant[1]) slave = `AXI_SLAVE1;
    else if (grant[0]) slave = `AXI_SLAVE0;
    else slave = `AXI_SLAVE_BITS'h0;
  end

  // {{{ Master
  assign master = ids_s[`AXI_IDS_BITS-1:`AXI_ID_BITS];
  always_comb begin
    case (master)
      `AXI_MASTER0: ready_m = ready_m0_i;
      `AXI_MASTER1: ready_m = ready_m1_i;
      `AXI_MASTER2: ready_m = ready_m2_i;
      default:      ready_m = 1'b1;
    endcase
  end

  // M0
  assign id_m0_o = ids_s[`AXI_ID_BITS-1:0];
  assign data_m0_o = data_s;
  assign resp_m0_o = resp_s;
  assign last_m0_o = last_s;
  // M1
  assign id_m1_o = ids_s[`AXI_ID_BITS-1:0];
  assign data_m1_o = data_s;
  assign resp_m1_o = resp_s;
  assign last_m1_o = last_s;
  // M2
  assign id_m2_o = ids_s[`AXI_ID_BITS-1:0];
  assign data_m2_o = data_s;
  assign resp_m2_o = resp_s;
  assign last_m2_o = last_s;
  // output
  assign {valid_m2_o, valid_m1_o, valid_m0_o} = validout_m;
  always_comb begin
    validout_m = `AXI_MASTER_NUM'b0;
    case (master)
      `AXI_MASTER0: validout_m[0] = valid_s;
      `AXI_MASTER1: validout_m[1] = valid_s;
      `AXI_MASTER2: validout_m[2] = valid_s;
    endcase
  end
  // }}}
  // {{{ Slave
  // input
  always_comb begin
    ids_s   = `AXI_IDS_BITS'b0;
    data_s  = `AXI_DATA_BITS'b0;
    resp_s  = 2'b0;
    last_s  = 1'b0;
    valid_s = 1'b0;
    case (slave)
      `AXI_SLAVE0:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s0_i, data_s0_i, resp_s0_i, last_s0_i, valid_s0_i
      };
      `AXI_SLAVE1:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s1_i, data_s1_i, resp_s1_i, last_s1_i, valid_s1_i
      };
      `AXI_SLAVE2:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s2_i, data_s2_i, resp_s2_i, last_s2_i, valid_s2_i
      };
      `AXI_SLAVE3:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s3_i, data_s3_i, resp_s3_i, last_s3_i, valid_s3_i
      };
      `AXI_SLAVE4:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s4_i, data_s4_i, resp_s4_i, last_s4_i, valid_s4_i
      };
      `AXI_SLAVE5:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s5_i, data_s5_i, resp_s5_i, last_s5_i, valid_s5_i
      };
      `AXI_SLAVE6:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_s6_i, data_s6_i, resp_s6_i, last_s6_i, valid_s6_i
      };
      `AXI_DEFAULT_SLAVE:
      {ids_s, data_s, resp_s, last_s, valid_s} = {
        id_sd_i, data_sd_i, resp_sd_i, last_sd_i, valid_sd_i
      };
    endcase
  end
  // output
  assign {ready_sd_o,
            ready_s6_o,
            ready_s5_o,
            ready_s4_o,
            ready_s3_o,
            ready_s2_o,
            ready_s1_o,
            ready_s0_o} = readyout_s;
  assign readyout_s = {`AXI_SLAVE_BITS{ready_m}} & validin_s;
  // }}}
endmodule
