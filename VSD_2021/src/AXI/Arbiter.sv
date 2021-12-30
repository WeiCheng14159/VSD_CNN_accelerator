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
    output logic                       ready_m1_o
);

  logic [`AXI_MASTER_BITS-1:0] master;
  logic lock0, lock1;
  logic grant0, grant1;
  always_ff @(posedge clk or negedge rst) begin
    if (~rst) begin
      lock0 <= 1'b0;
      lock1 <= 1'b0;
    end else begin
      lock0 <= (lock0 & readys_i) ? 1'b0 : (valid_m0_i & ~valid_m1_i & ~readys_i) ? 1'b1 : lock0;
      lock1 <= (lock1 & readys_i) ? 1'b0 : (~lock0     & valid_m1_i  & ~readys_i) ? 1'b1 : lock1;
    end
  end

  assign grant1 = (valid_m1_i & ~lock0) | lock1;
  assign grant0 = valid_m0_i | lock0;


  always_comb begin
    if (grant1) master = `AXI_MASTER1;
    else if (grant0) master = `AXI_MASTER0;
    else master = `AXI_MASTER_BITS'h0;
  end

  /*
	parameter IDLE  = 2'h0,
			  LOCK0 = 2'h1,
			  LOCK1 = 2'h2;
	logic [1:0] LOCK, NEXTLOCK;
    
	always_ff @(posedge clk or negedge rst) begin
		LOCK <= ~rst ? IDLE : NEXTLOCK;
	end
    always_comb begin
		case (LOCK)
			IDLE    : NEXTLOCK = valid_m1_i ? LOCK1 : (valid_m0_i ? LOCK0 : IDLE);
			LOCK0   : NEXTLOCK = readys_i ? IDLE : LOCK0;
			LOCK1   : NEXTLOCK = readys_i ? IDLE : LOCK1;
			default : NEXTLOCK = IDLE;
		endcase
	end
	always_comb begin
		case (LOCK)
			IDLE    : master = `AXI_MASTER_BITS'h0;
			LOCK0   : master = `AXI_MASTER0;
			default : master = `AXI_MASTER1;
		endcase
	end
*/
  always_comb begin
    case (master)
      `AXI_MASTER0: begin
        id_o       = {`AXI_MASTER0, id_m0_i};
        addr_o     = addr_m0_i;
        len_o      = len_m0_i;
        size_o     = size_m0_i;
        burst_o    = burst_m0_i;
        valid_o    = valid_m0_i;
        ready_m0_o = readys_i & valid_m0_i;
        ready_m1_o = 1'b0;
      end
      `AXI_MASTER1: begin
        id_o       = {`AXI_MASTER1, id_m1_i};
        addr_o     = addr_m1_i;
        len_o      = len_m1_i;
        size_o     = size_m1_i;
        burst_o    = burst_m1_i;
        valid_o    = valid_m1_i;
        ready_m0_o = 1'b0;
        ready_m1_o = readys_i & valid_m1_i;
      end
      default: begin
        id_o       = {`AXI_DEFAULT_MASTER, `AXI_ID_BITS'b0};
        addr_o     = `AXI_ADDR_BITS'h0;
        len_o      = `AXI_LEN_BITS'h0;
        size_o     = `AXI_SIZE_BITS'h0;
        burst_o    = `AXI_BURST_BITS'h0;
        valid_o    = 1'b0;
        ready_m0_o = 1'b0;
        ready_m1_o = 1'b0;
      end
    endcase
  end

endmodule

`endif
