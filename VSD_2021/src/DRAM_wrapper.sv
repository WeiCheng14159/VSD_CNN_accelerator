`include "../include/CPU_def.svh"
`include "./Interface/inf_Slave.sv"
`include "./FIFO.sv"
localparam DRAM_ADDR = 11;

module DRAM_wrapper (
    input                         clk, rst,
    inf_Slave.S2AXIin             s2axi_i,
    inf_Slave.S2AXIout            s2axi_o,
    input        [`DATA_BITS-1:0] DRAM_Q_i,
    input                         DRAM_valid_i,
    output logic                  DRAM_CSn_o,
    output logic [`WEB_BITS -1:0] DRAM_WEn_o,
    output logic                  DRAM_RASn_o,
    output logic                  DRAM_CASn_o,
    output logic [          10:0] DRAM_A_o,
    output logic [`DATA_BITS-1:0] DRAM_D_o
);
    localparam FIFO_DEPTH = 2;
    localparam IDLE     = 3'h0,
               SETROW   = 3'h1,
               READCOL  = 3'h2,
               WRITECOL = 3'h3,
               CHKROW   = 3'h4,  // check wheather the row is same or not
               CHANGE   = 3'h5, PRECHG = 3'h6, DONE = 3'h7;
    logic [2:0] STATE, NEXT;
    // Handshake
    logic arhns, rhns, awhns, whns, bhns;
    logic ahns;  // arhns || awhns
    logic rdfin, wrfin;
    // Sample
    logic [21:0] addr;
    logic [`AXI_IDS_BITS  -1:0] ids;
    logic [`AXI_BURST_BITS-1:0] burst;
    logic [`AXI_LEN_BITS  -1:0] len_r;
    logic [`AXI_SIZE_BITS -1:0] size;
    logic [`AXI_STRB_BITS -1:0] wstrb;
    logic [`AXI_DATA_BITS -1:0] wdata_r;
    logic latch_wlast;
    // DRAM
    logic [1:0] byte_off;
    logic [`WEB_BITS   -1:0] bwen, hwen, dramwen_r;
    logic [`DATA_BITS  -1:0] dramdata_r;
    logic [`DRAM_A_BITS-1:0] row_r, col_r;
    logic dramvalid;
    logic write;  // latch write signal
    logic clear;  // clear write
    logic samerow;
    logic col_over, row_change;
    logic wrcol_done;
// FIFO
logic [`DATA_BITS-1:0] fifo_datain, fifo_dataout;
logic fifo_clr;
logic fifo_wen, fifo_ren, fifo_empty, fifo_full;
    // Counter
    logic flag;  // go to the next step
    logic [2:0] dcnt;  // wait 5 cycle
    logic [`AXI_LEN_BITS-1:0] rcnt;   // cnt for read

// {{{ Handshake
    assign arhns = s2axi_i.arvalid && s2axi_o.arready;
    assign rhns  = s2axi_o.rvalid  && s2axi_i.rready;
    assign awhns = s2axi_i.awvalid && s2axi_o.awready; 
    assign whns  = s2axi_i.wvalid  && s2axi_o.wready;
    assign bhns  = s2axi_o.bvalid  && s2axi_i.bready;
    assign ahns  = arhns || awhns;
    assign rdfin = s2axi_o.rlast && rhns;
    assign wrfin = s2axi_i.wlast && whns;
// }}}
    
// {{{ Sample
    assign clear = ((STATE == READCOL) || (STATE == WRITECOL)) & dcnt[2];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            ids         <= `AXI_IDS_BITS'h0;
            burst       <= `AXI_BURST_BITS'h0;
            len_r       <= `AXI_LEN_BITS'h0;
            size        <= `AXI_SIZE_BITS'h0;
            wstrb       <= `AXI_STRB_BITS'h0;
            write       <= 1'b0;
            dramvalid   <= 1'b0;
            dramdata_r  <= `DATA_BITS'h0;
        end
        else begin
            ids       <= arhns ? s2axi_i.arid    : awhns ? s2axi_i.awid    : ids;
            burst     <= arhns ? s2axi_i.arburst : awhns ? s2axi_i.awburst : burst;
            len_r     <= arhns ? s2axi_i.arlen   : awhns ? s2axi_i.awlen   : len_r;
            size      <= arhns ? s2axi_i.arsize  : awhns ? s2axi_i.awsize  : size;
            wstrb     <= awhns ? s2axi_i.wstrb   : wstrb;
            write       <= (STATE == PRECHG) ? 1'b0 : (awhns ? 1'b1 : write);
            dramvalid   <= DRAM_valid_i;
            dramdata_r  <= DRAM_valid_i ? DRAM_Q_i : dramdata_r; 
        end
    end
// }}}
// {{{ Counter, flag, wrcol_done
    always_comb begin
        case (STATE)
            READCOL : flag = dramvalid;
            default : flag = dcnt[2];
        endcase
    end

    always_comb begin
        case (|len_r)
            1'b0 : wrcol_done = flag && wrfin;
            1'b1 : wrcol_done = flag && ~fifo_empty && latch_wlast;
        endcase
    end
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
                    rcnt <= rcnt;//`AXI_LEN_BITS'h0;
                end
                READCOL  : begin
                    dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? (rcnt + `AXI_LEN_BITS'h1): rcnt;
                end
                WRITECOL : begin
                    dcnt <=  flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <=  `AXI_LEN_BITS'h0;
                end         
                CHANGE   :  begin
                    dcnt <=  flag ? 3'h0 : (dcnt + 3'h1);
                    rcnt <=  rcnt;
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
            SETROW   : begin
                case ({flag, write})
                    2'b10   : NEXT = READCOL;
                    2'b11   : NEXT = WRITECOL;
                    default : NEXT = SETROW;
                endcase
            end
            // READCOL  : NEXT = flag & rdfin ? PRECHG : READCOL;
            READCOL  : begin
                case ({(flag && rdfin), row_change})
                    2'b01   : NEXT = CHANGE;
                    2'b10   : NEXT = PRECHG;
                    default : NEXT = READCOL;
                endcase
            end
            WRITECOL : begin
                case ({wrcol_done, row_change})
                    2'b01   : NEXT = CHANGE;
                    2'b10   : NEXT = PRECHG;
                    2'b11   : NEXT = PRECHG;
                    default : NEXT = WRITECOL;
                endcase
            end
            CHANGE   : NEXT = flag         ? SETROW : CHANGE;
            PRECHG   : NEXT = flag         ? IDLE   : PRECHG;
            default  : NEXT = STATE;
        endcase
    end
// }}}
// {{{ DRAM 
    assign col_over = &col_r[`DRAM_A_BITS-2:0];

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)               latch_wlast <= 1'b0;
        else if (s2axi_i.wlast) latch_wlast <= 1'b1;
        else if (awhns)         latch_wlast <= 1'b0;
    end

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            row_change <= 1'b0;
        else begin
            case(STATE)
                READCOL  : row_change <= col_over && DRAM_valid_i;
                WRITECOL : row_change <= col_over && (&dcnt[1:0]);
            endcase
        end
    end

    logic row_inc;
    assign row_inc = (STATE == CHANGE) && flag;
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)          col_r <= `DRAM_A_BITS'h0;
        else if (row_inc)  col_r <= `DRAM_A_BITS'h0;
        else if (arhns)    col_r <= s2axi_i.araddr[11:2];
        else if (awhns)    col_r <= s2axi_i.awaddr[11:2];
        else if (rhns)     col_r <= col_r + `DRAM_A_BITS'h1;
        else if (fifo_ren) col_r <= col_r + `DRAM_A_BITS'h1;
    end

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)         row_r <= `DRAM_A_BITS'h0;
        else if (row_inc) row_r <= row_r + `DRAM_A_BITS'h1;
        else if (arhns)   row_r <= s2axi_i.araddr[22:12];
        else if (awhns)   row_r <= s2axi_i.awaddr[22:12];

    end
    // DRAM_WEn
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)       byte_off <= 2'h0;
        else if (arhns) byte_off <= s2axi_i.araddr[1:0];
        else if (awhns) byte_off <= s2axi_i.awaddr[1:0];
    end
    always_comb begin
        case (byte_off)
            2'h0 : {bwen, hwen} = {4'b1110, 4'b1100};
            2'h1 : {bwen, hwen} = {4'b1101, 4'b1001};
            2'h2 : {bwen, hwen} = {4'b1011, 4'b0011};
            2'h3 : {bwen, hwen} = {4'b0111, 4'b0111};
        endcase
    end
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) 
            dramwen_r <= 4'h0;
        else begin
            case (wstrb)
                `AXI_STRB_HWORD : dramwen_r <= hwen;
                `AXI_STRB_BYTE  : dramwen_r <= bwen;
            endcase
        end
    end
// {{{
    always_comb begin
        DRAM_A_o    = `DRAM_A_BITS'h0;
        DRAM_D_o    = `DATA_BITS'h0;
        DRAM_CSn_o  = 1'b1;
        DRAM_RASn_o = 1'b1;
        DRAM_CASn_o = 1'b1;
        DRAM_WEn_o  = 4'hf;
        case (STATE)
            SETROW   : begin
                DRAM_A_o    = row_r; //addr[20:10]; 
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
                DRAM_D_o    = fifo_dataout;// wdata_r;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = ~|dcnt ? dramwen_r : 4'hf;
            end

            PRECHG, CHANGE : begin
                DRAM_A_o    = row_r;//addr[20:10]; 
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = {4{|dcnt}}; //~|dcnt ? 4'h0 : 4'hf;
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
    // ready
    always_comb begin
        case(STATE)
            IDLE     : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = {~s2axi_i.awvalid, 2'b10};
            WRITECOL : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = {2'b0, flag};
            default  : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = 3'b0;
        endcase
    end
    // valid
    logic bvalid;
    always_ff @(posedge clk or negedge rst) begin
        bvalid <= ~rst ? 1'b0 : wrcol_done;
    end
    assign s2axi_o.bvalid = bvalid;
    assign s2axi_o.rvalid = dramvalid;

// }}}

// {{{ FIFO
    assign fifo_wen = s2axi_i.wvalid && ~fifo_full && flag;
    assign fifo_ren = s2axi_o.wready && ~fifo_empty;
    assign fifo_datain = s2axi_i.wdata;
    assign fifo_clr    = ahns;

    FIFO #(.FIFO_DEPTH(FIFO_DEPTH)) i_fifo (
        .clk     (clk         ),
        .rst     (~rst        ),
        .clr_i   (fifo_clr    ),
        .wen_i   (fifo_wen    ),
        .ren_i   (fifo_ren    ),
        .data_i  (fifo_datain ),
        .data_o  (fifo_dataout),
        .empty_o (fifo_empty  ),
        .full_o  (fifo_full   )
    );
// }}}
endmodule
/* same row detection
    localparam FIFO_DEPTH = 2;
    localparam IDLE     = 3'h0,
               SETROW   = 3'h1,
               READCOL  = 3'h2,
               WRITECOL = 3'h3,
               WAITCHK  = 3'h4, CHKROW = 3'h5,  // check wheather the row is same or not
               CHANGE   = 3'h6, PRECHG = 3'h7;
    logic [2:0] STATE, NEXT;
    // Handshake
    logic arhns, rhns, awhns, whns, bhns;
    logic ahns;  // arhns || awhns
    logic rdfin, wrfin;
    // Sample
    logic [21:0] addr;
    logic [`AXI_IDS_BITS  -1:0] ids;
    logic [`AXI_BURST_BITS-1:0] burst;
    logic [`AXI_LEN_BITS  -1:0] len_r;
    logic [`AXI_SIZE_BITS -1:0] size;
    logic [`AXI_STRB_BITS -1:0] wstrb;
    logic [`AXI_DATA_BITS -1:0] wdata_r;
    logic latch_wlast;
    // DRAM
    logic [1:0] byte_off;
    logic [`WEB_BITS   -1:0] bwen, hwen, dramwen_r;
    logic [`DATA_BITS  -1:0] dramdata_r;
    logic [`DRAM_A_BITS-1:0] row_r, col_r;
    logic dramvalid;
    logic write;  // latch write signal
    logic clear;  // clear write
    logic wrowhit, rrowhit, samerow;
    logic col_over, row_change;
    logic wrcol_done;
    // FIFO
    logic [`DATA_BITS-1:0] fifo_datain, fifo_dataout;
    logic fifo_clr;
    logic fifo_wen, fifo_ren, fifo_empty, fifo_full;
    // Counter
    logic flag;  // go to the next step
    logic [2:0] dcnt;  // wait 5 cycle
    logic [`AXI_LEN_BITS-1:0] rcnt;   // cnt for read

// {{{ Handshake
    assign arhns = s2axi_i.arvalid && s2axi_o.arready;
    assign rhns  = s2axi_o.rvalid  && s2axi_i.rready;
    assign awhns = s2axi_i.awvalid && s2axi_o.awready; 
    assign whns  = s2axi_i.wvalid  && s2axi_o.wready;
    assign bhns  = s2axi_o.bvalid  && s2axi_i.bready;
    assign ahns  = arhns || awhns;
    assign rdfin = s2axi_o.rlast && rhns;
    assign wrfin = s2axi_i.wlast && whns;
// }}}
    
// {{{ Sample
    assign clear = ((STATE == READCOL) || (STATE == WRITECOL)) & dcnt[2];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            ids        <= `AXI_IDS_BITS'h0;
            burst      <= `AXI_BURST_BITS'h0;
            len_r      <= `AXI_LEN_BITS'h0;
            size       <= `AXI_SIZE_BITS'h0;
            wstrb      <= `AXI_STRB_BITS'h0;
            write      <= 1'b0;
            dramvalid  <= 1'b0;
            dramdata_r <= `DATA_BITS'h0;
        end
        else begin
            ids        <= arhns ? s2axi_i.arid    : awhns ? s2axi_i.awid    : ids;
            burst      <= arhns ? s2axi_i.arburst : awhns ? s2axi_i.awburst : burst;
            len_r      <= arhns ? s2axi_i.arlen   : awhns ? s2axi_i.awlen   : len_r;
            size       <= arhns ? s2axi_i.arsize  : awhns ? s2axi_i.awsize  : size;
            wstrb      <= awhns ? s2axi_i.wstrb   : wstrb;
            write      <= wrcol_done ? 1'b0 : (awhns ? 1'b1 : write);
            dramvalid  <= DRAM_valid_i;
            dramdata_r <= DRAM_valid_i ? DRAM_Q_i : dramdata_r; 
        end
    end
