`include "../../include/CPU_def.svh"

module PLIC (
    input clk, rst,
    input                           ifid_en_i,
    input                           csr_wfi_i,
    input        [`INT_BITS   -1:0] interrupt_i,
    output logic                    int_taken_o,
    output logic [`INT_ID_BITS-1:0] int_id_o
);

    logic [`INT_BITS-1:0] interrupt_r;
    logic enb, valid;

    logic int_taken;
    assign int_taken = |interrupt_i;
    assign valid = enb && ~csr_wfi_i && int_taken;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)                            enb <= 1'b0;
        else if (|interrupt_r && ifid_en_i) enb <= 1'b0;
        else if (csr_wfi_i)                 enb <= 1'b1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)            interrupt_r <= `INT_BITS'h0;
        else if (ifid_en_i) interrupt_r <= `INT_BITS'h0;
        else if (valid)     interrupt_r <= interrupt_i;
    end

    assign int_taken_o = |interrupt_r;
    always_comb begin
        case(interrupt_r)
            `INT_BITS'b1   : int_id_o = `INT_DMA;
            `INT_BITS'b10  : int_id_o = `INT_SCTRL;
            `INT_BITS'b100 : int_id_o = `INT_EPU;
            default        : int_id_o = `INT_ID_BITS'h0;
        endcase
    end

endmodule









