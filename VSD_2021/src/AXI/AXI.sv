`include "../../include/AXI_define.svh"
`include "../Interface/inf_Slave.sv"
`include "./AR_ch.sv"
`include "./AW_ch.sv"
`include "./W_ch.sv"
`include "./B_ch.sv"
`include "./R_ch.sv"
`include "./DefaultSlave.sv"

module AXI (
    input ACLK,
    input ARESETn,
    inf_Master.AXI2Min axi2m0_i,
    inf_Master.AXI2Mout axi2m0_o,
    inf_Master.AXI2Min axi2m1_i,
    inf_Master.AXI2Mout axi2m1_o,
    inf_Master.AXI2Min axi2m2_i,
    inf_Master.AXI2Mout axi2m2_o,
    inf_Slave.AXI2Sin axi2s0_i,
    inf_Slave.AXI2Sout axi2s0_o,
    inf_Slave.AXI2Sin axi2s1_i,
    inf_Slave.AXI2Sout axi2s1_o,
    inf_Slave.AXI2Sin axi2s2_i,
    inf_Slave.AXI2Sout axi2s2_o,
    inf_Slave.AXI2Sin axi2s3_i,
    inf_Slave.AXI2Sout axi2s3_o,
    inf_Slave.AXI2Sin axi2s4_i,
    inf_Slave.AXI2Sout axi2s4_o,
    inf_Slave.AXI2Sin axi2s5_i,
    inf_Slave.AXI2Sout axi2s5_o,
    inf_Slave.AXI2Sin axi2s6_i,
    inf_Slave.AXI2Sout axi2s6_o
);
  //---------- you should put your design here ----------//

  logic [`AXI_MASTER_BITS-1:0] MASTER;
  // default Slave
  logic [`AXI_IDS_BITS  -1:0] ARID_SD;
  logic [`AXI_ADDR_BITS -1:0] ARADDR_SD;
  logic [`AXI_LEN_BITS  -1:0] ARLEN_SD;
  logic [`AXI_SIZE_BITS -1:0] ARSIZE_SD;
  logic [`AXI_BURST_BITS-1:0] ARBURST_SD;
  logic ARVALID_SD;
  logic ARREADY_SD;
  logic [`AXI_IDS_BITS  -1:0] AWID_SD;
  logic [`AXI_ADDR_BITS -1:0] AWADDR_SD;
  logic [`AXI_LEN_BITS  -1:0] AWLEN_SD;
  logic [`AXI_SIZE_BITS -1:0] AWSIZE_SD;
  logic [`AXI_BURST_BITS-1:0] AWBURST_SD;
  logic AWVALID_SD;
  logic AWREADY_SD;
  logic [`AXI_DATA_BITS-1:0] WDATA_SD;
  logic [`AXI_STRB_BITS-1:0] WSTRB_SD;
  logic WLAST_SD;
  logic WVALID_SD;
  logic WREADY_SD;
  logic [`AXI_IDS_BITS -1:0] BID_SD;
  logic [`AXI_RESP_BITS-1:0] BRESP_SD;
  logic BVALID_SD;
  logic BREADY_SD;
  logic [`AXI_IDS_BITS -1:0] RID_SD;
  logic [`AXI_DATA_BITS-1:0] RDATA_SD;
  logic [`AXI_RESP_BITS-1:0] RRESP_SD;
  logic RLAST_SD;
  logic RVALID_SD;
  logic RREADY_SD;

  AR_ch i_ar (
      .clk       (ACLK),
      .rst       (ARESETn),
      // M0
      .id_m0_i   (axi2m0_i.arid),
      .addr_m0_i (axi2m0_i.araddr),
      .len_m0_i  (axi2m0_i.arlen),
      .size_m0_i (axi2m0_i.arsize),
      .burst_m0_i(axi2m0_i.arburst),
      .valid_m0_i(axi2m0_i.arvalid),
      .ready_m0_o(axi2m0_o.arready),
      // M1
      .id_m1_i   (axi2m1_i.arid),
      .addr_m1_i (axi2m1_i.araddr),
      .len_m1_i  (axi2m1_i.arlen),
      .size_m1_i (axi2m1_i.arsize),
      .burst_m1_i(axi2m1_i.arburst),
      .valid_m1_i(axi2m1_i.arvalid),
      .ready_m1_o(axi2m1_o.arready),
      // M2
      .id_m2_i   (axi2m2_i.arid),
      .addr_m2_i (axi2m2_i.araddr),
      .len_m2_i  (axi2m2_i.arlen),
      .size_m2_i (axi2m2_i.arsize),
      .burst_m2_i(axi2m2_i.arburst),
      .valid_m2_i(axi2m2_i.arvalid),
      .ready_m2_o(axi2m2_o.arready),
      // S0
      .id_s0_o   (axi2s0_o.arid),
      .addr_s0_o (axi2s0_o.araddr),
      .len_s0_o  (axi2s0_o.arlen),
      .size_s0_o (axi2s0_o.arsize),
      .burst_s0_o(axi2s0_o.arburst),
      .valid_s0_o(axi2s0_o.arvalid),
      .ready_s0_i(axi2s0_i.arready),
      // S1
      .id_s1_o   (axi2s1_o.arid),
      .addr_s1_o (axi2s1_o.araddr),
      .len_s1_o  (axi2s1_o.arlen),
      .size_s1_o (axi2s1_o.arsize),
      .burst_s1_o(axi2s1_o.arburst),
      .valid_s1_o(axi2s1_o.arvalid),
      .ready_s1_i(axi2s1_i.arready),
      // S2
      .id_s2_o   (axi2s2_o.arid),
      .addr_s2_o (axi2s2_o.araddr),
      .len_s2_o  (axi2s2_o.arlen),
      .size_s2_o (axi2s2_o.arsize),
      .burst_s2_o(axi2s2_o.arburst),
      .valid_s2_o(axi2s2_o.arvalid),
      .ready_s2_i(axi2s2_i.arready),
      // S3
      .id_s3_o   (axi2s3_o.arid),
      .addr_s3_o (axi2s3_o.araddr),
      .len_s3_o  (axi2s3_o.arlen),
      .size_s3_o (axi2s3_o.arsize),
      .burst_s3_o(axi2s3_o.arburst),
      .valid_s3_o(axi2s3_o.arvalid),
      .ready_s3_i(axi2s3_i.arready),
      // S4
      .id_s4_o   (axi2s4_o.arid),
      .addr_s4_o (axi2s4_o.araddr),
      .len_s4_o  (axi2s4_o.arlen),
      .size_s4_o (axi2s4_o.arsize),
      .burst_s4_o(axi2s4_o.arburst),
      .valid_s4_o(axi2s4_o.arvalid),
      .ready_s4_i(axi2s4_i.arready),
      // S5
      .id_s5_o   (axi2s5_o.arid),
      .addr_s5_o (axi2s5_o.araddr),
      .len_s5_o  (axi2s5_o.arlen),
      .size_s5_o (axi2s5_o.arsize),
      .burst_s5_o(axi2s5_o.arburst),
      .valid_s5_o(axi2s5_o.arvalid),
      .ready_s5_i(axi2s5_i.arready),
      // S6
      .id_s6_o   (axi2s6_o.arid),
      .addr_s6_o (axi2s6_o.araddr),
      .len_s6_o  (axi2s6_o.arlen),
      .size_s6_o (axi2s6_o.arsize),
      .burst_s6_o(axi2s6_o.arburst),
      .valid_s6_o(axi2s6_o.arvalid),
      .ready_s6_i(axi2s6_i.arready),
      // SD
      .id_sd_o   (ARID_SD),
      .addr_sd_o (ARADDR_SD),
      .len_sd_o  (ARLEN_SD),
      .size_sd_o (ARSIZE_SD),
      .burst_sd_o(ARBURST_SD),
      .valid_sd_o(ARVALID_SD),
      .ready_sd_i(ARREADY_SD)
  );

  R_ch i_r (
      .clk       (ACLK),
      .rst       (ARESETn),
      // M0
      .id_m0_o   (axi2m0_o.rid),
      .data_m0_o (axi2m0_o.rdata),
      .resp_m0_o (axi2m0_o.rresp),
      .last_m0_o (axi2m0_o.rlast),
      .valid_m0_o(axi2m0_o.rvalid),
      .ready_m0_i(axi2m0_i.rready),
      // M1
      .id_m1_o   (axi2m1_o.rid),
      .data_m1_o (axi2m1_o.rdata),
      .resp_m1_o (axi2m1_o.rresp),
      .last_m1_o (axi2m1_o.rlast),
      .valid_m1_o(axi2m1_o.rvalid),
      .ready_m1_i(axi2m1_i.rready),
      // M2
      .id_m2_o   (axi2m2_o.rid),
      .data_m2_o (axi2m2_o.rdata),
      .resp_m2_o (axi2m2_o.rresp),
      .last_m2_o (axi2m2_o.rlast),
      .valid_m2_o(axi2m2_o.rvalid),
      .ready_m2_i(axi2m2_i.rready),
      // S0
      .id_s0_i   (axi2s0_i.rid),
      .data_s0_i (axi2s0_i.rdata),
      .resp_s0_i (axi2s0_i.rresp),
      .last_s0_i (axi2s0_i.rlast),
      .valid_s0_i(axi2s0_i.rvalid),
      .ready_s0_o(axi2s0_o.rready),
      // S1
      .id_s1_i   (axi2s1_i.rid),
      .data_s1_i (axi2s1_i.rdata),
      .resp_s1_i (axi2s1_i.rresp),
      .last_s1_i (axi2s1_i.rlast),
      .valid_s1_i(axi2s1_i.rvalid),
      .ready_s1_o(axi2s1_o.rready),
      // S2
      .id_s2_i   (axi2s2_i.rid),
      .data_s2_i (axi2s2_i.rdata),
      .resp_s2_i (axi2s2_i.rresp),
      .last_s2_i (axi2s2_i.rlast),
      .valid_s2_i(axi2s2_i.rvalid),
      .ready_s2_o(axi2s2_o.rready),
      // S3
      .id_s3_i   (axi2s3_i.rid),
      .data_s3_i (axi2s3_i.rdata),
      .resp_s3_i (axi2s3_i.rresp),
      .last_s3_i (axi2s3_i.rlast),
      .valid_s3_i(axi2s3_i.rvalid),
      .ready_s3_o(axi2s3_o.rready),
      // S4
      .id_s4_i   (axi2s4_i.rid),
      .data_s4_i (axi2s4_i.rdata),
      .resp_s4_i (axi2s4_i.rresp),
      .last_s4_i (axi2s4_i.rlast),
      .valid_s4_i(axi2s4_i.rvalid),
      .ready_s4_o(axi2s4_o.rready),
      // S5
      .id_s5_i   (axi2s5_i.rid),
      .data_s5_i (axi2s5_i.rdata),
      .resp_s5_i (axi2s5_i.rresp),
      .last_s5_i (axi2s5_i.rlast),
      .valid_s5_i(axi2s5_i.rvalid),
      .ready_s5_o(axi2s5_o.rready),
      // S6
      .id_s6_i   (axi2s6_i.rid),
      .data_s6_i (axi2s6_i.rdata),
      .resp_s6_i (axi2s6_i.rresp),
      .last_s6_i (axi2s6_i.rlast),
      .valid_s6_i(axi2s6_i.rvalid),
      .ready_s6_o(axi2s6_o.rready),
      // SD
      .id_sd_i   (RID_SD),
      .data_sd_i (RDATA_SD),
      .resp_sd_i (RRESP_SD),
      .last_sd_i (RLAST_SD),
      .valid_sd_i(RVALID_SD),
      .ready_sd_o(RREADY_SD)
  );

  AW_ch i_aw (
      .clk       (ACLK),
      .rst       (ARESETn),
      // M1
      .id_m1_i   (axi2m1_i.awid),
      .addr_m1_i (axi2m1_i.awaddr),
      .len_m1_i  (axi2m1_i.awlen),
      .size_m1_i (axi2m1_i.awsize),
      .burst_m1_i(axi2m1_i.awburst),
      .valid_m1_i(axi2m1_i.awvalid),
      .ready_m1_o(axi2m1_o.awready),
      // M2
      .id_m2_i   (axi2m2_i.awid),
      .addr_m2_i (axi2m2_i.awaddr),
      .len_m2_i  (axi2m2_i.awlen),
      .size_m2_i (axi2m2_i.awsize),
      .burst_m2_i(axi2m2_i.awburst),
      .valid_m2_i(axi2m2_i.awvalid),
      .ready_m2_o(axi2m2_o.awready),
      // S0
      .id_s0_o   (axi2s0_o.awid),
      .addr_s0_o (axi2s0_o.awaddr),
      .len_s0_o  (axi2s0_o.awlen),
      .size_s0_o (axi2s0_o.awsize),
      .burst_s0_o(axi2s0_o.awburst),
      .valid_s0_o(axi2s0_o.awvalid),
      .ready_s0_i(axi2s0_i.awready),
      // S1
      .id_s1_o   (axi2s1_o.awid),
      .addr_s1_o (axi2s1_o.awaddr),
      .len_s1_o  (axi2s1_o.awlen),
      .size_s1_o (axi2s1_o.awsize),
      .burst_s1_o(axi2s1_o.awburst),
      .valid_s1_o(axi2s1_o.awvalid),
      .ready_s1_i(axi2s1_i.awready),
      // S2
      .id_s2_o   (axi2s2_o.awid),
      .addr_s2_o (axi2s2_o.awaddr),
      .len_s2_o  (axi2s2_o.awlen),
      .size_s2_o (axi2s2_o.awsize),
      .burst_s2_o(axi2s2_o.awburst),
      .valid_s2_o(axi2s2_o.awvalid),
      .ready_s2_i(axi2s2_i.awready),
      // S3
      .id_s3_o   (axi2s3_o.awid),
      .addr_s3_o (axi2s3_o.awaddr),
      .len_s3_o  (axi2s3_o.awlen),
      .size_s3_o (axi2s3_o.awsize),
      .burst_s3_o(axi2s3_o.awburst),
      .valid_s3_o(axi2s3_o.awvalid),
      .ready_s3_i(axi2s3_i.awready),
      // S4
      .id_s4_o   (axi2s4_o.awid),
      .addr_s4_o (axi2s4_o.awaddr),
      .len_s4_o  (axi2s4_o.awlen),
      .size_s4_o (axi2s4_o.awsize),
      .burst_s4_o(axi2s4_o.awburst),
      .valid_s4_o(axi2s4_o.awvalid),
      .ready_s4_i(axi2s4_i.awready),
      // S5
      .id_s5_o   (axi2s5_o.awid),
      .addr_s5_o (axi2s5_o.awaddr),
      .len_s5_o  (axi2s5_o.awlen),
      .size_s5_o (axi2s5_o.awsize),
      .burst_s5_o(axi2s5_o.awburst),
      .valid_s5_o(axi2s5_o.awvalid),
      .ready_s5_i(axi2s5_i.awready),
      // S6
      .id_s6_o   (axi2s6_o.awid),
      .addr_s6_o (axi2s6_o.awaddr),
      .len_s6_o  (axi2s6_o.awlen),
      .size_s6_o (axi2s6_o.awsize),
      .burst_s6_o(axi2s6_o.awburst),
      .valid_s6_o(axi2s6_o.awvalid),
      .ready_s6_i(axi2s6_i.awready),
      // SD
      .id_sd_o   (AWID_SD),
      .addr_sd_o (AWADDR_SD),
      .len_sd_o  (AWLEN_SD),
      .size_sd_o (AWSIZE_SD),
      .burst_sd_o(AWBURST_SD),
      .valid_sd_o(AWVALID_SD),
      .ready_sd_i(AWREADY_SD)
  );

  W_ch i_w (
      .clk       (ACLK),
      .rst       (ARESETn),
      // M1
      .data_m1_i (axi2m1_i.wdata),
      .strb_m1_i (axi2m1_i.wstrb),
      .last_m1_i (axi2m1_i.wlast),
      .valid_m1_i(axi2m1_i.wvalid),
      .ready_m1_o(axi2m1_o.wready),
      // M2
      .data_m2_i (axi2m2_i.wdata),
      .strb_m2_i (axi2m2_i.wstrb),
      .last_m2_i (axi2m2_i.wlast),
      .valid_m2_i(axi2m2_i.wvalid),
      .ready_m2_o(axi2m2_o.wready),
      // S0
      .data_s0_o (axi2s0_o.wdata),
      .strb_s0_o (axi2s0_o.wstrb),
      .last_s0_o (axi2s0_o.wlast),
      .valid_s0_o(axi2s0_o.wvalid),
      .ready_s0_i(axi2s0_i.wready),
      // S1
      .data_s1_o (axi2s1_o.wdata),
      .strb_s1_o (axi2s1_o.wstrb),
      .last_s1_o (axi2s1_o.wlast),
      .valid_s1_o(axi2s1_o.wvalid),
      .ready_s1_i(axi2s1_i.wready),
      // S2
      .data_s2_o (axi2s2_o.wdata),
      .strb_s2_o (axi2s2_o.wstrb),
      .last_s2_o (axi2s2_o.wlast),
      .valid_s2_o(axi2s2_o.wvalid),
      .ready_s2_i(axi2s2_i.wready),
      // S3
      .data_s3_o (axi2s3_o.wdata),
      .strb_s3_o (axi2s3_o.wstrb),
      .last_s3_o (axi2s3_o.wlast),
      .valid_s3_o(axi2s3_o.wvalid),
      .ready_s3_i(axi2s3_i.wready),
      // s4
      .data_s4_o (axi2s4_o.wdata),
      .strb_s4_o (axi2s4_o.wstrb),
      .last_s4_o (axi2s4_o.wlast),
      .valid_s4_o(axi2s4_o.wvalid),
      .ready_s4_i(axi2s4_i.wready),
      // s5
      .data_s5_o (axi2s5_o.wdata),
      .strb_s5_o (axi2s5_o.wstrb),
      .last_s5_o (axi2s5_o.wlast),
      .valid_s5_o(axi2s5_o.wvalid),
      .ready_s5_i(axi2s5_i.wready),
      // s6
      .data_s6_o (axi2s6_o.wdata),
      .strb_s6_o (axi2s6_o.wstrb),
      .last_s6_o (axi2s6_o.wlast),
      .valid_s6_o(axi2s6_o.wvalid),
      .ready_s6_i(axi2s6_i.wready),
      // SD
      .data_sd_o (WDATA_SD),
      .strb_sd_o (WSTRB_SD),
      .last_sd_o (WLAST_SD),
      .valid_sd_o(WVALID_SD),
      .ready_sd_i(WREADY_SD),

      .awvalid_s0_i(axi2s0_o.awvalid),
      .awvalid_s1_i(axi2s1_o.awvalid),
      .awvalid_s2_i(axi2s2_o.awvalid),
      .awvalid_s3_i(axi2s3_o.awvalid),
      .awvalid_s4_i(axi2s4_o.awvalid),
      .awvalid_s5_i(axi2s5_o.awvalid),
      .awvalid_s6_i(axi2s6_o.awvalid),
      .awvalid_sd_i(AWVALID_SD)
  );

  B_ch i_b (
      .clk       (ACLK),
      .rst       (ARESETn),
      // M1
      .id_m1_o   (axi2m1_o.bid),
      .resp_m1_o (axi2m1_o.bresp),
      .valid_m1_o(axi2m1_o.bvalid),
      .ready_m1_i(axi2m1_i.bready),
      // M2
      .id_m2_o   (axi2m2_o.bid),
      .resp_m2_o (axi2m2_o.bresp),
      .valid_m2_o(axi2m2_o.bvalid),
      .ready_m2_i(axi2m2_i.bready),
      // S0
      .ids_s0_i  (axi2s0_i.bid),
      .resp_s0_i (axi2s0_i.bresp),
      .valid_s0_i(axi2s0_i.bvalid),
      .ready_s0_o(axi2s0_o.bready),
      // S1
      .ids_s1_i  (axi2s1_i.bid),
      .resp_s1_i (axi2s1_i.bresp),
      .valid_s1_i(axi2s1_i.bvalid),
      .ready_s1_o(axi2s1_o.bready),
      // S2
      .ids_s2_i  (axi2s2_i.bid),
      .resp_s2_i (axi2s2_i.bresp),
      .valid_s2_i(axi2s2_i.bvalid),
      .ready_s2_o(axi2s2_o.bready),
      // S3
      .ids_s3_i  (axi2s3_i.bid),
      .resp_s3_i (axi2s3_i.bresp),
      .valid_s3_i(axi2s3_i.bvalid),
      .ready_s3_o(axi2s3_o.bready),
      // S4
      .ids_s4_i  (axi2s4_i.bid),
      .resp_s4_i (axi2s4_i.bresp),
      .valid_s4_i(axi2s4_i.bvalid),
      .ready_s4_o(axi2s4_o.bready),
      // S5
      .ids_s5_i  (axi2s5_i.bid),
      .resp_s5_i (axi2s5_i.bresp),
      .valid_s5_i(axi2s5_i.bvalid),
      .ready_s5_o(axi2s5_o.bready),
      // S6
      .ids_s6_i  (axi2s6_i.bid),
      .resp_s6_i (axi2s6_i.bresp),
      .valid_s6_i(axi2s6_i.bvalid),
      .ready_s6_o(axi2s6_o.bready),
      // SD
      .ids_sd_i  (BID_SD),
      .resp_sd_i (BRESP_SD),
      .valid_sd_i(BVALID_SD),
      .ready_sd_o(BREADY_SD)
  );

  DefaultSlave i_slave (
      .clk      (ACLK),
      .rst      (ARESETn),
      .awid_i   (AWID_SD),
      .awaddr_i (AWADDR_SD),
      .awlen_i  (AWLEN_SD),
      .awsize_i (AWSIZE_SD),
      .awburst_i(AWBURST_SD),
      .awvalid_i(AWVALID_SD),
      .awready_o(AWREADY_SD),
      .wdata_i  (WDATA_SD),
      .wstrb_i  (WSTRB_SD),
      .wlast_i  (WLAST_SD),
      .wvalid_i (WVALID_SD),
      .wready_o (WREADY_SD),
      .bid_o    (BID_SD),
      .bresp_o  (BRESP_SD),
      .bvalid_o (BVALID_SD),
      .bready_i (BREADY_SD),
      .arid_i   (ARID_SD),
      .araddr_i (ARADDR_SD),
      .arlen_i  (ARLEN_SD),
      .arsize_i (ARSIZE_SD),
      .arburst_i(ARBURST_SD),
      .arvalid_i(ARVALID_SD),
      .arready_o(ARREADY_SD),
      .rid_o    (RID_SD),
      .rdata_o  (RDATA_SD),
      .rresp_o  (RRESP_SD),
      .rlast_o  (RLAST_SD),
      .rvalid_o (RVALID_SD),
      .rready_i (RREADY_SD)
  );

endmodule
