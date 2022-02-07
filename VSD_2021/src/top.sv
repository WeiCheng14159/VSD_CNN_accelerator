`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Slave.sv"
`include "./Interface/inf_Master.sv"
`include "./AXI/AXI.sv"
`include "./CPU_wrapper.sv"
`include "./SRAM_wrapper.sv"
`include "./ROM_wrapper.sv"
`include "./SCtrl_wrapper.sv"
`include "./DRAM_wrapper.sv"
`include "./DMA.sv"
`include "./EPU_wrapper.sv"

module top (
    input                          clk,
    rst,
    input        [`DATA_BITS -1:0] ROM_out,
    output logic                   ROM_read,
    output logic                   ROM_enable,
    output logic [`ADDR_BITS-21:0] ROM_address,

    input                    sensor_ready,
    input  [`DATA_BITS -1:0] sensor_out,
    output                   sensor_en,

    input        [`DATA_BITS -1:0] DRAM_Q,
    input                          DRAM_valid,
    output logic                   DRAM_CSn,
    output logic [`WEB_BITS  -1:0] DRAM_WEn,
    output logic                   DRAM_RASn,
    output logic                   DRAM_CASn,
    output logic [           10:0] DRAM_A,
    output logic [`DATA_BITS -1:0] DRAM_D
);

  inf_Master master0 ();
  inf_Master master1 ();
  inf_Master master2 ();
  inf_Slave slave0 ();
  inf_Slave slave1 ();
  inf_Slave slave2 ();
  inf_Slave slave3 ();
  inf_Slave slave4 ();
  inf_Slave slave5 ();
  inf_Slave slave6 ();

  // interrupt
  logic [`INT_BITS-1:0] interrupt;
  // logic int_taken;
  logic int_sctrl;
  logic [1:0] int_dma;
  logic int_epu;
  assign interrupt = {int_epu, int_sctrl, int_dma};

  logic latch_rst;
  always_ff @(posedge clk or posedge rst) begin
    latch_rst <= rst ? rst : rst;
  end

  AXI AXI (
      .ACLK    (clk),
      .ARESETn (~latch_rst),
      .axi2m0_i(master0.AXI2Min),
      .axi2m0_o(master0.AXI2Mout),
      .axi2m1_i(master1.AXI2Min),
      .axi2m1_o(master1.AXI2Mout),
      .axi2m2_i(master2.AXI2Min),
      .axi2m2_o(master2.AXI2Mout),
      .axi2s0_i(slave0.AXI2Sin),
      .axi2s0_o(slave0.AXI2Sout),
      .axi2s1_i(slave1.AXI2Sin),
      .axi2s1_o(slave1.AXI2Sout),
      .axi2s2_i(slave2.AXI2Sin),
      .axi2s2_o(slave2.AXI2Sout),
      .axi2s3_i(slave3.AXI2Sin),
      .axi2s3_o(slave3.AXI2Sout),
      .axi2s4_i(slave4.AXI2Sin),
      .axi2s4_o(slave4.AXI2Sout),
      .axi2s5_i(slave5.AXI2Sin),
      .axi2s5_o(slave5.AXI2Sout),
      .axi2s6_i(slave6.AXI2Sin),
      .axi2s6_o(slave6.AXI2Sout)

  );

  CPU_wrapper cpu_wrapper (
      .clk        (clk),
      .rst        (~latch_rst),
      .interrupt_i(interrupt),
      .m02axi_i   (master0.M2AXIin),
      .m02axi_o   (master0.M2AXIout),
      .m12axi_i   (master1.M2AXIin),
      .m12axi_o   (master1.M2AXIout)
  );

  ROM_wrapper rom_wrapper (
      .clk       (clk),
      .rst       (~latch_rst),
      .s2axi_i   (slave0.S2AXIin),
      .s2axi_o   (slave0.S2AXIout),
      .ROM_out_i (ROM_out),
      .ROM_en_o  (ROM_enable),
      .ROM_read_o(ROM_read),
      .ROM_addr_o(ROM_address)
  );

  SRAM_wrapper IM1 (
      .clk    (clk),
      .rst    (~latch_rst),
      .s2axi_i(slave1.S2AXIin),
      .s2axi_o(slave1.S2AXIout)
  );

  SRAM_wrapper DM1 (
      .clk    (clk),
      .rst    (~latch_rst),
      .s2axi_i(slave2.S2AXIin),
      .s2axi_o(slave2.S2AXIout)
  );

  SCtrl_wrapper sctrl_wrapper (
      .clk           (clk),
      .rst           (~latch_rst),
      .s2axi_i       (slave3.S2AXIin),
      .s2axi_o       (slave3.S2AXIout),
      .sensor_ready_i(sensor_ready),
      .sensor_out_i  (sensor_out),
      .sensor_en_o   (sensor_en),
      .sctrl_int_o   (int_sctrl)
  );

  DRAM_wrapper dram_wrapper (
      .clk         (clk),
      .rst         (~latch_rst),
      .s2axi_i     (slave4.S2AXIin),
      .s2axi_o     (slave4.S2AXIout),
      .DRAM_Q_i    (DRAM_Q),
      .DRAM_valid_i(DRAM_valid),
      .DRAM_CSn_o  (DRAM_CSn),
      .DRAM_WEn_o  (DRAM_WEn),
      .DRAM_RASn_o (DRAM_RASn),
      .DRAM_CASn_o (DRAM_CASn),
      .DRAM_A_o    (DRAM_A),
      .DRAM_D_o    (DRAM_D)
  );

  DMA i_dma (
      .clk    (clk),
      .rst    (latch_rst),
      .m2axi_i(master2.M2AXIin),
      .m2axi_o(master2.M2AXIout),
      .s2axi_i(slave5.S2AXIin),
      .s2axi_o(slave5.S2AXIout),
      .int_o  (int_dma)
  );

  EPU_wrapper epu_wrapper (
      .clk     (clk),
      .rst     (latch_rst),
      .s2axi_i (slave6.S2AXIin),
      .s2axi_o (slave6.S2AXIout),
      .epuint_o(int_epu)
  );

endmodule
