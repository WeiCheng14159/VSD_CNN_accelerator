`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Slave.sv"

module Input_wrapper (
    input clk, rst,
    inf_Slave.S2AXIin   s2axi_i,
    inf_Slave.S2AXIout  s2axi_o
);

    // output 
    assign s2axi_o.rlast = 1'b1;
    assign s2axi_o.rresp = `AXI_RESP_OKAY;
    assign s2axi_o.bresp = `AXI_RESP_OKAY;
    assign s2axi_o.rdata = `AXI_DATA_BITS'h0; 
    assign s2axi_o.rid   = `AXI_IDS_BITS'h0;
    assign s2axi_o.bid   = `AXI_IDS_BITS'h0;
    assign {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
    assign {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;

endmodule
