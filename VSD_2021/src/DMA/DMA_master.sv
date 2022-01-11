`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "../FIFO.sv"

parameter FIFO_DEPTH = 2;
parameter IDLE  = 3'h0,
          CHECK = 3'h1,
          AR_CH = 3'h2,  // send address to source
          AW_CH = 3'h3,  // send address to destination
          BUSY  = 3'h4, B_CH = 3'h5, FIN = 3'h6;

module DMA_master (
    input clk, rst,
    inf_Master.M2AXIin          m2axi_i,
    inf_Master.M2AXIout         m2axi_o,
    input                       dma_en_i,
    input  [`AXI_ADDR_BITS-1:0] src_addr_i,
    input  [`AXI_ADDR_BITS-1:0] dst_addr_i,
    input  [`DATA_BITS    -1:0] data_qty_i,
    output                      dma_fin_o
);
    
    logic [2:0] STATE, NEXT;    
    // Handshake
    logic arhns, awhns, rhns, whns, bhns;
    logic rdfin, wrfin;
    // FIFO
    logic [`DATA_BITS-1:0] fifo_datain, fifo_dataout;
    logic fifo_wen, fifo_ren, fifo_empty, fifo_full;
    logic [FIFO_DEPTH-1:0] fifo_cnt_r;
    // DMA
    logic [`AXI_LEN_BITS-1:0] op_qty_r;   // send to AXI
    logic [`DATA_BITS   -1:0] rem_qty_r;  // remainder of quantity
    logic done;  // rem_qty_r == 0
    // AXI
    logic [`ADDR_BITS-1:0] src_addr_r;  // araddr
    logic [`ADDR_BITS-1:0] dst_addr_r;  // awaddr
    
    // Handshake
    assign awhns = m2axi_i.awready & m2axi_o.awvalid;
    assign whns  = m2axi_i.wready  & m2axi_o.wvalid;
    assign bhns  = m2axi_o.bready  & m2axi_i.bvalid;
    assign arhns = m2axi_i.arready & m2axi_o.arvalid;
    assign rhns  = m2axi_o.rready  & m2axi_i.rvalid;
    assign rdfin = rhns & m2axi_i.rlast;
    assign wrfin = whns & m2axi_o.wlast;
    // DMA
    assign done = (~|rem_qty_r) && (STATE == B_CH);
    assign dma_fin_o = STATE == FIN;  // interrupt


// {{{ STATE
    logic start;

    always_ff @(posedge clk or posedge rst) begin
        start <= rst ? 1'b0 : dma_en_i;
    end
    always_ff @(posedge clk or posedge rst) begin
        STATE <= rst ? IDLE : NEXT;
    end
    always_comb begin
        case (STATE)
            IDLE    : NEXT = start       ? CHECK : IDLE;
            CHECK   : NEXT = |rem_qty_r  ? AR_CH : FIN;
            AR_CH   : NEXT = arhns       ? AW_CH : AR_CH;
            AW_CH   : NEXT = awhns       ? BUSY  : AW_CH;
            BUSY    : NEXT = wrfin       ? B_CH  : BUSY;
            B_CH    : NEXT = ~|rem_qty_r ? FIN   : AR_CH;
            FIN     : NEXT = IDLE;
            default : NEXT = STATE;
        endcase
    end
// }}}
// {{{
    always_ff @(posedge clk or posedge rst) begin
        if (rst)           rem_qty_r <= `DATA_BITS'h0;
        else if (dma_en_i) rem_qty_r <= data_qty_i;
        else if (wrfin)    rem_qty_r <= rem_qty_r - op_qty_r;
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst)                op_qty_r <= `AXI_LEN_BITS'h0;
        else if (dma_en_i)      op_qty_r <= data_qty_i < `DATA_BITS'hff ? data_qty_i[`AXI_LEN_BITS-1:0] : `AXI_LEN_BITS'hff;
        else if (STATE == B_CH) op_qty_r <= rem_qty_r  < `DATA_BITS'hff ? rem_qty_r[`AXI_LEN_BITS-1:0]    : `AXI_LEN_BITS'hff;   
    end
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            src_addr_r <= `ADDR_BITS'h0;
            dst_addr_r <= `ADDR_BITS'h0;
        end
        else if (dma_en_i) begin
            src_addr_r <= src_addr_i;
            dst_addr_r <= dst_addr_i;
        end
        else if ((STATE == B_CH) && ~done) begin
            src_addr_r <= src_addr_r + `ADDR_BITS'h400;
            dst_addr_r <= dst_addr_r + `ADDR_BITS'h400;
        end
    end


// }}}
// {{{ AXI
    assign m2axi_o.arid    = `AXI_DMA_ID;
    assign m2axi_o.araddr  = src_addr_r;
    assign m2axi_o.arlen   = op_qty_r;//data_qty_i[`AXI_LEN_BITS-1:0];
    assign m2axi_o.arsize  = `AXI_SIZE_WORD;
    assign m2axi_o.arburst = `AXI_BURST_FIXED;
    assign m2axi_o.awid    = `AXI_DMA_ID;
    assign m2axi_o.awaddr  = dst_addr_r;
    assign m2axi_o.awlen   = op_qty_r;//data_qty_i[`AXI_LEN_BITS-1:0];
    assign m2axi_o.awburst = `AXI_BURST_FIXED;
    assign m2axi_o.wstrb   = `AXI_STRB_WORD;
    assign m2axi_o.wdata   = fifo_dataout;
    assign m2axi_o.wlast   = &fifo_cnt_r;
    always_comb begin
        {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
        {m2axi_o.rready, m2axi_o.bready} = 2'b0;
        case (STATE)
            IDLE  : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
                {m2axi_o.rready, m2axi_o.bready} = 2'b0;
            end
            CHECK : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
                {m2axi_o.rready, m2axi_o.bready} = 2'b0;                
            end
            AR_CH : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b100;
                {m2axi_o.rready, m2axi_o.bready} = 2'b0;        
            end
            AW_CH : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b010;
                {m2axi_o.rready, m2axi_o.bready} = 2'b0;          
            end            
            BUSY  : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = {2'b0, fifo_ren};
                {m2axi_o.rready, m2axi_o.bready} = {~fifo_full, 1'b0}; 
            end
            B_CH  : begin
                {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
                {m2axi_o.rready, m2axi_o.bready} = 2'b1;
            end
        endcase
    end
// }}}
// {{{ FIFO (2)
    assign fifo_datain = m2axi_i.rdata;
    assign fifo_wen = (STATE == BUSY) & rhns;
    assign fifo_ren = (STATE == BUSY) & fifo_full | (|fifo_cnt_r);
    always_ff @(posedge clk or posedge rst) begin
        if (rst)              fifo_cnt_r <= {FIFO_DEPTH{1'b0}};
        else if (rdfin)       fifo_cnt_r <= {{(FIFO_DEPTH-1){1'b0}}, 1'b1};
        else if (|fifo_cnt_r) fifo_cnt_r <= fifo_cnt_r + {{(FIFO_DEPTH-1){1'b0}}, 1'b1};
    end
    FIFO #(.FIFO_DEPTH(FIFO_DEPTH)) i_fifo (
        .clk     (clk         ),
        .rst     (rst         ),
        .wen_i   (fifo_wen    ),
        .ren_i   (fifo_ren    ),
        .data_i  (fifo_datain ),
        .data_o  (fifo_dataout),
        .empty_o (fifo_empty  ),
        .full_o  (fifo_full   )
    );
// }}}

    // always_ff @(posedge clk) begin
    //     if (wrfin)
    //         $display("==================================================");
    //     if (whns)
    //         $display("%h", fifo_dataout);
    // end
    // always_comb begin
    //     if (dma_en_i)
    //         $display("src: %h, dst: %h\n--------------------------------------------------", src_addr_i, dst_addr_i);
        
    // end


endmodule
