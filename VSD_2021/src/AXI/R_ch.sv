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
    output       [`AXI_ID_BITS  -1:0] id_m1_o,
    output       [`AXI_DATA_BITS-1:0] data_m1_o,
    output       [`AXI_RESP_BITS-1:0] resp_m1_o,
    output logic                      last_m1_o,
    output logic                      valid_m1_o,
    input                             ready_m1_i,
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

  // S
  logic [`AXI_IDS_BITS -1:0] ids_s;
  logic [`AXI_DATA_BITS-1:0] data_s;
  logic [`AXI_RESP_BITS-1:0] resp_s;
  logic last_s;
  logic valid_s;

  // M
  logic [1:0] validout;
  logic ready_m;


  logic [5:0] sel;
  logic [5:0] grant;
  logic [5:0] validin;
  assign validin = {
    valid_sd_i, valid_s4_i, valid_s3_i, valid_s2_i, valid_s1_i, valid_s0_i
  };
  // assign validin = {valid_sd_i, valid_s4_i, 1'b0, valid_s2_i, valid_s1_i, valid_s0_i};
  always_ff @(posedge clk or negedge rst) begin
    if (~rst) sel <= 6'b0;
    else begin
      sel[0] <= (sel[0] & ready_m & last_s0_i) ? 1'b0 : (             validin[0] & ~|validin[5:1] & ~ready_m) ? 1'b1 : sel[0];
      sel[1] <= (sel[1] & ready_m & last_s1_i) ? 1'b0 : (~sel[0]    & validin[1] & ~|validin[5:2] & ~ready_m) ? 1'b1 : sel[1];
      sel[2] <= (sel[2] & ready_m & last_s2_i) ? 1'b0 : (~|sel[1:0] & validin[2] & ~|validin[5:3] & ~ready_m) ? 1'b1 : sel[2];
      sel[3] <= (sel[3] & ready_m & last_s3_i) ? 1'b0 : (~|sel[2:0] & validin[3] & ~|validin[5:4] & ~ready_m) ? 1'b1 : sel[3];
      sel[4] <= (sel[4] & ready_m & last_s4_i) ? 1'b0 : (~|sel[3:0] & validin[4] & ~|validin[5]   & ~ready_m) ? 1'b1 : sel[4];
      sel[5] <= (sel[5] & ready_m & last_sd_i) ? 1'b0 : (~|sel[4:0] & validin[5]                  & ~ready_m) ? 1'b1 : sel[5];
    end
  end
  assign grant[0] = valid_s0_i | sel[0];
  assign grant[1] = valid_s1_i & ~sel[0] | sel[1];
  assign grant[2] = valid_s2_i & (~|sel[1:0]) | sel[2];
  assign grant[3] = valid_s3_i & (~|sel[2:0]) | sel[3];
  // assign grant[3] = 1'b0;
  assign grant[4] = valid_s4_i & (~|sel[3:0]) | sel[4];
  assign grant[5] = valid_sd_i & (~|sel[4:0]) | sel[5];

  always_comb begin
    if (grant[5]) slave = `AXI_DEFAULT_SLAVE;
    else if (grant[4]) slave = `AXI_SLAVE4;
    else if (grant[2]) slave = `AXI_SLAVE2;
    else if (grant[3]) slave = `AXI_SLAVE3;
    else if (grant[1]) slave = `AXI_SLAVE1;
    else if (grant[0]) slave = `AXI_SLAVE0;
    else slave = `AXI_SLAVE_BITS'h0;
  end

  // Master
  assign master = ids_s[`AXI_IDS_BITS-1:`AXI_ID_BITS];
  always_comb begin
    case (master)
      `AXI_MASTER0: ready_m = ready_m0_i;
      `AXI_MASTER1: ready_m = ready_m1_i;
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
  // valid
  assign {valid_m1_o, valid_m0_o} = validout;
  always_comb begin
    case (master)
      `AXI_MASTER0: validout = {1'b0, valid_s};
      `AXI_MASTER1: validout = {valid_s, 1'b0};
      default:      validout = 2'b0;
    endcase
  end
  // Slave
  // input
  always_comb begin
    case (slave)
      `AXI_SLAVE0: begin
        ids_s   = id_s0_i;
        data_s  = data_s0_i;
        resp_s  = resp_s0_i;
        last_s  = last_s0_i;
        valid_s = valid_s0_i;
      end
      `AXI_SLAVE1: begin
        ids_s   = id_s1_i;
        data_s  = data_s1_i;
        resp_s  = resp_s1_i;
        last_s  = last_s1_i;
        valid_s = valid_s1_i;
      end
      `AXI_SLAVE2: begin
        ids_s   = id_s2_i;
        data_s  = data_s2_i;
        resp_s  = resp_s2_i;
        last_s  = last_s2_i;
        valid_s = valid_s2_i;
      end
      `AXI_SLAVE3: begin
        ids_s   = id_s3_i;
        data_s  = data_s3_i;
        resp_s  = resp_s3_i;
        last_s  = last_s3_i;
        valid_s = valid_s3_i;
      end
      `AXI_SLAVE4: begin
        ids_s   = id_s4_i;
        data_s  = data_s4_i;
        resp_s  = resp_s4_i;
        last_s  = last_s4_i;
        valid_s = valid_s4_i;
      end
      `AXI_DEFAULT_SLAVE: begin
        ids_s   = id_sd_i;
        data_s  = data_sd_i;
        resp_s  = resp_sd_i;
        last_s  = last_sd_i;
        valid_s = valid_sd_i;
      end
      default: begin
        ids_s   = `AXI_IDS_BITS'b0;
        data_s  = `AXI_DATA_BITS'b0;
        resp_s  = 2'b0;
        last_s  = 1'b0;
        valid_s = 1'b0;
      end
    endcase
  end
  // output
  logic [5:0] readyout;

  assign {ready_sd_o, ready_s4_o, ready_s3_o, ready_s2_o, ready_s1_o, ready_s0_o} = readyout;
  always_comb begin
    case (slave)
      `AXI_SLAVE0:        readyout = {5'b0, ready_m & valid_s0_i};
      `AXI_SLAVE1:        readyout = {4'b0, ready_m & valid_s1_i, 1'b0};
      `AXI_SLAVE2:        readyout = {3'b0, ready_m & valid_s2_i, 2'b0};
      `AXI_SLAVE3:        readyout = {2'b0, ready_m & valid_s3_i, 3'b0};
      `AXI_SLAVE4:        readyout = {1'b0, ready_m & valid_s4_i, 4'b0};
      `AXI_DEFAULT_SLAVE: readyout = {ready_m & valid_sd_i, 5'b0};
      default:            readyout = 6'b0;
    endcase
  end

endmodule
