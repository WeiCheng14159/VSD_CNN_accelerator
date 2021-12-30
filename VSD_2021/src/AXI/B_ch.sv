`include "../../include/AXI_define.svh"

module B_ch (
    input                             clk,
    rst,
    output       [`AXI_ID_BITS  -1:0] id_m1_o,
    output       [`AXI_RESP_BITS-1:0] resp_m1_o,
    output logic                      valid_m1_o,
    input                             ready_m1_i,
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
    // SD
    input        [`AXI_IDS_BITS -1:0] ids_sd_i,
    input        [`AXI_RESP_BITS-1:0] resp_sd_i,
    input                             valid_sd_i,
    output logic                      ready_sd_o
);
  // M
  logic [`AXI_MASTER_BITS-1:0] master;
  logic ready_m;
  // S
  logic [`AXI_SLAVE_BITS -1:0] slave;
  logic [`AXI_IDS_BITS   -1:0] ids_s;
  logic [`AXI_RESP_BITS  -1:0] resp_s;
  logic valid_s;



  // Master
  always_comb begin
    case (master)
      `AXI_MASTER1: ready_m = ready_m1_i;
      default:      ready_m = 1'b1;
    endcase
  end
  // M1
  assign id_m1_o   = ids_s[`AXI_ID_BITS-1:0];
  assign resp_m1_o = resp_s;
  assign master    = ids_s[`AXI_IDS_BITS-1:`AXI_ID_BITS];
  always_comb begin
    case (master)
      `AXI_MASTER1: valid_m1_o = valid_s;
      default:      valid_m1_o = 1'b0;
    endcase
  end
  // Slave
  logic [5:0] validin;
  assign validin = {
    valid_sd_i, valid_s4_i, valid_s3_i, valid_s2_i, valid_s1_i, valid_s0_i
  };
  // assign validin = {valid_sd_i, valid_s4_i, 1'b0, valid_s2_i, valid_s1_i, valid_s0_i};
  always_comb begin
    case (validin)
      6'b100000: slave = `AXI_DEFAULT_SLAVE;
      6'b010000: slave = `AXI_SLAVE4;
      6'b001000: slave = `AXI_SLAVE3;
      6'b000100: slave = `AXI_SLAVE2;
      6'b000010: slave = `AXI_SLAVE1;
      6'b000001: slave = `AXI_SLAVE0;
      default:   slave = `AXI_DEFAULT_SLAVE;
    endcase
  end
  always_comb begin
    case (slave)
      `AXI_SLAVE0: begin
        ids_s   = ids_s0_i;
        resp_s  = resp_s0_i;
        valid_s = valid_s0_i;
      end
      `AXI_SLAVE1: begin
        ids_s   = ids_s1_i;
        resp_s  = resp_s1_i;
        valid_s = valid_s1_i;
      end
      `AXI_SLAVE2: begin
        ids_s   = ids_s2_i;
        resp_s  = resp_s2_i;
        valid_s = valid_s2_i;
      end
      `AXI_SLAVE3: begin
        ids_s   = ids_s3_i;
        resp_s  = resp_s3_i;
        valid_s = valid_s3_i;
      end
      `AXI_SLAVE4: begin
        ids_s   = ids_s4_i;
        resp_s  = resp_s4_i;
        valid_s = valid_s4_i;
      end
      `AXI_DEFAULT_SLAVE: begin
        ids_s   = ids_sd_i;
        resp_s  = resp_sd_i;
        valid_s = valid_sd_i;
      end
      default: begin
        ids_s   = `AXI_IDS_BITS'h0;
        resp_s  = 1'b0;
        valid_s = 1'b0;
      end
    endcase
  end
  logic [5:0] readyout;
  // logic ready_s3_o;
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
