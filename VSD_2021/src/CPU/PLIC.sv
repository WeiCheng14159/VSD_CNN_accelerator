`include "../../include/CPU_def.svh"

module PLIC (
    input clk, rst,
    input        [`INT_BITS-1:0] interrupt_i,
    // output logic [`INT_BITS-1:0] cause_o,
    output logic                 int_taken_o,
    output logic                 int_id_o
);

    assign int_taken_o = |interrupt_i;
    always_comb begin
        case(interrupt_i)
            `INT_BITS'b1 : int_id_o = `INT_DMA;
            default      : int_id_o = `INT_ID_BITS'h0;
        endcase
    end

endmodule