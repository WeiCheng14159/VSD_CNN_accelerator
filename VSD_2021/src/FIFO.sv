`ifnder __FIFO__
`define __FIFO__
`inculde "../include/CPU_def.svh"

module FIFO #(
    paramter FIFO_DEPTH = 4;
)(
    input  clk, rst,
    input  wen_i,  // write enable
    input  ren_i,  // read enable
    input  [`DATA_BITS-1:0] data_i,
    output [`DATA_BITS-1:0] data_o
);

    logic [`DATA_BITS-1:0] mem [(2**FIFO_DEPTH)-1:0];
    logic [FIFO_DEPTH-1:0] rptr, wptr, wptr_;
    logic full, empty;
    integer i;

    assign data_o = mem[rptr];
    assign full   = wptr_ == rptr;
    assign empty  = wptr  == rptr;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            for (i = 0; i < 2**FIFO_DEPTH; i = i + 1)
                mem[i] <= `DATA_BITS'h0;
        else if (wen_i & ~full)
            mem[wptr] <= data_i;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wptr  <= {FIFO_DEPTH{1'b0}};
            wprt_ <= {{(FIFO_DEPTH-1){1'b0}}, 1'b1}
            rptr  <= {FIFO_DEPTH{1'b0}};
        end
        else begin
            wptr  <= wptr  + {{(FIFO_DEPTH-1){1'b0}}, ~empty & wen_i};
            wptr_ <= wptr_ + {{(FIFO_DEPTH-1){1'b0}}, ~empty & wen_i};
            rptr  <= rptr  + {{(FIFO_DEPTH-1){1'b0}}, ~full & ren_i};
        end
    end

endmodule
`endif
