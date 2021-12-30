`include "../include/CPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Slave.sv"
`include "sensor_ctrl.sv"

module SCtrl_wrapper(
    input clk, rst,
	inf_Slave.S2AXIin  s2axi_i,
	inf_Slave.S2AXIout s2axi_o,
    input                         sensor_ready_i,
    input        [`DATA_BITS-1:0] sensor_out_i,
    output logic                  sensor_en_o,
    output logic                  sctrl_int_o
);

	parameter IDLE  = 3'h0,
			  W_CH  = 3'h1,
			  B_CH  = 3'h2,
			  R_CH  = 3'h3;
	logic [2:0] STATE, NEXT;
	// Handshake
	logic awhns, arhns, whns, rhns, bhns;
	logic rdfin, wrfin;
	// Sensor
    logic sctrl_en, sctrl_clear;
    logic [8:0] sensor_addr;
    logic [`DATA_BITS-1:0] sctrl_out;

	//logic [13:0] raddr, waddr;
	logic [`ADDR_BITS     -1:0] addr;
	logic [`AXI_IDS_BITS  -1:0] aids; //arids, awids;
	logic [`AXI_DATA_BITS -1:0] rdata;
	logic [`AXI_LEN_BITS  -1:0] alen; //arlen, awlen;
	logic [`AXI_BURST_BITS-1:0] burst;
	logic rvalid;

	logic [`AXI_LEN_BITS-1:0] cnt;

	// {{{ Handshake
	assign rdfin = s2axi_o.rlast & rhns;
	assign wrfin = s2axi_i.wlast & whns;
	assign awhns = s2axi_i.awvalid & s2axi_o.awready;
	assign arhns = s2axi_i.arvalid & s2axi_o.arready;
	assign whns  = s2axi_i.wvalid  & s2axi_o.wready;
	assign rhns  = s2axi_o.rvalid  & s2axi_i.rready;
	assign bhns  = s2axi_o.bvalid  & s2axi_i.bready;
	// }}}
	// Counter
	always_ff @(posedge clk or negedge rst) begin
		if (~rst)
			cnt <= `AXI_LEN_BITS'h0;	
		else begin
			case (STATE)
				R_CH : cnt <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? cnt + `AXI_LEN_BITS'h1 : cnt;
				W_CH : cnt <= wrfin ? `AXI_LEN_BITS'h0 : whns ? cnt + `AXI_LEN_BITS'h1 : cnt;
			endcase
		end
	end

	// Sample
	always_ff @(posedge clk or negedge rst) begin
		if (~rst) begin
			addr   <= `ADDR_BITS'h0;
			aids   <= `AXI_IDS_BITS'h0;
			alen   <= `AXI_LEN_BITS'h0;
			burst  <= `AXI_BURST_BITS'h0;
			rvalid <= 1'b0;
			//rdata  <= `AXI_DATA_BITS'h0;
		end
		else begin
			addr   <= awhns ? s2axi_i.awaddr  : arhns ? s2axi_i.araddr : addr;
			aids   <= awhns ? s2axi_i.awid    : arhns ? s2axi_i.arid : aids;
			alen   <= awhns ? s2axi_i.awlen   : arhns ? s2axi_i.arlen : alen;
			burst  <= awhns ? s2axi_i.awburst : arhns ? s2axi_i.arburst : burst;
			rvalid <= s2axi_o.rvalid;
			//rdata  <= (s2axi_o.rvalid & ~rvalid) ? sctrl_out : rdata;
		end
	end
// {{{ STATE
	always_ff@(posedge clk or negedge rst) begin
		STATE <= ~rst ? IDLE : NEXT;
	end
	always_comb begin
		case(STATE)
			IDLE    : begin
				case ({awhns, whns, arhns})
					3'b110  : NEXT = B_CH;
					3'b100  : NEXT = W_CH;
					3'b001  : NEXT = R_CH;
					default : NEXT = IDLE;
				endcase
			end
			W_CH    : NEXT = wrfin ? B_CH : W_CH;
			B_CH    : begin
				case ({bhns, awhns, arhns})
					3'b110  : NEXT = W_CH;
					3'b101  : NEXT = R_CH;
					3'b100  : NEXT = IDLE;
					default : NEXT = B_CH;
				endcase
			end
			R_CH    : begin
				case ({rdfin, awhns, arhns})
					3'b110  : NEXT = W_CH;
					3'b101  : NEXT = R_CH;
					3'b100  : NEXT = IDLE;
					default : NEXT = R_CH; 
				endcase
			end
			default : NEXT = STATE;
		endcase
	end
// }}}
// {{{ AXI
	assign s2axi_o.rlast = cnt == alen;
	assign s2axi_o.rresp = `AXI_RESP_OKAY;
	assign s2axi_o.bresp = `AXI_RESP_OKAY;
	assign s2axi_o.rdata = sctrl_out; 
	assign s2axi_o.rid = aids;
	assign s2axi_o.bid = aids;

	always_comb begin
		case (STATE)
			IDLE    : {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {1'b1, ~s2axi_i.awvalid, 1'b0};
            W_CH    : {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b1;
            B_CH    : {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {bhns, 2'b0};
            R_CH    : {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = {rhns, 2'b0};
            default : {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
        endcase
	end
	always_comb begin
		case (STATE)
            B_CH    : {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b1;
			R_CH    : {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b10;
            default : {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;
		endcase
	end
// }}}
	
	always_comb begin
		case (burst)
			default : sensor_addr = addr[2+:9];
		endcase
	end

    always_ff @ (posedge clk or negedge rst) begin
        if (~rst) 
            {sctrl_en, sctrl_clear} <= 2'b0;
        else if (s2axi_i.wvalid) begin
            if (sensor_addr == 9'h40)     sctrl_en    <= s2axi_i.wdata[0];
            else if(sensor_addr == 9'h80) sctrl_clear <= s2axi_i.wdata[0]; 
        end
    end



	sensor_ctrl sensor_ctrl(
	    .clk              (clk              ),
	    .rst              (~rst             ),
	    .sctrl_en         (sctrl_en         ),
	    .sctrl_clear      (sctrl_clear      ),
	    .sctrl_addr       (sensor_addr[5:0] ),
	    .sensor_ready     (sensor_ready_i   ),
	    .sensor_out       (sensor_out_i     ),
	    .sctrl_interrupt  (sctrl_int_o),
	    .sctrl_out        (sctrl_out        ),
	    .sensor_en        (sensor_en_o      )
	);
endmodule
