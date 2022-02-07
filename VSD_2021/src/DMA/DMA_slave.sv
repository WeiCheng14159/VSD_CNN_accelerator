`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"

module DMA_slave (
    input                                      clk,
    rst,
           inf_Slave.S2AXIin                   s2axi_i,
           inf_Slave.S2AXIout                  s2axi_o,
    input                                      dma_fin_i,
    output logic                               dma_en_o,
    output logic              [`ADDR_BITS-1:0] src_addr_o,
    output logic              [`ADDR_BITS-1:0] dst_addr_o,
    output logic              [`DATA_BITS-1:0] data_qty_o
);

  logic [1:0] STATE, NEXT;
  parameter IDLE = 2'h0, W_CH = 2'h1, B_CH = 2'h2, R_CH = 2'h3;
  // Handshake
  logic arhns, awhns, rhns, whns, bhns;
  logic rdfin, wrfin;
  // Sample
  logic [2:0] addr_r;
  logic [`AXI_IDS_BITS -1:0] ids_r;
  logic [`AXI_DATA_BITS-1:0] rdata_r;
  logic [`AXI_LEN_BITS -1:0] len_r;
  logic [`AXI_STRB_BITS-1:0] wstrb_r;
  // Handshake
  assign awhns = s2axi_i.awvalid & s2axi_o.awready;
  assign arhns = s2axi_i.arvalid & s2axi_o.arready;
  assign whns  = s2axi_i.wvalid & s2axi_o.wready;
  assign rhns  = s2axi_o.rvalid & s2axi_i.rready;
  assign bhns  = s2axi_o.bvalid & s2axi_i.bready;
  assign rdfin = s2axi_o.rlast & rhns;
  assign wrfin = s2axi_i.wlast & whns;

  // {{{ STATE
  always_ff @(posedge clk or posedge rst) begin
    STATE <= rst ? IDLE : NEXT;
  end
  always_comb begin
    case (STATE)
      IDLE: begin
        case ({
          awhns, whns, arhns
        })
          3'b110:  NEXT = B_CH;
          3'b100:  NEXT = W_CH;
          3'b001:  NEXT = R_CH;
          default: NEXT = IDLE;
        endcase
      end
      R_CH: begin
        case ({
          rdfin, awhns, arhns
        })
          3'b110:  NEXT = W_CH;
          3'b101:  NEXT = R_CH;
          3'b100:  NEXT = IDLE;
          default: NEXT = R_CH;
        endcase
      end
      W_CH: NEXT = wrfin ? B_CH : W_CH;
      B_CH: begin
        case ({
          bhns, awhns, arhns
        })
          3'b110:  NEXT = W_CH;
          3'b101:  NEXT = R_CH;
          3'b100:  NEXT = IDLE;
          default: NEXT = B_CH;
        endcase
      end
    endcase
  end
  // }}}

  // {{{ Sample
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      addr_r  <= 3'h0;
      ids_r   <= `AXI_IDS_BITS'h0;
      len_r   <= `AXI_LEN_BITS'h0;
      wstrb_r <= `AXI_STRB_BITS'h0;
    end else begin
      addr_r  <= arhns ? s2axi_i.araddr[4:2] : awhns ? s2axi_i.awaddr[4:2] : addr_r;
      ids_r <= arhns ? s2axi_i.arid : awhns ? s2axi_i.awid : ids_r;
      len_r <= awhns ? s2axi_i.awlen : arhns ? s2axi_i.arlen : len_r;
      wstrb_r <= awhns ? s2axi_i.wstrb : wstrb_r;
    end
  end
  // }}}

  // {{{ DMA
  // assign dma_en_o = {whns, addr_r[1:0]} & {3{s2axi_i.wdata[0]}};
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      src_addr_o <= `ADDR_BITS'h0;
      dst_addr_o <= `ADDR_BITS'h0;
      data_qty_o <= `DATA_BITS'h0;
      dma_en_o   <= 1'b0;
    end else if (whns) begin
      case (addr_r)
        3'h0: src_addr_o <= s2axi_i.wdata;
        3'h1: dst_addr_o <= s2axi_i.wdata;
        3'h2: data_qty_o <= s2axi_i.wdata;
        3'h3: dma_en_o <= s2axi_i.wdata[0];
      endcase
    end else dma_en_o <= 1'b0;
  end
  // }}}

  // {{{ --> AXI
  assign s2axi_o.rlast = 1;
  assign s2axi_o.rresp = `AXI_RESP_OKAY;
  assign s2axi_o.bresp = `AXI_RESP_OKAY;
  assign s2axi_o.rdata = 0;
  assign s2axi_o.rid   = ids_r;
  assign s2axi_o.bid   = ids_r;
  always_comb begin
    {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
    {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;
    case (STATE)
      IDLE: begin
        {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {
          1'b1, ~s2axi_i.awvalid, 1'b0
        };
        {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;
      end
      W_CH: begin
        {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b1;
        {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;
      end
      B_CH: begin
        {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {bhns, 2'b0};
        {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b01;
      end
      R_CH: begin
        {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {rhns, 2'b0};
        {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b10;
      end
    endcase
  end
  // }}}
endmodule
