`include "../../include/CPU_def.svh"
module PLIC (
    input                           clk,
    rst,
    input                           ifid_en_i,
    input                           csr_wfi_i,
    input                           csr_mret_i,
    input        [`ADDR_BITS  -1:0] csr_retpc_i,
    input        [`INT_BITS   -1:0] interrupt_i,
    output logic                    int_taken_o,
    output logic [`INT_ID_BITS-1:0] int_id_o,
    output logic [`ADDR_BITS  -1:0] mretpc_o
);

  /**************************************
*  3   | 2     | 1       | 0          *
*  EPU | SCtrl | DMA_fin | DMA_notify *
**************************************/

  logic [`INT_BITS-2:0] interrupt_r;
  logic [`INT_BITS-2:0] int_filter;
  logic enb, valid, lock_dma;

  assign int_filter = lock_dma ? {2'b0, interrupt_i[1]} : interrupt_i[`INT_BITS-1:1];

  always_ff @(posedge clk or posedge rst) begin
    if (rst) lock_dma <= 1'b0;
    else if (interrupt_r[0] && ifid_en_i) lock_dma <= 1'b0;
    else if (interrupt_i[0]) lock_dma <= 1'b1;
  end

  logic int_taken;
  assign int_taken = |int_filter;
  assign valid = enb && ~csr_wfi_i && int_taken;
  assign mretpc_o = csr_retpc_i;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) enb <= 1'b0;
    else if (|interrupt_r && ifid_en_i) enb <= 1'b0;
    else if (csr_wfi_i) enb <= 1'b1;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) interrupt_r <= 0;
    else if (ifid_en_i) interrupt_r <= 0;
    else if (valid) interrupt_r <= int_filter;
  end

  assign int_taken_o = |interrupt_r;
  always_comb begin
    case (interrupt_r)
      `INT_BITS'b1:   int_id_o = `INT_DMA;
      `INT_BITS'b10:  int_id_o = `INT_SCTRL;
      `INT_BITS'b100: int_id_o = `INT_EPU;
      default:        int_id_o = `INT_ID_BITS'h0;
    endcase
  end

endmodule
