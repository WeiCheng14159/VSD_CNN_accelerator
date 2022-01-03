`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Master.sv"
`include "./Interface/inf_Slave.sv"
// `include "./DMA/DMA_master.sv"
// `include "./DMA/DMA_slave.sv"

module DMA (
    input clk, rst,
    inf_Master.M2AXIin  m2axi_i,
    inf_Master.M2AXIout m2axi_o,
    inf_Slave.S2AXIin   s2axi_i,
    inf_Slave.S2AXIout  s2axi_o
);

    // output 
    assign m2axi_o.arid    = `AXI_ID_BITS'h0;
    assign m2axi_o.arlen   = `AXI_LEN_ONE;
    assign m2axi_o.arsize  = `AXI_SIZE_BITS'b10;
    assign m2axi_o.arburst = `AXI_BURST_INC;
    assign m2axi_o.araddr  = `AXI_ADDR_BITS'h0;
    assign m2axi_o.awid    = `AXI_ID_BITS'h0;
    assign m2axi_o.awlen   = `AXI_LEN_ONE;
    assign m2axi_o.awsize  = `AXI_SIZE_BITS'b10;
    assign m2axi_o.awburst = `AXI_BURST_INC;
    assign m2axi_o.awaddr  = `AXI_ADDR_BITS'h0;
    assign m2axi_o.wstrb   = `AXI_STRB_BITS'h0;
    assign m2axi_o.wlast   = 1'b1;
    assign m2axi_o.wdata   = `AXI_DATA_BITS'h0;
    assign {m2axi_o.arvalid, m2axi_o.awvalid, m2axi_o.wvalid} = 3'b0;
    assign {m2axi_o.rready, m2axi_o.bready} = 2'b0;

    assign s2axi_o.rlast = 1'b1;
    assign s2axi_o.rresp = `AXI_RESP_OKAY;
    assign s2axi_o.bresp = `AXI_RESP_OKAY;
    assign s2axi_o.rdata = `AXI_DATA_BITS'h0; 
    assign s2axi_o.rid   = `AXI_IDS_BITS'h0;
    assign s2axi_o.bid   = `AXI_IDS_BITS'h0;
    assign {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
    assign {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;

endmodule
