`include "../include/CPU_def.svh"
`include "./Interface/inf_Slave.sv"
`include "./FIFO.sv"
localparam DRAM_ADDR = 11;

module DRAM_wrapper (
    input clk, rst,
    inf_Slave.S2AXIin  s2axi_i,
    inf_Slave.S2AXIout s2axi_o,
    input        [`DATA_BITS-1:0] DRAM_Q_i,
    input                         DRAM_valid_i,
    output logic                  DRAM_CSn_o,
    output logic [`WEB_BITS -1:0] DRAM_WEn_o,
    output logic                  DRAM_RASn_o,
    output logic                  DRAM_CASn_o,
    output logic [          10:0] DRAM_A_o,
    output logic [`DATA_BITS-1:0] DRAM_D_o
);
	
    localparam FIFO_DEPTH = 6;
    localparam IDLE     = 3'h0,
               SETROW   = 3'h1,
               READCOL  = 3'h2,
               WRITECOL = 3'h3,
               SAMEROW  = 3'h4,
               PRECHG   = 3'h5,
               DONE     = 3'h6;
    logic [2:0] STATE, NEXT;
    // Handshake
    logic arhns, rhns, awhns, whns, bhns;
    logic ahns;  // arhns, awhns
    logic rdfin, wrfin;
    // Sample
    logic [21:0] addr;
    logic [`AXI_IDS_BITS  -1:0] ids;
    logic [`AXI_BURST_BITS-1:0] burst;
    logic [`AXI_LEN_BITS  -1:0] len_r;
    logic [`AXI_SIZE_BITS -1:0] size;
    logic [`AXI_STRB_BITS -1:0] wstrb;
    logic [`AXI_DATA_BITS -1:0] wdata_r;
    // DRAM
    logic [1:0] byte_off;
    logic [`WEB_BITS   -1:0] bwen, hwen, dramwen;
    logic [`DATA_BITS  -1:0] dramdata_r;
    logic [`DATA_BITS  -1:0] dramdataD_r;
    // logic [`DRAM_A_BITS-1:0] row, col, col_r;
    logic [`DRAM_A_BITS-1:0] col_r;
    logic [ 1:0] off;
    logic dramvalid_r;
    // Counter
    logic flag;
    logic [2:0] dcnt;  // wait 5 cycle
    logic [`AXI_LEN_BITS-1:0] rcnt;   // cnt for read
    // Other
    logic write;
    logic clear;  // clear write
    // FIFO
    logic [`DATA_BITS-1:0] fifo_datain, fifo_dataout;
    logic fifo_wen, fifo_ren, fifo_empty, fifo_full;
    logic [FIFO_DEPTH-1:0] fifo_cnt_r;

// {{{ Handshake
    assign arhns = s2axi_i.arvalid & s2axi_o.arready;
    assign rhns  = s2axi_o.rvalid  & s2axi_i.rready;
    assign awhns = s2axi_i.awvalid & s2axi_o.awready; 
    assign whns  = s2axi_i.wvalid  & s2axi_o.wready;
    assign bhns  = s2axi_o.bvalid  & s2axi_i.bready;
    assign ahns  = arhns | awhns;
    assign rdfin = s2axi_o.rlast & rhns;
    assign wrfin = s2axi_i.wlast & whns;
    // always_ff @(posedge clk or negedge rst) begin
    //     if (~rst)         latch_wrfin <= 1'b0;
    //     else if (dcnt[2]) latch_wrfin <= 1'b0;
    //     else if (wrfin)   latch_wrfin <= 1'b1;
    // end
// }}}
    
// {{{ Sample
    assign clear = ((STATE == READCOL) | (STATE == WRITECOL)) & dcnt[2];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            addr      <= 21'h0;
            ids       <= `AXI_IDS_BITS'h0;
            burst     <= `AXI_BURST_BITS'h0;
            len_r     <= `AXI_LEN_BITS'h0;
            size      <= `AXI_SIZE_BITS'h0;
            wstrb     <= `AXI_STRB_BITS'h0;
            wdata_r   <= `DATA_BITS'h0;
            write     <= 1'b0;
            dramvalid_r <= 1'b0;
            dramdata_r  <= `DATA_BITS'h0;
            dramdataD_r <= `DATA_BITS'h0;
        end
        else begin
            addr      <= arhns ? s2axi_i.araddr[22:2] : awhns ? s2axi_i.awaddr[22:2] : addr;
            byte_off  <= arhns ? s2axi_i.araddr[ 1:0] : awhns ? s2axi_i.awaddr[ 1:0] : byte_off;
            ids       <= arhns ? s2axi_i.arid    : awhns ? s2axi_i.awid    : ids;
            burst     <= arhns ? s2axi_i.arburst : awhns ? s2axi_i.awburst : burst;
            len_r     <= arhns ? s2axi_i.arlen   : awhns ? s2axi_i.awlen   : len_r;
            size      <= arhns ? s2axi_i.arsize  : awhns ? s2axi_i.awsize  : size;
            wstrb     <= awhns ? s2axi_i.wstrb   : wstrb;
            // wdata     <= awhns ? s2axi_i.wdata   : wdata;
            wdata_r   <= s2axi_i.wvalid ? s2axi_i.wdata : wdata_r;
            write     <= clear ? 1'b0 : (awhns ? 1'b1 : write);
            dramvalid_r <= DRAM_valid_i;
            dramdata_r  <= DRAM_valid_i ? DRAM_Q_i : dramdata_r; 
            // dramdataD_r <= (STATE == SETROW) ? s2axi_i.wdata : dramdataD_r;
        end
    end
// }}}
// {{{ Counter, flag
    assign flag = (STATE == READCOL) ? dramvalid_r : dcnt[2];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            dcnt <= 3'h0;
            rcnt <= `AXI_LEN_BITS'h0;
        end
        else begin
            case (STATE)
                IDLE     : begin
                    dcnt <= 3'h0;
                    rcnt <= `AXI_LEN_BITS'h0;
                end
                SETROW   : begin
                    dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <= `AXI_LEN_BITS'h0;
                end
                READCOL  : begin
                    dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? (rcnt + `AXI_LEN_BITS'h1): rcnt;
                end
                WRITECOL : begin
                    dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <= `AXI_LEN_BITS'h0;
                end
                PRECHG   : begin
                    dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <= `AXI_LEN_BITS'h0;
                end
            endcase
        end
    end
// }}}

// {{{ STATE
    always_ff @(posedge clk or negedge rst) begin
        STATE <= ~rst ? IDLE : NEXT;
    end
    always_comb begin  // flag = dcnt == 3'h4
        case (STATE)
            IDLE     : NEXT = ahns ? SETROW : IDLE;
            SETROW   : NEXT = flag ? (write ? WRITECOL : READCOL) : SETROW;
            SETROW   : begin
                case ({flag, write})
                    2'b10   : NEXT = READCOL;
                    2'b11   : NEXT = WRITECOL;
                    default : NEXT = SETROW;
                endcase
            end
            READCOL  : NEXT = flag & rdfin ? PRECHG : READCOL;
            // WRITECOL : NEXT = flag         ? PRECHG : WRITECOL;
            WRITECOL : NEXT = flag & wrfin ? PRECHG : WRITECOL; 
            PRECHG   : NEXT = flag         ? IDLE : PRECHG;
            default  : NEXT = STATE;
        endcase
    end
// }}}
// {{{ DRAM 
    // assign row = addr[20:10];
    // assign col = {1'b0, addr[9:0]};
    // assign off = rcnt[1:0];

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)             col_r <= `DRAM_A_BITS'h0;
        else if (arhns)       col_r <= s2axi_i.araddr[11:2];
        else if (awhns)       col_r <= s2axi_i.awaddr[11:2];
        else if (rhns | whns) col_r <= col_r + `DRAM_A_BITS'h1;
    end

    // DRAM_WEn
    always_comb begin
        case (byte_off)
            2'h0 : {bwen, hwen} = {4'b1110, 4'b1100};
            2'h1 : {bwen, hwen} = {4'b1101, 4'b1001};
            2'h2 : {bwen, hwen} = {4'b1011, 4'b0011};
            2'h3 : {bwen, hwen} = {4'b0111, 4'b0111};
        endcase
    end
    always_comb begin
        case (wstrb)
            `AXI_STRB_HWORD : dramwen = hwen;
            `AXI_STRB_BYTE  : dramwen = bwen;
            default         : dramwen = 4'h0; 
        endcase
    end

    always_comb begin
        case (STATE)
            IDLE     : begin
                DRAM_A_o    = `ADDR_BITS'h0;
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b1;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = 4'hf;
            end
            SETROW   : begin
                DRAM_A_o    = addr[20:10]; 
                DRAM_D_o    = s2axi_i.wdata;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = 4'hf;
            end
            READCOL  : begin
                DRAM_A_o    = col_r;
                DRAM_D_o    = s2axi_i.wdata;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = 4'hf;
            end
            WRITECOL : begin
                DRAM_A_o    = col_r;
                DRAM_D_o    = wdata_r;//s2axi_i.wdata;//dramdataD_r;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = ~|dcnt ? dramwen : 4'hf;
            end
            PRECHG   : begin
                DRAM_A_o    = addr[20:10]; 
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = ~|dcnt ? 4'h0 : 4'hf;
            end
            default  : begin
                DRAM_A_o    = 11'h0;
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b1;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = 4'hf;
            end
        endcase
    end
// }}}
// {{{ AXI
    assign s2axi_o.rid   = ids;
    assign s2axi_o.rdata = dramdata_r;
    assign s2axi_o.rresp = `AXI_RESP_OKAY;
    assign s2axi_o.rlast = rcnt == len_r;
    assign s2axi_o.bid   = ids;
    assign s2axi_o.bresp = `AXI_RESP_OKAY;
    logic [2:0] readyout;
    logic [1:0] validout;
    assign {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = readyout;
    assign {s2axi_o.rvalid, s2axi_o.bvalid} = validout;
    always_comb begin
        case (STATE)
            IDLE     : readyout = {~s2axi_i.awvalid, 2'b10};
            WRITECOL : readyout = {2'b0, flag};
            // WRITECOL : readyout = 3'b1;
            default  : readyout = 3'b0;  // SETROW, READCOL, PRECHG
        endcase
    end
    always_comb begin
        case (STATE)
            READCOL  : validout = {dramvalid_r, 1'b0};
            PRECHG   : validout = {1'b0, ~|dcnt};
            default  : validout = 2'b0;  // IDLE, SETROW, WRITECOL
        endcase
    end
// }}}

// {{{

// }}}





// {{{ FIFO
    logic [2:0] wen_valid;
    logic wen_enb;
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)                 wen_enb <= 1'b0;
        // else if (wrfin)           wen_enb <= 1'b0;
        else if (&wen_valid[2:1]) wen_enb <= 1'b1;
    end
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)              wen_valid <= 3'h0;
        // else if (wrfin)        wen_valid <= 3'h0;
        else if (awhns)        wen_valid <= 3'h4;
        else if (wen_valid[2]) wen_valid[1:0] <= wen_valid[1:0] + 2'h1;
    end

    assign fifo_datain = s2axi_i.wdata;
    assign fifo_wen = wen_enb && wen_valid[0];//(STATE == SETROW || STATE == WRITECOL) && ~fifo_full;
    assign fifo_ren = (STATE == WRITECOL) && flag;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)              fifo_cnt_r <= {FIFO_DEPTH{1'b0}};
        else if (rdfin)       fifo_cnt_r <= {{(FIFO_DEPTH-1){1'b0}}, 1'b1};
        else if (|fifo_cnt_r) fifo_cnt_r <= fifo_cnt_r + {{(FIFO_DEPTH-1){1'b0}}, 1'b1};
    end
    FIFO #(.FIFO_DEPTH(FIFO_DEPTH)) i_fifo (
        .clk     (clk         ),
        .rst     (~rst        ),
        .clr_i   (1'b0),
        .wen_i   (fifo_wen    ),
        .ren_i   (fifo_ren    ),
        .data_i  (fifo_datain ),
        .data_o  (fifo_dataout),
        .empty_o (fifo_empty  ),
        .full_o  (fifo_full   )
    );
// }}}


endmodule
