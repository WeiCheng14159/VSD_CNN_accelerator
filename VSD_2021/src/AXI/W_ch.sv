`include "../../include/AXI_define.svh"

module W_ch (
    input clk, rst,
    // M1
    input        [`AXI_DATA_BITS-1:0] wdata_m1_i,
    input        [`AXI_STRB_BITS-1:0] wstrb_m1_i,
    input                             wlast_m1_i,
    input                             wvalid_m1_i,
    output logic                      wready_m1_o,
    // M2
    input        [`AXI_DATA_BITS-1:0] wdata_m2_i,
    input        [`AXI_STRB_BITS-1:0] wstrb_m2_i,
    input                             wlast_m2_i,
    input                             wvalid_m2_i,
    output logic                      wready_m2_o,
    // S0
    output logic [`AXI_DATA_BITS-1:0] wdata_s0_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s0_o,
    output logic                      wlast_s0_o,
    output logic                      wvalid_s0_o,
    input                             wready_s0_i,
    // S1
    output logic [`AXI_DATA_BITS-1:0] wdata_s1_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s1_o,
    output logic                      wlast_s1_o,
    output logic                      wvalid_s1_o,
    input                             wready_s1_i,
    // S2
    output logic [`AXI_DATA_BITS-1:0] wdata_s2_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s2_o,
    output logic                      wlast_s2_o,
    output logic                      wvalid_s2_o,
    input                             wready_s2_i,
    // S3
    output logic [`AXI_DATA_BITS-1:0] wdata_s3_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s3_o,
    output logic                      wlast_s3_o,
    output logic                      wvalid_s3_o,
    input                             wready_s3_i,
    // S4
    output logic [`AXI_DATA_BITS-1:0] wdata_s4_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s4_o,
    output logic                      wlast_s4_o,
    output logic                      wvalid_s4_o,
    input                             wready_s4_i,
    // S5
    output logic [`AXI_DATA_BITS-1:0] wdata_s5_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_s5_o,
    output logic                      wlast_s5_o,
    output logic                      wvalid_s5_o,
    input                             wready_s5_i,
    // SD
    output logic [`AXI_DATA_BITS-1:0] wdata_sd_o,
    output logic [`AXI_STRB_BITS-1:0] wstrb_sd_o,
    output logic                      wlast_sd_o,
    output logic                      wvalid_sd_o,
    input                             wready_sd_i,

    input                             awvalid_m1_i,
    input                             awvalid_m2_i,
    input                             awvalid_s0_i,
    input                             awvalid_s1_i,
    input                             awvalid_s2_i,
    input                             awvalid_s3_i,
    input                             awvalid_s4_i,
    input                             awvalid_s5_i,
    input                             awvalid_sd_i
);
    logic free;
    logic [`AXI_MASTER_BITS-1:0] master;
    logic [`AXI_DATA_BITS  -1:0] data_m;
    logic [`AXI_STRB_BITS  -1:0] strb_m;
    logic last_m, valid_m;
    logic [`AXI_MASTER_NUM-1:0] validin_m;
    logic ready_s;
    logic [`AXI_SLAVE_BITS-1:0] awvalidin_s, validout_s;
    logic [`AXI_SLAVE_BITS-1:0] sel, slave, lockaw_s, freeaw_s;
    integer i;

// {{{ Master
    // M0
    logic [`AXI_DATA_BITS-1:0] wdata_m0;
    logic [`AXI_STRB_BITS-1:0] wstrb_m0;
    logic wlast_m0, wvalid_m0, wready_m0;
    assign wdata_m0  = `AXI_DATA_BITS'h0;
    assign wstrb_m0  = `AXI_STRB_BITS'h0;
    assign wlast_m0  = 1'b0;
    assign wvalid_m0 = 1'b0;
    assign wready_m0 = 1'b0;

    assign wready_m1_o = ready_s & wvalid_m1_i;
    assign wready_m2_o = ready_s & wvalid_m2_i;
	assign validin_m = {wvalid_m2_i, wvalid_m1_i, wvalid_m0};


    // always_comb begin
    //     case (master)
    //         `AXI_MASTER0 : {data_m, strb_m, last_m, valid_m} = {wdata_m0, wstrb_m0, wlast_m0, wvalid_m0};
    //         `AXI_MASTER1 : {data_m, strb_m, last_m, valid_m} = {wdata_m1_i, wstrb_m1_i, wlast_m1_i, wvalid_m1_i};
    //         `AXI_MASTER2 : {data_m, strb_m, last_m, valid_m} = {wdata_m2_i, wstrb_m2_i, wlast_m2_i, wvalid_m2_i};
    //         default      : {data_m, strb_m, last_m, valid_m} = {`AXI_DATA_BITS'h0, `AXI_STRB_BITS'h0, 1'b0, 1'b0}; 
    //     endcase
    // end

	always_comb begin
		case(validin_m)
			3'b001  : {data_m, strb_m, last_m, valid_m} = {wdata_m0, wstrb_m0, wlast_m0, wvalid_m0};
			3'b010  : {data_m, strb_m, last_m, valid_m} = {wdata_m1_i, wstrb_m1_i, wlast_m1_i, wvalid_m1_i};
			3'b100  : {data_m, strb_m, last_m, valid_m} = {wdata_m2_i, wstrb_m2_i, wlast_m2_i, wvalid_m2_i};
			default : {data_m, strb_m, last_m, valid_m} = {`AXI_DATA_BITS'h0, `AXI_STRB_BITS'h0, 1'b0, 1'b0};
		endcase
	end
// }}}
// {{{ Slave
    assign awvalidin_s = {awvalid_sd_i,
                          awvalid_s5_i,
                          awvalid_s4_i,
                          awvalid_s3_i,
                          awvalid_s2_i,
                          awvalid_s1_i,
                          awvalid_s0_i};
    assign slave = lockaw_s | awvalidin_s;
    assign free = valid_m & ready_s & last_m;

    assign freeaw_s = {`AXI_SLAVE_BITS{valid_m}} & {`AXI_SLAVE_BITS{valid_m}} &
                      {wready_sd_i, 
                       wready_s5_i,
                       wready_s4_i,
                       wready_s3_i,
                       wready_s2_i,
                       wready_s1_i,
                       wready_s0_i};

    always_comb begin
        case (slave)
            `AXI_SLAVE0        : ready_s = wready_s0_i;	
            `AXI_SLAVE1        : ready_s = wready_s1_i;
            `AXI_SLAVE2        : ready_s = wready_s2_i;
            `AXI_SLAVE3        : ready_s = wready_s3_i;
            `AXI_SLAVE4        : ready_s = wready_s4_i;
            `AXI_DEFAULT_SLAVE : ready_s = wready_sd_i;
            default            : ready_s = 1'b1;
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            lockaw_s <= `AXI_SLAVE_BITS'b0;
        else begin
            for (i = 0; i < `AXI_SLAVE_BITS; i = i + 1)
                lockaw_s[i] <=  awvalidin_s[i] ? awvalidin_s[i] : free ? 1'b0 : lockaw_s[i];
        end
    end


    // 
    assign {wvalid_sd_o,
            wvalid_s5_o,
            wvalid_s4_o,
            wvalid_s3_o,
            wvalid_s2_o, 
            wvalid_s1_o, 
            wvalid_s0_o} = validout_s;
    assign validout_s = {`AXI_SLAVE_BITS{valid_m}} & slave;
    // S0
    assign wdata_s0_o = data_m;
    assign wstrb_s0_o = wvalid_s0_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s0_o = last_m;
    // S1
    assign wdata_s1_o = data_m;
    assign wstrb_s1_o = wvalid_s1_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s1_o = last_m;
    // S2
    assign wdata_s2_o = data_m;
    assign wstrb_s2_o = wvalid_s2_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s2_o = last_m;
    // S3
    assign wdata_s3_o = data_m;
    assign wstrb_s3_o = wvalid_s3_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s3_o = last_m;
    // S4
    assign wdata_s4_o = data_m;
    assign wstrb_s4_o = wvalid_s4_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s4_o = last_m;
    // S5
    assign wdata_s5_o = data_m;
    assign wstrb_s5_o = wvalid_s5_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_s5_o = last_m;
    // SD
    assign wdata_sd_o = data_m;
    assign wstrb_sd_o = wvalid_sd_o ? strb_m : `AXI_STRB_BITS'hf;
    assign wlast_sd_o = last_m;
// }}}  
endmodule