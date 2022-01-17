`include "../../include/CPU_def.svh"

module PLIC (
    input clk, rst,
    input        [`INT_BITS   -1:0] interrupt_i,
    output logic                    int_taken_o,
    output logic [`INT_ID_BITS-1:0] int_id_o
);

    assign int_taken_o = |interrupt_i;
    always_comb begin
        if (interrupt_i[0])      int_id_o = `INT_DMA;
        else if (interrupt_i[1]) int_id_o = `INT_SCTRL;
        else if (interrupt_i[2]) int_id_o = `INT_EPU;
        else                     int_id_o = `INT_ID_BITS'h0;
    end

endmodule