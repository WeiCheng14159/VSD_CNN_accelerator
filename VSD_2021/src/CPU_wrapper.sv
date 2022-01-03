`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Master.sv"
`include "./CPU.sv"
`include "./L1C_inst.sv"
`include "./L1C_data.sv"

module CPU_wrapper (
    input clk, rst,
    input int_taken_i,
    inf_Master.M2AXIin  m02axi_i,
    inf_Master.M2AXIout m02axi_o,
    inf_Master.M2AXIin  m12axi_i,
    inf_Master.M2AXIout m12axi_o
);

    logic [`TYPE_BITS-1 :0] cputype;
    logic [`WEB_BITS -1:0] cpuweb_1;
    logic [`ADDR_BITS-1:0] cpuaddr_1;
    logic [`DATA_BITS-1:0] crdata_1;
    logic [`DATA_BITS-1:0] cpuwdata_1;
    logic cwait_1;
    logic cpureq_1;
    logic cpuread_1, cpuwrite_1;
    logic req_read1, req_write1;
    // Inst cache to M0
    logic [`ADDR_BITS-1:0] caddr_m1;
    logic [`DATA_BITS-1:0] cwdata_m1;
    logic [`TYPE_BITS-1:0] ctype_m1;
    logic cwrite_m1;
    logic creq_m1;
    logic sctrl_rd_m1;
    // M0 to inst cache
    logic [`DATA_BITS-1:0] rdata_m1;
    logic wait_m1;

    assign cpuwrite_1  = 1'b0;
    assign cpuweb_1    = 4'hf;
    assign cpuwdata_1  = `DATA_BITS'h0;
    assign req_read1   = cpureq_1 & cpuread_1;
    assign req_write1  = cpureq_1 & cpuwrite_1;
    assign sctrl_rd_m1 = 1'b0;

    logic [`WEB_BITS -1:0] cpuweb_2;
    logic [`ADDR_BITS-1:0] cpuaddr_2;
    logic [`DATA_BITS-1:0] crdata_2;
    logic [`DATA_BITS-1:0] cpuwdata_2;
    logic cwait_2;
    logic cpureq_2;
    logic cpuread_2, cpuwrite_2;
    logic req_read2, req_write2;
    // Inst cache to M1
    logic [`ADDR_BITS-1:0] caddr_m2;
    logic [`DATA_BITS-1:0] cwdata_m2;
    logic [`TYPE_BITS-1:0] ctype_m2;
    logic cwrite_m2;
    logic creq_m2;
    logic sctrl_rd_m2;
    // M1 to inst cache
    logic [`DATA_BITS-1:0] rdata_m2;
    logic wait_m2;

    assign req_read2  = cpureq_2 & cpuread_2;
    assign req_write2 = cpureq_2 & cpuwrite_2;

    logic latch_rst;
    always_ff @(posedge clk or negedge rst) begin
        latch_rst <= ~rst ? rst : rst;
    end

    CPU i_CPU (
        .clk       (clk       ),
        .rst       (~latch_rst),
        // Cache
        .inst_i    (crdata_1  ),
        .inst_pc_o (cpuaddr_1 ),
        .dm_data_i (crdata_2  ),
        .dm_addr_o (cpuaddr_2 ),
        .dm_data_o (cpuwdata_2),
        .web_o     (cpuweb_2  ),
        // L1IC
        .wait1_i  (cwait_1    ),
        .req1_o   (cpureq_1   ),
        .read1_o  (cpuread_1  ),
        // .write1_o (cpuwrite_1 ),
        // L1DC
        .wait2_i  (cwait_2    ),
        .req2_o   (cpureq_2   ),
        .read2_o  (cpuread_2  ),
        .write2_o (cpuwrite_2 ),
        // 2021.11.23
        .cputype_o (cputype   ),
        //
        .int_taken_i (int_taken_i)

    );
    // }}}
    L1C_inst L1CI (
        .clk        (clk       ),
        .rst        (~rst      ),
        // Core inputs
        .core_addr  (cpuaddr_1 ),
        .core_req   (cpureq_1  ),
        .core_write (cpuwrite_1),
        .core_in    (cpuwdata_1),
        .core_type  (cputype   ), 
        // Wrapper inputs
        .I_out      (rdata_m1  ),
        .I_wait     (wait_m1   ),
        // Core outputs
        .core_out   (crdata_1  ),
        .core_wait  (cwait_1   ),
        // Wrapper outputs
        .I_req      (creq_m1   ),
        .I_addr     (caddr_m1  ),
        .I_write    (cwrite_m1 ),
        .I_in       (cwdata_m1 ),
        .I_type     (ctype_m1  )
    );
    L1C_data L1CD (
        .clk        (clk       ),
        .rst        (~rst      ),
        // Core inputs
        .core_addr  (cpuaddr_2 ),
        .core_req   (cpureq_2  ),
        .core_write (cpuwrite_2),
        .core_in    (cpuwdata_2),
        .core_type  (cputype   ), 
        // Wrapper inputs
        .D_out      (rdata_m2  ),
        .D_wait     (wait_m2   ),
        // Core outputs
        .core_out   (crdata_2  ),
        .core_wait  (cwait_2   ),
        // Wrapper outputs
        .D_req      (creq_m2   ),
        .D_addr     (caddr_m2  ),
        .D_write    (cwrite_m2 ),
        .D_in       (cwdata_m2 ),
        .D_type     (ctype_m2  ),

        .sctrl_rd_o (sctrl_rd_m2)
    );

    Master M0 (
        .clk       (clk       ),
        .rst       (rst       ),
        .m2axi_i   (m02axi_i  ),
        .m2axi_o   (m02axi_o  ),
        .creq_i    (creq_m1   ),
        
        .sctrl_rd_i (sctrl_rd_m1),
        .cwrite_i  (cwrite_m1 ),
        .cwtype_i  (ctype_m1  ),
        .cdatain_i (cwdata_m1 ),
        .caddr_i   (caddr_m1  ),
        .dataout_o (rdata_m1  ),
        .wait_o    (wait_m1   )
    );
    Master M1 (
        .clk       (clk       ),
        .rst       (rst       ),
        .m2axi_i   (m12axi_i  ),
        .m2axi_o   (m12axi_o  ),
        .creq_i    (creq_m2   ),
        .sctrl_rd_i (sctrl_rd_m2),
        .cwrite_i  (cwrite_m2 ),
        .cwtype_i  (ctype_m2  ),
        .cdatain_i (cwdata_m2 ),
        .caddr_i   (caddr_m2  ),
        .dataout_o (rdata_m2  ),
        .wait_o    (wait_m2   )
    );

endmodule
