`include "../include/CPU_def.svh"
`include "./Interface/inf_Slave.sv"

module DRAM_wrapper (
    input                                      clk,
    rst,
           inf_Slave.S2AXIin                   s2axi_i,
           inf_Slave.S2AXIout                  s2axi_o,
    input                     [`DATA_BITS-1:0] DRAM_Q_i,
    input                                      DRAM_valid_i,
    output logic                               DRAM_CSn_o,
    output logic              [`WEB_BITS -1:0] DRAM_WEn_o,
    output logic                               DRAM_RASn_o,
    output logic                               DRAM_CASn_o,
    output logic              [          10:0] DRAM_A_o,
    output logic              [`DATA_BITS-1:0] DRAM_D_o
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
  logic                       ahns;  // Address handshake;
  // Sample
  logic [               22:2] addr;
  logic [`AXI_IDS_BITS  -1:0] ids;
  logic [`AXI_BURST_BITS-1:0] burst;
  logic [`AXI_LEN_BITS  -1:0] len;
  logic [`AXI_SIZE_BITS -1:0] size;
  logic [`AXI_STRB_BITS -1:0] wstrb;
  logic [`AXI_DATA_BITS -1:0] wdata;
  // logic                       rvalid, bvalid;
  // DRAM
  logic [                1:0] byte_off;
  logic [`WEB_BITS  -1:0] bwen, hwen, dramwen;
  logic [`DATA_BITS -1:0] dramdata;
  logic [`DATA_BITS -1:0] dramdataD;
  // Rom
  logic [10:0] row, col;
  logic [1:0] off;
  // Delay counter
  logic [2:0] dcnt;  // wait 5 cycle
  logic [`AXI_LEN_BITS-1:0] rcnt;
  // Other
  logic rdfin, wrfin;
  logic write;
  logic clear;  // clear write
  logic dramvalid;

  // {{{ Handshake
  assign arhns = s2axi_i.arvalid & s2axi_o.arready;
  assign rhns  = s2axi_o.rvalid & s2axi_i.rready;
  assign awhns = s2axi_i.awvalid & s2axi_o.awready;
  assign whns  = s2axi_i.wvalid & s2axi_o.wready;
  assign bhns  = s2axi_o.bvalid & s2axi_i.bready;
  assign ahns  = arhns | awhns;
  // }}}
  // 
  assign row   = addr[22:12];
  assign col   = {1'b0, addr[11:2]};
  assign off   = rcnt[1:0];
  assign rdfin = s2axi_o.rlast & rhns;
  assign wrfin = s2axi_i.wlast & whns;
  assign clear = ((STATE == READCOL) | (STATE == WRITECOL)) & dcnt[2];
  // {{{ Sample
  always_ff @(posedge clk or negedge rst) begin
    if (~rst) begin
      addr      <= 21'h0;
      byte_off  <= 2'h0;
      ids       <= `AXI_IDS_BITS'h0;
      burst     <= `AXI_BURST_BITS'h0;
      len       <= `AXI_LEN_BITS'h0;
      size      <= `AXI_SIZE_BITS'h0;
      wstrb     <= `AXI_STRB_BITS'h0;
      wdata     <= `DATA_BITS'h0;
      // rvalid    <= 1'b0;
      write     <= 1'b0;
      dramvalid <= 1'b0;
      dramdata  <= `DATA_BITS'h0;
      dramdataD <= `DATA_BITS'h0;
    end else begin
      addr      <= arhns ? s2axi_i.araddr[22:2] : awhns ? s2axi_i.awaddr[22:2] : addr;
      byte_off  <= arhns ? s2axi_i.araddr[ 1:0] : awhns ? s2axi_i.awaddr[1:0]  : byte_off;
      ids <= arhns ? s2axi_i.arid : awhns ? s2axi_i.awid : ids;
      burst <= arhns ? s2axi_i.arburst : awhns ? s2axi_i.awburst : burst;
      len <= arhns ? s2axi_i.arlen : awhns ? s2axi_i.awlen : len;
      size <= arhns ? s2axi_i.arsize : awhns ? s2axi_i.awsize : size;
      wstrb <= awhns ? s2axi_i.wstrb : wstrb;
      wdata <= awhns ? s2axi_i.wdata : wdata;
      // rvalid    <= arhns ? 1'b0 : s2axi_o.rvalid;
      write <= clear ? 1'b0 : (awhns ? 1'b1 : write);
      dramvalid <= DRAM_valid_i;
      dramdata <= DRAM_valid_i ? DRAM_Q_i : dramdata;
      dramdataD <= (STATE == SETROW) ? s2axi_i.wdata : dramdataD;
    end
  end
  // }}}
  // {{{ Counter, flag
  logic flag;
  // assign flag = (STATE == READCOL) ? dcnt == 3'h5 : dcnt[2];
  // assign flag = (STATE == READCOL) ? DRAM_valid_i : dcnt[2];
  assign flag = (STATE == READCOL) ? dramvalid : dcnt[2];

  always_ff @(posedge clk or negedge rst) begin
    if (~rst) begin
      dcnt <= 3'h0;
      rcnt <= `AXI_LEN_BITS'h0;
    end else begin
      case (STATE)
        IDLE: begin
          dcnt <= 3'h0;
          rcnt <= `AXI_LEN_BITS'h0;
        end
        SETROW: begin
          dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
          rcnt <= `AXI_LEN_BITS'h0;
        end
        READCOL: begin
          dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
          rcnt <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? (rcnt + `AXI_LEN_BITS'h1): rcnt;
        end
        WRITECOL: begin
          dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
          rcnt <= `AXI_LEN_BITS'h0;
        end
        PRECHG: begin
          dcnt <= flag ? 3'h0 : (dcnt + 3'h1);
          rcnt <= `AXI_LEN_BITS'h0;
        end
      endcase
    end
  end
  // }}}

  // {{{ State
  always_ff @(posedge clk or negedge rst) begin
    STATE <= ~rst ? IDLE : NEXT;
  end
  always_comb begin  // flag = dcnt == 3'h4
    case (STATE)
      IDLE:     NEXT = ahns ? SETROW : IDLE;
      SETROW:   NEXT = flag ? (write ? WRITECOL : READCOL) : SETROW;
      READCOL:  NEXT = flag & rdfin ? PRECHG : READCOL;
      WRITECOL: NEXT = flag ? PRECHG : WRITECOL;
      PRECHG:   NEXT = flag ? IDLE : PRECHG;
      default:  NEXT = STATE;
    endcase
  end
  // }}}
  // {{{ DRAM 
  always_comb begin
    case (byte_off)
      2'h0: {bwen, hwen} = {4'b1110, 4'b1100};
      2'h1: {bwen, hwen} = {4'b1101, 4'b1001};
      2'h2: {bwen, hwen} = {4'b1011, 4'b0011};
      2'h3: {bwen, hwen} = {4'b0111, 4'b0111};
    endcase
  end
  always_comb begin
    //case (s2axi_i.wstrb)
    case (wstrb)
      `AXI_STRB_HWORD: dramwen = hwen;
      `AXI_STRB_BYTE:  dramwen = bwen;
      default:         dramwen = 4'h0;
    endcase
  end


  always_comb begin
    case (STATE)
      IDLE: begin
        DRAM_A_o    = row;
        DRAM_D_o    = `DATA_BITS'h0;
        DRAM_CSn_o  = 1'b1;
        DRAM_RASn_o = 1'b1;
        DRAM_CASn_o = 1'b1;
        DRAM_WEn_o  = 4'hf;
      end
      SETROW: begin
        DRAM_A_o    = row;
        DRAM_D_o    = s2axi_i.wdata;
        DRAM_CSn_o  = 1'b0;
        DRAM_RASn_o = |dcnt;
        DRAM_CASn_o = 1'b1;
        DRAM_WEn_o  = 4'hf;
      end
      READCOL: begin
        DRAM_A_o    = col + {9'h0, off};
        //DRAM_A_o    = {col[11:2], off};
        DRAM_D_o    = s2axi_i.wdata;
        DRAM_CSn_o  = 1'b0;
        DRAM_RASn_o = 1'b1;
        DRAM_CASn_o = |dcnt;
        DRAM_WEn_o  = 4'hf;
      end
      WRITECOL: begin
        DRAM_A_o    = col;
        DRAM_D_o    = dramdataD;
        DRAM_CSn_o  = 1'b0;
        DRAM_RASn_o = 1'b1;
        DRAM_CASn_o = |dcnt;
        DRAM_WEn_o  = ~|dcnt ? dramwen : 4'hf;
      end
      PRECHG: begin
        DRAM_A_o    = row;
        DRAM_D_o    = `DATA_BITS'h0;
        DRAM_CSn_o  = 1'b0;
        DRAM_RASn_o = |dcnt;
        DRAM_CASn_o = 1'b1;
        DRAM_WEn_o  = ~|dcnt ? 4'h0 : 4'hf;
      end
      default: begin
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
  assign s2axi_o.rdata = DRAM_valid_i ? DRAM_Q_i : dramdata;
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
      IDLE:     readyout = {~s2axi_i.awvalid, 2'b10};
      // SETROW   : readyout = 3'b0;
      // READCOL  : readyout = 3'b0;
      WRITECOL: readyout = 3'b1;
      // PRECHG   : readyout = 3'b0;
      default:  readyout = 3'b0;
    endcase
  end
  always_comb begin
    case (STATE)
      // IDLE     : validout = 2'b0; 
      // SETROW   : validout = 2'b0;
      // READCOL  : validout = {DRAM_valid_i, 1'b0};
      READCOL: validout = {dramvalid, 1'b0};
      // WRITECOL : validout = 2'b0;
      PRECHG:  validout = {1'b0, ~|dcnt};
      default: validout = 2'b0;
    endcase
  end
  // }}}

endmodule
