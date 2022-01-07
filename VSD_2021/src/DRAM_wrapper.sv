`include "../include/CPU_def.svh"
`include "./Interface/inf_Slave.sv"

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
	
    parameter IDLE     = 3'h0,
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
    logic [`AXI_LEN_BITS  -1:0] len;
    logic [`AXI_SIZE_BITS -1:0] size;
    logic [`AXI_STRB_BITS -1:0] wstrb;
    logic [`AXI_DATA_BITS -1:0] wdata;
    // DRAM
    logic [1:0] byte_off;
    logic [`WEB_BITS   -1:0] bwen, hwen, dramwen;
    logic [`DATA_BITS  -1:0] dramdata_r;
    logic [`DATA_BITS  -1:0] dramdataD_r;
    logic [`DRAM_A_BITS-1:0] row, col, col_r;
    logic [ 1:0] off;
    logic dramvalid_r;
    // Counter
    logic [2:0] dcnt;  // wait 5 cycle
    logic [`AXI_LEN_BITS-1:0] rcnt;   // cnt for read
    // Other
    logic write;
    logic clear;  // clear write
    

// {{{ Handshake
    assign arhns = s2axi_i.arvalid & s2axi_o.arready;
    assign rhns  = s2axi_o.rvalid  & s2axi_i.rready;
    assign awhns = s2axi_i.awvalid & s2axi_o.awready; 
    assign whns  = s2axi_i.wvalid  & s2axi_o.wready;
    assign bhns  = s2axi_o.bvalid  & s2axi_i.bready;
    assign ahns  = arhns | awhns;
    assign rdfin = s2axi_o.rlast & rhns;
    assign wrfin = s2axi_i.wlast & whns;
// }}}
    
// {{{ Sample
    assign clear = ((STATE == READCOL) | (STATE == WRITECOL)) & dcnt[2];
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            addr      <= 21'h0;
            ids       <= `AXI_IDS_BITS'h0;
            burst     <= `AXI_BURST_BITS'h0;
            len       <= `AXI_LEN_BITS'h0;
            size      <= `AXI_SIZE_BITS'h0;
            wstrb     <= `AXI_STRB_BITS'h0;
            wdata     <= `DATA_BITS'h0;
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
            len       <= arhns ? s2axi_i.arlen   : awhns ? s2axi_i.awlen   : len;
            size      <= arhns ? s2axi_i.arsize  : awhns ? s2axi_i.awsize  : size;
            wstrb     <= awhns ? s2axi_i.wstrb   : wstrb;
            wdata     <= awhns ? s2axi_i.wdata   : wdata;
            write     <= clear ? 1'b0 : (awhns ? 1'b1 : write);
            dramvalid_r <= DRAM_valid_i;
            dramdata_r  <= DRAM_valid_i ? DRAM_Q_i : dramdata_r; 
            dramdataD_r <= (STATE == SETROW) ? s2axi_i.wdata : dramdataD_r;
        end
    end
// }}}
// {{{ Counter, flag
    logic flag;
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
            IDLE     : NEXT = ahns         ? SETROW : IDLE;
            SETROW   : NEXT = flag         ? (write ? WRITECOL : READCOL) : SETROW;
            READCOL  : NEXT = flag & rdfin ? PRECHG : READCOL;
            WRITECOL : NEXT = flag         ? PRECHG : WRITECOL; 
            PRECHG   : NEXT = flag         ? IDLE : PRECHG;
            default  : NEXT = STATE;
        endcase
    end
// }}}
// {{{ DRAM 
    assign row = addr[20:10];
    assign col = {1'b0, addr[9:0]};
    assign off = rcnt[1:0];

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)      col_r <= `DRAM_A_BITS'h0;
        else if (rhns) col_r <= addr[9:0] + rcnt + `DRAM_A_BITS'h1;
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
    // DRAM_A
    // always_comb begin
    //     if (burst)
    // end
    always_comb begin
        case (STATE)
            IDLE     : begin
                DRAM_A_o    = row;
                DRAM_D_o    = `DATA_BITS'h0;
                DRAM_CSn_o  = 1'b1;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = 4'hf;
            end
            SETROW   : begin
                DRAM_A_o    = row;
                DRAM_D_o    = s2axi_i.wdata;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = |dcnt;
                DRAM_CASn_o = 1'b1;
                DRAM_WEn_o  = 4'hf;
            end
            READCOL  : begin
                // DRAM_A_o    = col + {9'h0, off};
                DRAM_A_o    = col_r;
                DRAM_D_o    = s2axi_i.wdata;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = 4'hf;
            end
            WRITECOL : begin
                DRAM_A_o    = col;
                DRAM_D_o    = dramdataD_r;
                DRAM_CSn_o  = 1'b0;
                DRAM_RASn_o = 1'b1;
                DRAM_CASn_o = |dcnt;
                DRAM_WEn_o  = ~|dcnt ? dramwen : 4'hf;
            end
            PRECHG   : begin
                DRAM_A_o    = row; 
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
    assign s2axi_o.rlast = rcnt == len;
    assign s2axi_o.bid   = ids;
    assign s2axi_o.bresp = `AXI_RESP_OKAY;
    logic [2:0] readyout;
    logic [1:0] validout;
    assign {s2axi_o.arready, s2axi_o.awready, s2axi_o.wready} = readyout;
    assign {s2axi_o.rvalid, s2axi_o.bvalid} = validout;
    always_comb begin
        case (STATE)
            IDLE     : readyout = {~s2axi_i.awvalid, 2'b10};
            WRITECOL : readyout = 3'b1;
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
endmodule
