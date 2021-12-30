`include "../../include/AXI_define.svh"

module W_ch (
    input                             clk,
    rst,
    input        [`AXI_DATA_BITS-1:0] data_m1_i,
    input        [`AXI_STRB_BITS-1:0] strb_m1_i,
    input                             last_m1_i,
    input                             valid_m1_i,
    output logic                      ready_m1_o,
    // S0
    output logic [`AXI_DATA_BITS-1:0] data_s0_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s0_o,
    output logic                      last_s0_o,
    output logic                      valid_s0_o,
    input                             ready_s0_i,
    // S1
    output logic [`AXI_DATA_BITS-1:0] data_s1_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s1_o,
    output logic                      last_s1_o,
    output logic                      valid_s1_o,
    input                             ready_s1_i,
    // S2
    output logic [`AXI_DATA_BITS-1:0] data_s2_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s2_o,
    output logic                      last_s2_o,
    output logic                      valid_s2_o,
    input                             ready_s2_i,
    // S3
    output logic [`AXI_DATA_BITS-1:0] data_s3_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s3_o,
    output logic                      last_s3_o,
    output logic                      valid_s3_o,
    input                             ready_s3_i,
    // S4
    output logic [`AXI_DATA_BITS-1:0] data_s4_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s4_o,
    output logic                      last_s4_o,
    output logic                      valid_s4_o,
    input                             ready_s4_i,
    // SD
    output logic [`AXI_DATA_BITS-1:0] data_sd_o,
    output logic [`AXI_STRB_BITS-1:0] strb_sd_o,
    output logic                      last_sd_o,
    output logic                      valid_sd_o,
    input                             ready_sd_i,

    input awvalid_s0_i,
    input awvalid_s1_i,
    input awvalid_s2_i,
    input awvalid_s3_i,
    input awvalid_s4_i,
    input awvalid_sd_i
);
  // S
  logic [`AXI_SLAVE_BITS-1:0] slave;
  logic [5:0] wvalid_s;
  logic free;
  // M
  logic [`AXI_DATA_BITS -1:0] data_m;
  logic [`AXI_STRB_BITS -1:0] strb_m;
  logic last_m;
  logic valid_m;
  logic ready_s;

  // Master
  // M1
  assign data_m = data_m1_i;
  assign strb_m = strb_m1_i;
  assign last_m = last_m1_i;
  assign valid_m = valid_m1_i;
  assign ready_m1_o = ready_s & valid_m1_i;
  // Slave
  assign free = valid_m & ready_s & last_m;
  assign slave[0] = wvalid_s[0] | awvalid_s0_i;
  assign slave[1] = wvalid_s[1] | awvalid_s1_i;
  assign slave[2] = wvalid_s[2] | awvalid_s2_i;
  assign slave[3] = wvalid_s[3] | awvalid_s3_i;
  // assign slave[3] = 1'b0;
  assign slave[4] = wvalid_s[4] | awvalid_s4_i;
  assign slave[5] = wvalid_s[5] | awvalid_sd_i;

  always_comb begin
    case (slave)
      `AXI_SLAVE0:        ready_s = ready_s0_i;
      `AXI_SLAVE1:        ready_s = ready_s1_i;
      `AXI_SLAVE2:        ready_s = ready_s2_i;
      `AXI_SLAVE3:        ready_s = ready_s3_i;
      `AXI_SLAVE4:        ready_s = ready_s4_i;
      `AXI_DEFAULT_SLAVE: ready_s = ready_sd_i;
      default:            ready_s = 1'b1;
    endcase
  end

  always_ff @(posedge clk or negedge rst) begin
    if (~rst) begin
      wvalid_s <= 6'b0;
    end else begin
      wvalid_s[0] <= awvalid_s0_i ? awvalid_s0_i : free ? 1'b0 : wvalid_s[0];
      wvalid_s[1] <= awvalid_s1_i ? awvalid_s1_i : free ? 1'b0 : wvalid_s[1];
      wvalid_s[2] <= awvalid_s2_i ? awvalid_s2_i : free ? 1'b0 : wvalid_s[2];
      wvalid_s[3] <= awvalid_s3_i ? awvalid_s3_i : free ? 1'b0 : wvalid_s[3];
      wvalid_s[4] <= awvalid_s4_i ? awvalid_s4_i : free ? 1'b0 : wvalid_s[4];
      wvalid_s[5] <= awvalid_sd_i ? awvalid_sd_i : free ? 1'b0 : wvalid_s[5];
    end
  end
  logic [5:0] validout;
  // logic valid_s3_o;
  assign {valid_sd_o, valid_s4_o, valid_s3_o, valid_s2_o, valid_s1_o, valid_s0_o} = validout;
  always_comb begin
    case (slave)
      `AXI_SLAVE0:        validout = {5'b0, valid_m};
      `AXI_SLAVE1:        validout = {4'b0, valid_m, 1'b0};
      `AXI_SLAVE2:        validout = {3'b0, valid_m, 2'b0};
      `AXI_SLAVE3:        validout = {2'b0, valid_m, 3'b0};
      `AXI_SLAVE4:        validout = {1'b0, valid_m, 4'b0};
      `AXI_DEFAULT_SLAVE: validout = {valid_m, 5'b0};
      default:            validout = 6'b0;
    endcase
  end
  // S0
  assign data_s0_o = data_m;
  assign strb_s0_o = (valid_s0_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s0_o = last_m;
  // S1
  assign data_s1_o = data_m;
  assign strb_s1_o = (valid_s1_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s1_o = last_m;
  // S2
  assign data_s2_o = data_m;
  assign strb_s2_o = (valid_s2_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s2_o = last_m;
  // S3
  assign data_s3_o = data_m;
  assign strb_s3_o = (valid_s3_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s3_o = last_m;
  // S4
  assign data_s4_o = data_m;
  assign strb_s4_o = (valid_s4_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s4_o = last_m;
  // SD
  assign data_sd_o = data_m;
  assign strb_sd_o = (valid_sd_o) ? strb_m : `AXI_STRB_BITS'hf;
  assign last_sd_o = last_m;
endmodule
