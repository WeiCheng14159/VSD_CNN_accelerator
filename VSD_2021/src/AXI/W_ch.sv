`include "../../include/AXI_define.svh"

module W_ch (
    input                             clk,
    rst,
    // M1
    input        [`AXI_DATA_BITS-1:0] data_m1_i,
    input        [`AXI_STRB_BITS-1:0] strb_m1_i,
    input                             last_m1_i,
    input                             valid_m1_i,
    output logic                      ready_m1_o,
    // M2
    input        [`AXI_DATA_BITS-1:0] data_m2_i,
    input        [`AXI_STRB_BITS-1:0] strb_m2_i,
    input                             last_m2_i,
    input                             valid_m2_i,
    output logic                      ready_m2_o,
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
    // S5
    output logic [`AXI_DATA_BITS-1:0] data_s5_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s5_o,
    output logic                      last_s5_o,
    output logic                      valid_s5_o,
    input                             ready_s5_i,
    // S6
    output logic [`AXI_DATA_BITS-1:0] data_s6_o,
    output logic [`AXI_STRB_BITS-1:0] strb_s6_o,
    output logic                      last_s6_o,
    output logic                      valid_s6_o,
    input                             ready_s6_i,
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
    input awvalid_s5_i,
    input awvalid_s6_i,
    input awvalid_sd_i
);
  logic [`AXI_SLAVE_BITS-1:0] slave;
  logic free;
  logic [`AXI_DATA_BITS -1:0] data_m;
  logic [`AXI_STRB_BITS -1:0] strb_m;
  logic last_m, valid_m;
  logic [`AXI_MASTER_NUM-1:0] validin_m;
  logic ready_s;
  logic [`AXI_SLAVE_BITS-1:0] awvalidin_s, validout_s, wvalid_s;
  integer i;

  // {{{ Master
  // M0
  logic [`AXI_DATA_BITS-1:0] data_m0;
  logic [`AXI_STRB_BITS-1:0] strb_m0;
  logic last_m0, valid_m0, ready_m0;
  assign data_m0 = `AXI_DATA_BITS'h0;
  assign strb_m0 = `AXI_STRB_BITS'h0;
  assign last_m0 = 1'b0;
  assign valid_m0 = 1'b0;
  assign ready_m0 = 1'b0;

  // assign ready_m1_o = ready_s & valid_m1_i;
  // assign ready_m2_o = ready_s & valid_m2_i;
  assign ready_m1_o = ready_s;
  assign ready_m2_o = ready_s;
  assign validin_m = {valid_m2_i, valid_m1_i, valid_m0};
  always_comb begin
    case (validin_m)
      3'b001:
      {data_m, strb_m, last_m, valid_m} = {data_m0, strb_m0, last_m0, valid_m0};
      3'b010:
      {data_m, strb_m, last_m, valid_m} = {
        data_m1_i, strb_m1_i, last_m1_i, valid_m1_i
      };
      3'b100:
      {data_m, strb_m, last_m, valid_m} = {
        data_m2_i, strb_m2_i, last_m2_i, valid_m2_i
      };
      default:
      {data_m, strb_m, last_m, valid_m} = {
        `AXI_DATA_BITS'h0, `AXI_STRB_BITS'h0, 1'b0, 1'b0
      };
    endcase
  end
  // }}}
  // {{{ Slave
  assign awvalidin_s = {
    awvalid_sd_i,
    awvalid_s6_i,
    awvalid_s5_i,
    awvalid_s4_i,
    awvalid_s3_i,
    awvalid_s2_i,
    awvalid_s1_i,
    awvalid_s0_i
  };
  assign slave = wvalid_s | awvalidin_s;
  always_comb begin
    case (slave)
      `AXI_SLAVE0:        ready_s = ready_s0_i;
      `AXI_SLAVE1:        ready_s = ready_s1_i;
      `AXI_SLAVE2:        ready_s = ready_s2_i;
      `AXI_SLAVE3:        ready_s = ready_s3_i;
      `AXI_SLAVE4:        ready_s = ready_s4_i;
      `AXI_SLAVE5:        ready_s = ready_s5_i;
      `AXI_SLAVE6:        ready_s = ready_s6_i;
      `AXI_DEFAULT_SLAVE: ready_s = ready_sd_i;
      default:            ready_s = 1'b0;
    endcase
  end
  assign free = valid_m & ready_s & last_m;
  always_ff @(posedge clk or negedge rst) begin
    if (~rst) wvalid_s <= `AXI_SLAVE_BITS'b0;
    else begin
      for (i = 0; i < `AXI_SLAVE_BITS; i++)
        wvalid_s[i] <=  awvalidin_s[i] ? awvalidin_s[i] : free ? 1'b0 : wvalid_s[i];
    end
  end

  assign {valid_sd_o,
            valid_s6_o,
            valid_s5_o,
            valid_s4_o,
            valid_s3_o,
            valid_s2_o, 
            valid_s1_o, 
            valid_s0_o} = validout_s;
  assign validout_s = {`AXI_SLAVE_BITS{valid_m}} & slave;
  // S0
  assign data_s0_o = data_m;
  assign strb_s0_o = valid_s0_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s0_o = last_m;
  // S1
  assign data_s1_o = data_m;
  assign strb_s1_o = valid_s1_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s1_o = last_m;
  // S2
  assign data_s2_o = data_m;
  assign strb_s2_o = valid_s2_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s2_o = last_m;
  // S3
  assign data_s3_o = data_m;
  assign strb_s3_o = valid_s3_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s3_o = last_m;
  // S4
  assign data_s4_o = data_m;
  assign strb_s4_o = valid_s4_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s4_o = last_m;
  // S5
  assign data_s5_o = data_m;
  assign strb_s5_o = valid_s5_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s5_o = last_m;
  // S6
  assign data_s6_o = data_m;
  assign strb_s6_o = valid_s6_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_s6_o = last_m;
  // SD
  assign data_sd_o = data_m;
  assign strb_sd_o = valid_sd_o ? strb_m : `AXI_STRB_BITS'hf;
  assign last_sd_o = last_m;
  // }}}  
endmodule