// }}}
// {{{ flag, wrcol_done
    always_comb begin
        case (STATE)
            IDLE    : flag = 1'b1;
            READCOL : flag = dramvalid;
            WAITCHK : flag = 1'b1;
            default : flag = dcnt[2];
        endcase
    end
    always_comb begin
        case (|len_r)
            1'b0 : wrcol_done = flag && wrfin;
            1'b1 : wrcol_done = flag && ~fifo_empty && latch_wlast;
        endcase
    end
// }}}
// {{{ cnt
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)       
            dcnt <= 3'h0;
        else begin
            case (STATE)
                WAITCHK : dcnt <= {3{ahns}};
                default : dcnt <= flag ? 3'h0 : dcnt + 3'h1;
            endcase
        end
    end
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) 
            rcnt <= `AXI_LEN_BITS'h0;
        else begin
            case (STATE)
                SETROW   : rcnt <= rcnt;
                READCOL  : rcnt <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? (rcnt + `AXI_LEN_BITS'h1) : rcnt;
                WRITECOL : rcnt <= `AXI_LEN_BITS'h0;       
                CHANGE   : rcnt <= rcnt;
                default  : rcnt <= `AXI_LEN_BITS'h0;
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
            SETROW   : begin
                case ({flag, write})
                    2'b10   : NEXT = READCOL;
                    2'b11   : NEXT = WRITECOL;
                    default : NEXT = SETROW;
                endcase
            end
            // READCOL  : NEXT = flag & rdfin ? PRECHG : READCOL;
            READCOL  : begin
                case ({(flag && rdfin), row_change})
                    2'b01   : NEXT = CHANGE;
                    2'b10   : NEXT = PRECHG;
                    default : NEXT = READCOL;
                endcase
            end
            WRITECOL : begin
                case ({wrcol_done, row_change})
                    2'b01   : NEXT = CHANGE;
                    // 2'b10   : NEXT = PRECHG;
                    2'b10   : NEXT = WAITCHK;
                    2'b11   : NEXT = PRECHG;
                    default : NEXT = WRITECOL;
                endcase
            end
            WAITCHK  : NEXT = ahns ? CHKROW : WAITCHK;
            CHKROW   : begin
                case ({wrowhit, rrowhit, flag})
                    3'b100  : NEXT = READCOL;
                    3'b010  : NEXT = WRITECOL;
                    3'b001  : NEXT = SETROW;
                    default : NEXT = CHKROW;
                endcase
            end
            CHANGE   : NEXT = flag ? SETROW : CHANGE;
            PRECHG   : NEXT = flag ? IDLE   : PRECHG;
            default  : NEXT = STATE;
        endcase
    end
