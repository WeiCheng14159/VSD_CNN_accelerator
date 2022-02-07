`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Master.sv"
`include "./Interface/inf_Slave.sv"
`include "./DMA/DMA_master.sv"
`include "./DMA/DMA_slave.sv"

module DMA (
    input clk,
    rst,
    inf_Master.M2AXIin m2axi_i,
    inf_Master.M2AXIout m2axi_o,
    inf_Slave.S2AXIin s2axi_i,
    inf_Slave.S2AXIout s2axi_o,
    output logic [1:0] int_o
);

  logic [`ADDR_BITS-1:0] src_addr, dst_addr;
  logic [`DATA_BITS-1:0] data_qty;  // quantity
  logic dma_en;  // start
  logic dma_fin, latch_fin, latch_int;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) latch_fin <= 1'b0;
    else if (dma_fin) latch_fin <= 1'b1;
    else if (latch_fin) latch_fin <= 1'b0;
  end
  always_ff @(posedge clk or posedge rst) begin
    latch_int <= rst ? 1'b0 : dma_fin | latch_fin;
  end
  assign int_o = {dma_fin, dma_en};

  // output 
  // assign int_o = 0;
  // assign m2axi_o.arid    = `AXI_ID_BITS'h0;
  // assign m2axi_o.arlen   = `AXI_LEN_ONE;
  // assign m2axi_o.arsize  = `AXI_SIZE_BITS'b10;
  // assign m2axi_o.arburst = `AXI_BURST_INC;
  // assign m2axi_o.araddr  = `AXI_ADDR_BITS'h0;
  // assign m2axi_o.awid    = `AXI_ID_BITS'h0;
  // assign m2axi_o.awlen   = `AXI_LEN_ONE;
  // assign m2axi_o.awsize  = `AXI_SIZE_BITS'b10;
  // assign m2axi_o.awburst = `AXI_BURST_INC;
  // assign m2axi_o.awaddr  = `AXI_ADDR_BITS'h0;
  // assign m2axi_o.wstrb   = `AXI_STRB_BITS'h0;
  // assign m2axi_o.wlast   = 1'b1;
  // assign m2axi_o.wdata   = `AXI_DATA_BITS'h0;
  // assign {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
  // assign {m2axi_o.rready, m2axi_o.bready} = 2'b0;

  // assign s2axi_o.rlast = 1'b1;
  // assign s2axi_o.rresp = `AXI_RESP_OKAY;
  // assign s2axi_o.bresp = `AXI_RESP_OKAY;
  // assign s2axi_o.rdata = `AXI_DATA_BITS'h0; 
  // assign s2axi_o.rid   = `AXI_IDS_BITS'h0;
  // assign s2axi_o.bid   = `AXI_IDS_BITS'h0;
  // assign {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
  // assign {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;


  DMA_master dma_m (
      .clk       (clk),
      .rst       (rst),
      .m2axi_i   (m2axi_i),
      .m2axi_o   (m2axi_o),
      .dma_en_i  (dma_en),
      .src_addr_i(src_addr),
      .dst_addr_i(dst_addr),
      .data_qty_i(data_qty),
      .dma_fin_o (dma_fin)
  );

  DMA_slave dma_s (
      .clk       (clk),
      .rst       (rst),
      .s2axi_i   (s2axi_i),
      .s2axi_o   (s2axi_o),
      .dma_fin_i (dma_fin),
      .dma_en_o  (dma_en),
      .src_addr_o(src_addr),
      .dst_addr_o(dst_addr),
      .data_qty_o(data_qty)
  );

endmodule
