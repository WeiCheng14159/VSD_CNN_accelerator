`include "../../include/CPU_def.svh"

module PLIC (
    input clk, rst,
    input        [`INT_BITS   -1:0] interrupt_i,
    output logic                    int_taken_o,
    output logic [`INT_ID_BITS-1:0] int_id_o
);

    assign int_taken_o = |interrupt_i;
    always_comb begin
        case(interrupt_i)
            `INT_BITS'b1   : int_id_o = `INT_DMA;
            `INT_BITS'b10  : int_id_o = `INT_SCTRL;
            `INT_BITS'b100 : int_id_o = `INT_EPU;
            default        : int_id_o = `INT_ID_BITS'h0;
        endcase
    end

endmodule