// }}}
// {{{ DRAM 
    // samerow
    logic ssamerow;
    assign ssamerow = awhns ? row_r == s2axi_i.awaddr[22:12] :
                      arhns ? row_r == s2axi_i.araddr[22:12] : 1'b0;
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)                 {wrowhit, rrowhit, samerow} <= 3'b0;
        else if (STATE == CHKROW) {wrowhit, rrowhit, samerow} <= {write, ~write, 1'b1} & {3{ssamerow}};
        else if (wrcol_done)      {wrowhit, samerow} <= 2'b0;
        else if (rdfin)           {rrowhit, samerow} <= 2'b0;
    end
    logic [10:0] row_lock;
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)      row_lock <= `DRAM_A_BITS'h0;
        else if (ahns) row_lock <= row_r;
    end

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)               latch_wlast <= 1'b0;
        else if (s2axi_i.wlast) latch_wlast <= 1'b1;
        else if (awhns)         latch_wlast <= 1'b0;
    end

    assign col_over = &col_r[`DRAM_A_BITS-2:0];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            row_change <= 1'b0;
        else begin
            case(STATE)
                READCOL  : row_change <= col_over && DRAM_valid_i;
                WRITECOL : row_change <= col_over && (&dcnt[1:0]);
            endcase
        end
    end
    logic row_inc;
    assign row_inc = (STATE == CHANGE) && flag;
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)          col_r <= `DRAM_A_BITS'h0;
        else if (row_inc)  col_r <= `DRAM_A_BITS'h0;
        else if (arhns)    col_r <= s2axi_i.araddr[11:2];
        else if (awhns)    col_r <= s2axi_i.awaddr[11:2];
        else if (rhns)     col_r <= col_r + `DRAM_A_BITS'h1;
        else if (fifo_ren) col_r <= col_r + `DRAM_A_BITS'h1;
    end
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)         row_r <= `DRAM_A_BITS'h0;
        else if (row_inc) row_r <= row_r + `DRAM_A_BITS'h1;
        else if (arhns)   row_r <= s2axi_i.araddr[22:12];
        else if (awhns)   row_r <= s2axi_i.awaddr[22:12];
    end
    // DRAM_WEn
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)       byte_off <= 2'h0;
        else if (arhns) byte_off <= s2axi_i.araddr[1:0];
        else if (awhns) byte_off <= s2axi_i.awaddr[1:0];
    end
    always_comb begin
        case (byte_off)
            2'h0 : {bwen, hwen} = {4'b1110, 4'b1100};
            2'h1 : {bwen, hwen} = {4'b1101, 4'b1001};
            2'h2 : {bwen, hwen} = {4'b1011, 4'b0011};
            2'h3 : {bwen, hwen} = {4'b0111, 4'b0111};
        endcase
    end
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) 
            dramwen_r <= 4'h0;
        else begin
            case (wstrb)
                `AXI_STRB_HWORD : dramwen_r <= hwen;
                `AXI_STRB_BYTE  : dramwen_r <= bwen;
            endcase
        end
    end
