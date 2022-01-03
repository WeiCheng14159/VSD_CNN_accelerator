`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "../include/def.svh"

module Master(
    input clk, rst,
    inf_Master.M2AXIin  m2axi_i,
    inf_Master.M2AXIout m2axi_o,
    // Cache
    input                         creq_i,
    input                         sctrl_rd_i,
    input                         cwrite_i,
    input        [`TYPE_BITS-1:0] cwtype_i,
    input        [`DATA_BITS-1:0] cdatain_i,
    input        [`DATA_BITS-1:0] caddr_i,
    output logic [`DATA_BITS-1:0] dataout_o,
    output logic wait_o
);
// {{{
    // STATE
    logic [2:0] STATE, NEXT;
    parameter IDLE  = 3'h0,
                AR_CH = 3'h1,
                R_CH  = 3'h2,
                AW_CH = 3'h3,
                W_CH  = 3'h4,
                B_CH  = 3'h5;
    // Handshake
    logic awhns, arhns, rhns, whns, bhns;
    // Other
    logic rdfin, wrfin;
    logic req_rd, req_wr;
    logic [`AXI_STRB_BITS-1:0] wstrb;
    logic [`AXI_DATA_BITS-1:0] rdata;
// }}}
    // Handshake
    assign awhns = m2axi_i.awready & m2axi_o.awvalid;
    assign whns  = m2axi_i.wready  & m2axi_o.wvalid;
    assign bhns  = m2axi_o.bready  & m2axi_i.bvalid;
    assign arhns = m2axi_i.arready & m2axi_o.arvalid;
    assign rhns  = m2axi_o.rready  & m2axi_i.rvalid;
    // Finish
    assign rdfin = rhns & m2axi_i.rlast;
    assign wrfin = whns & m2axi_o.wlast;
    // Sample
    always_ff@(posedge clk or negedge rst) begin
        if (~rst) rdata <= `AXI_DATA_BITS'b0;
        else      rdata <= (rhns) ? m2axi_i.rdata : rdata;
    end
    always_comb begin
        case (cwtype_i[1:0])
            2'b00   : wstrb = `AXI_STRB_BYTE;
            2'b01   : wstrb = `AXI_STRB_HWORD;
            default : wstrb = `AXI_STRB_WORD;
        endcase
    end
    //
    assign m2axi_o.arid    = `AXI_ID_BITS'h0;
    assign m2axi_o.arlen   = sctrl_rd_i ? `AXI_LEN_ONE : `AXI_LEN_FOUR;
    assign m2axi_o.arsize  = `AXI_SIZE_BITS'b10;
    assign m2axi_o.arburst = `AXI_BURST_INC;
    assign m2axi_o.araddr  = caddr_i;
    assign m2axi_o.awid    = `AXI_ID_BITS'h0;
    assign m2axi_o.awlen   = `AXI_LEN_ONE;
    assign m2axi_o.awsize  = `AXI_SIZE_BITS'b10;
    assign m2axi_o.awburst = `AXI_BURST_INC;
    assign m2axi_o.awaddr  = caddr_i;
    assign m2axi_o.wstrb   = wstrb;
    assign m2axi_o.wlast   = 1'b1;
    assign m2axi_o.wdata   = cdatain_i;
    assign dataout_o       = rhns ? m2axi_i.rdata : rdata;

// {{{ STATE
    always_ff @(posedge clk or negedge rst) begin
        STATE <= ~rst ? IDLE : NEXT;
    end
    always_comb begin
        case (STATE)
            IDLE    : begin
                case ({m2axi_o.arvalid, m2axi_o.awvalid})
                    2'b10   : NEXT = arhns ? R_CH : AR_CH;
                    2'b01   : NEXT = awhns ? W_CH : AW_CH;
                    default : NEXT = IDLE;
                endcase
            end
            AR_CH   : NEXT = arhns ? R_CH : AR_CH;
            R_CH    : NEXT = rdfin ? IDLE : R_CH;
            AW_CH   : NEXT = awhns ? W_CH : AW_CH;
            W_CH    : NEXT = wrfin ? B_CH : W_CH;
            B_CH    : begin
                if (bhns) begin
                    case ({m2axi_o.arvalid, m2axi_o.awvalid})
                        2'b10   : NEXT = AR_CH;
                        2'b01   : NEXT = AW_CH;
                        default : NEXT = B_CH;
                    endcase
                end
                else 
                    NEXT = IDLE;
            end
            default : NEXT = IDLE;
        endcase
    end
// }}}	

    assign req_rd = (creq_i & ~cwrite_i) | sctrl_rd_i;
    assign req_wr = creq_i & cwrite_i;

    logic [2:0] validout;
    logic [1:0] readyout;
    assign {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = validout;
    assign {m2axi_o.rready, m2axi_o.bready} = readyout;
    always_comb begin
        case (STATE)
            IDLE    : validout = {req_rd, req_wr, 1'b0};
            AR_CH   : validout = 3'b100;
            R_CH    : validout = 3'b0;
            AW_CH   : validout = 3'b10;
            W_CH    : validout = 3'b1;
            B_CH    : validout = 3'b0;
            default : validout = 3'b0;
        endcase
    end

    always_comb begin
        case (STATE)
            IDLE    : readyout = 2'b0;
            AR_CH   : readyout = 2'b0;
            R_CH    : readyout = 2'b10;
            AW_CH   : readyout = 2'b0;
            W_CH    : readyout = {1'b0, wrfin};
            B_CH    : readyout = 2'b1;
            default : readyout = 2'b0;
        endcase
    end
    always_comb begin
        case (STATE)
            IDLE    : wait_o = req_wr | req_rd;
            AR_CH   : wait_o = 1'b1;
            //R_CH    : wait_o = ~rdfin;
            R_CH    : wait_o = ~rhns;
            AW_CH   : wait_o = 1'b1;
            W_CH    : wait_o = ~wrfin;
            B_CH    : wait_o = req_wr | req_rd;
            default : wait_o = 1'b0;
        endcase
    end

endmodule
