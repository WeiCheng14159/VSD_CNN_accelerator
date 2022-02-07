`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Master.sv"
`include "./CPU.sv"
`include "./L1C_inst.sv"
`include "./L1C_data.sv"

module CPU_wrapper (
    input clk,
    rst,
    inf_Master.M2AXIin m02axi_i,
    inf_Master.M2AXIout m02axi_o,
    inf_Master.M2AXIin m12axi_i,
    inf_Master.M2AXIout m12axi_o,
    input [`INT_BITS-1:0] interrupt_i
);

  logic [`TYPE_BITS-1:0] cputype;
  logic [`WEB_BITS -1:0] cpuweb_0;
  logic [`ADDR_BITS-1:0] cpuaddr_0;
  logic [`DATA_BITS-1:0] crdata_0;
  logic [`DATA_BITS-1:0] cpuwdata_0;
  logic cwait_0;
  logic cpureq_0;
  logic cpuread_0, cpuwrite_0;
  // Inst cache to M0
  logic [`ADDR_BITS-1:0] caddr_m0;
  logic [`DATA_BITS-1:0] cwdata_m0;
  logic [`TYPE_BITS-1:0] ctype_m0;
  logic cwrite_m0;
  logic cwreq_m0, crreq_m0;
  logic arlenone_m0;
  // M0 to inst cache
  logic [`DATA_BITS-1:0] rdata_m0;
  logic wait_m0;

  assign cpuwrite_0  = 1'b0;
  assign cpuweb_0    = 4'hf;
  assign cpuwdata_0  = `DATA_BITS'h0;

  assign arlenone_m0 = 1'b0;

  logic [`WEB_BITS -1:0] cpuweb_1;
  logic [`ADDR_BITS-1:0] cpuaddr_1;
  logic [`DATA_BITS-1:0] crdata_1;
  logic [`DATA_BITS-1:0] cpuwdata_1;
  logic cwait_1;
  logic cpureq_1;
  logic cpuread_1, cpuwrite_1;
  // Inst cache to M1
  logic [`ADDR_BITS-1:0] caddr_m1;
  logic [`DATA_BITS-1:0] cwdata_m1;
  logic [`TYPE_BITS-1:0] ctype_m1;
  logic cwrite_m1;
  logic cwreq_m1, crreq_m1;
  logic arlenone_m1;
  // M1 to inst cache
  logic [`DATA_BITS-1:0] rdata_m1;
  logic wait_m1;

  logic latch_rst;
  always_ff @(posedge clk or negedge rst) begin
    latch_rst <= ~rst ? rst : rst;
  end

  CPU i_CPU (
      .clk        (clk),
      .rst        (~latch_rst),
      // Cache     
      .inst_i     (crdata_0),
      .inst_pc_o  (cpuaddr_0),
      .dm_data_i  (crdata_1),
      .dm_addr_o  (cpuaddr_1),
      .dm_data_o  (cpuwdata_1),
      .web_o      (cpuweb_1),
      // L1IC      
      .wait0_i    (cwait_0),
      .req0_o     (cpureq_0),
      .read0_o    (cpuread_0),
      // L1DC      
      .wait1_i    (cwait_1),
      .req1_o     (cpureq_1),
      .read1_o    (cpuread_1),
      .write1_o   (cpuwrite_1),
      .cputype_o  (cputype),
      .interrupt_i(interrupt_i)

  );
  // }}}
  L1C_inst L1CI (
      .clk       (clk),
      .rst       (~rst),
      // Core inputs
      .core_addr (cpuaddr_0),
      .core_req  (cpureq_0),
      .core_write(cpuwrite_0),
      .core_in   (cpuwdata_0),
      .core_type (cputype),
      // Wrapper inputs
      .I_out     (rdata_m0),
      .I_wait    (wait_m0),
      // Core outputs
      .core_out  (crdata_0),
      .core_wait (cwait_0),
      // Wrapper outputs
      // .I_req      (creq_m0   ),

      .I_wreq(cwreq_m0),
      .I_rreq(crreq_m0),

      .I_addr (caddr_m0),
      .I_write(cwrite_m0),
      .I_in   (cwdata_m0),
      .I_type (ctype_m0)
  );
  L1C_data L1CD (
      .clk       (clk),
      .rst       (~rst),
      // Core inputs
      .core_addr (cpuaddr_1),
      .core_req  (cpureq_1),
      .core_write(cpuwrite_1),
      .core_in   (cpuwdata_1),
      .core_type (cputype),
      // Wrapper inputs
      .D_out     (rdata_m1),
      .D_wait    (wait_m1),
      // Core outputs
      .core_out  (crdata_1),
      .core_wait (cwait_1),
      // Wrapper outputs
      // .D_req      (creq_m1   ),
      .D_wreq    (cwreq_m1),
      .D_rreq    (crreq_m1),

      .D_addr    (caddr_m1),
      .D_write   (cwrite_m1),
      .D_in      (cwdata_m1),
      .D_type    (ctype_m1),
      .arlenone_o(arlenone_m1)
  );

  Master M0 (
      .clk       (clk),
      .rst       (rst),
      .m2axi_i   (m02axi_i),
      .m2axi_o   (m02axi_o),
      .arlenone_i(arlenone_m0),
      // .creq_i     (creq_m0    ),
      .cwreq_i   (cwreq_m0),
      .crreq_i   (crreq_m0),

      .cwrite_i (cwrite_m0),
      .cwtype_i (ctype_m0),
      .cdatain_i(cwdata_m0),
      .caddr_i  (caddr_m0),
      .dataout_o(rdata_m0),
      .wait_o   (wait_m0)
  );
  Master M1 (
      .clk       (clk),
      .rst       (rst),
      .m2axi_i   (m12axi_i),
      .m2axi_o   (m12axi_o),
      .arlenone_i(arlenone_m1),
      // .creq_i     (creq_m1    ),
      .cwreq_i   (cwreq_m1),
      .crreq_i   (crreq_m1),

      .cwrite_i (cwrite_m1),
      .cwtype_i (ctype_m1),
      .cdatain_i(cwdata_m1),
      .caddr_i  (caddr_m1),
      .dataout_o(rdata_m1),
      .wait_o   (wait_m1)
  );
endmodule