// {{{
    always_comb begin
        DRAM_A_o    = `DRAM_A_BITS'h0;
        DRAM_D_o    = `DATA_BITS'h0;
        DRAM_CSn_o  = 1'b1;
        DRAM_RASn_o = 1'b1;
        DRAM_CASn_o = 1'b1;
        DRAM_WEn_o  = 4'hf;
        case (STATE)
            SETROW   : begin
                DRAM_A_o    = row_r; //addr[20:10]; 
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
                DRAM_D_o    = fifo_dataout;// wdata_r;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = ~|dcnt ? dramwen_r : 4'hf;
            end
            CHKROW  : begin
                DRAM_A_o    = row_lock;//addr[20:10]~; 
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = ~&dcnt;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = {4{|dcnt}}; //~|dcnt ? 4'h0 : 4'hf;                
            end
            PRECHG, CHANGE : begin
                DRAM_A_o    = row_r;//addr[20:10]; 
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = {4{|dcnt}}; //~|dcnt ? 4'h0 : 4'hf;
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
    // ready
    always_comb begin
        case(STATE)
            IDLE     : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = {~s2axi_i.awvalid, 2'b10};
            WAITCHK  : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = {~s2axi_i.awvalid, 2'b10};
            WRITECOL : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = {2'b0, flag};
            default  : {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = 3'b0;
        endcase
    end
    // valid
    assign s2axi_o.rvalid = dramvalid;
    always_ff @(posedge clk or negedge rst) begin
        s2axi_o.bvalid <= ~rst ? 1'b0 : wrcol_done;
    end
// }}}

// {{{ FIFO
    assign fifo_wen = s2axi_i.wvalid && ~fifo_full && flag;
    assign fifo_ren = s2axi_o.wready && ~fifo_empty;
    assign fifo_datain = s2axi_i.wdata;
    assign fifo_clr    = ahns;

    FIFO #(.FIFO_DEPTH(FIFO_DEPTH)) i_fifo (
        .clk     (clk         ),
        .rst     (~rst        ),
        .clr_i   (fifo_clr    ),
        .wen_i   (fifo_wen    ),
        .ren_i   (fifo_ren    ),
        .data_i  (fifo_datain ),
        .data_o  (fifo_dataout),
        .empty_o (fifo_empty  ),
        .full_o  (fifo_full   )
    );
// }}}
endmodule
*/

