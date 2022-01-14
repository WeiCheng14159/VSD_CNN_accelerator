`include "../include/EPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Slave.sv"
`include "./Interface/inf_EPUIN.sv"
`include "./Interface/sp_ram_intf.sv"
// `include "./EPU/Input_wrapper.sv"
// `include "./EPU/Output_wrapper.sv"
// `include "./EPU/Bias_wrapper.sv"
// `include "./EPU/Weight_wrapper.sv"
// `include "./EPU/CONV_wrapper.sv"



module EPU_wrapper (
    input clk, rst,
    inf_Slave.S2AXIin  s2axi_i,
    inf_Slave.S2AXIout s2axi_o
    // output logic       epuint_o
);

/* 
    assign s2axi_o.rlast = 1'b1;
    assign s2axi_o.rresp = `AXI_RESP_OKAY;
    assign s2axi_o.bresp = `AXI_RESP_OKAY;
    assign s2axi_o.rdata = `AXI_DATA_BITS'h0; 
    assign s2axi_o.rid   = `AXI_IDS_BITS'h0;
    assign s2axi_o.bid   = `AXI_IDS_BITS'h0;
    assign {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
    assign {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;

*/
    localparam IDLE = 2'h0, R_CH = 2'h1, W_CH = 2'h2, B_CH = 2'h3;
    logic [1:0] STATE, NEXT;
    // Handshake
    logic awhns, arhns, whns, rhns, bhns;
    logic rdfin, wrfin;
    // Sample
    logic [-1:0] addr_r;
    logic [`AXI_IDS_BITS  -1:0] ids_r;
    logic [`AXI_LEN_BITS  -1:0] len_r;
    logic [`AXI_STRB_BITS -1:0] wstrb_r;
    logic [`AXI_BURST_BITS-1:0] burst_r;
    // rlast
    logic [`AXI_LEN_BITS-1:0] cnt_r;
    // SRAM enable
    logic [3:0] enb;
    // 
    inf_EPUIN EPUIN();
    logic [`DATA_BITS-1:0] in_rdata, out_rdata, bias_rdata, weight_rdata;
    logic in_rvalid, out_rvalid, bias_rvalid, weight_rvalid;
    logic in_trans, out_trans;
    logic conv_start, conv_fin;

    // Handshake
    assign EPUIN.rdfin = s2axi_o.rlast & rhns;
    assign EPUIN.wrfin = s2axi_i.wlast & whns;
    assign EPUIN.awhns = s2axi_i.awvalid & s2axi_o.awready;
    assign EPUIN.arhns = s2axi_i.arvalid & s2axi_o.arready;
    assign whns = s2axi_i.wvalid & s2axi_o.wready;
    assign rhns = s2axi_o.rvalid & s2axi_i.rready;
    assign bhns = s2axi_o.bvalid & s2axi_i.bready;

// {{{ Sample
    always_ff @(posedge clk or negedge rst) begin
        if (~rst) begin
            addr_r  <= `AXI_ADDR_BITS'h0;
            ids_r   <= `AXI_IDS_BITS'h0;
            len_r   <= `AXI_LEN_BITS'h0;
            wstrb_r <= `AXI_STRB_BITS'h0;
        end
        else begin
            addr_r  <= arhns ? s2axi_i.araddr  : awhns ? s2axi_i.awaddr : addr_r;
            ids_r   <= arhns ? s2axi_i.arid    : awhns ? s2axi_i.awid   : ids_r;
            len_r   <= arhns ? s2axi_i.arlen   : awhns ? s2axi_i.awlen  : len_r;
            wstrb_r <= awhns ? s2axi_i.wstrb   : wstrb_r;
            burst_r <= awhns ? s2axi_i.awburst : arhns ? s2axi_i.arburst : burst_r;
        end
    end
// }}}

// {{{ STATE
    always_ff@(posedge clk or negedge rst) begin
        STATE <= ~rst ? IDLE : NEXT;
    end
    always_comb begin
        case(STATE)
            IDLE    : begin
                case ({EPUIN.awhns, EPUIN.arhns})
                    2'b10   : NEXT = B_CH;
                    2'b01   : NEXT = R_CH;
                    default : NEXT = IDLE;
                endcase
            end
            R_CH    : NEXT = EPUIN.rdfin ? IDLE : R_CH;
            W_CH    : NEXT = EPUIN.wrfin ? B_CH : W_CH;
            B_CH    : NEXT = bhns        ? IDLE : B_CH;
            default : NEXT = STATE;
        endcase
    end
// }}}

// {{{ Counter
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            cnt_r <= `AXI_LEN_BITS'h0;	
        else begin
            case (STATE)
                R_CH : cnt_r <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? cnt_r + `AXI_LEN_BITS'h1 : cnt_r;
                W_CH : cnt_r <= wrfin ? `AXI_LEN_BITS'h0 : whns ? cnt_r + `AXI_LEN_BITS'h1 : cnt_r;
            endcase
        end
    end
// }}}
// {{{ AXI
    assign s2axi_o.rlast  = cnt_r == len_r;
    assign s2axi_o.rresp  = `AXI_RESP_OKAY;
    assign s2axi_o.bresp  = `AXI_RESP_OKAY;
    assign s2axi_o.rid    = ids_r;
    assign s2axi_o.bid    = ids_r;
    assign s2axi_o.bvalid = STATE == B_CH;
    assign s2axi_o.wready = STATE == W_CH;
    always_comb begin
        case (enb)
            4'b0001 : s2axi_o.rdata = in_rdata;
            4'b0010 : s2axi_o.rdata = out_rdata;
            4'b0100 : s2axi_o.rdata = bias_rdata;
            4'b1000 : s2axi_o.rdata = weight_rdata;
            default : s2axi_o.rdata = `DATA_BITS'h0;
        endcase
    end
    always_comb begin
        s2axi_o.awready = 1'b0;
        s2axi_o.arready = 1'b0;
        case (STATE)
            IDLE : {s2axi_o.awready, s2axi_o.arready} = {1'b1, ~s2axi_i.awvalid};
            R_CH : {s2axi_o.awready, s2axi_o.arready} = {rhns, 1'b0};
            B_CH : {s2axi_o.awready, s2axi_o.arready} = {bhns, 1'b0};
        endcase
    end
    logic r_ch;
    assign r_ch = STATE == R_CH;
    always_comb begin
        case ({r_ch, enb})
            5'b10001 : s2axi_o.rvalid = in_rvalid;
            5'b10010 : s2axi_o.rvalid = out_rvalid;
            5'b10100 : s2axi_o.rvalid = bias_rvalid;
            5'b11000 : s2axi_o.rvalid = weight_rvalid;
            default  : s2axi_o.rvalid = 1'b0;
        endcase
    end

// }}}


// {{{ SRAM
    always_ff @(posedge clk or negedge rst) begin
        if (~rst)               EPUIN.addr <= {`EPU_ADDR_BITS{1'b0}};
        else if (awhns)         EPUIN.addr <= s2axi_i.awaddr;
        else if (arhns)         EPUIN.addr <= s2axi_i.araddr + `EPU_ADDR_BITS'h1;//{{(`EPU_ADDR_BITS-1){1'b0}}, 1'b1};
        else if (wrfin | rdfin) EPUIN.addr <= {`EPU_ADDR_BITS{1'b0}};
        else if (whns | rhns)   EPUIN.addr <= EPUIN.addr + `EPU_ADDR_BITS'h1;//{{(`EPU_ADDR_BITS-1){1'b0}}, 1'b1};
    end

    // Input  : 5000_0000 ~ 5000_ffff
    //          5001_0000 ~ 5fff_ffff
    // Output : 6000_0000 ~ 6000_ffff
    //          6001_0000 ~ 6fff_ffff
    // Bias   : 7000_0000 ~ 73ff_ffff
    // Weight : 7400_0000 ~ 7fff_ffff
    // AP     : 8000_0000 ~ 8fff_ffff

    always_comb begin
        enb = 4'b0;
        if (addr_r > `AXI_ADDR_BITS'h5000_ffff && addr_r < `AXI_ADDR_BITS'h6000_0000)
            enb[0] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h6000_ffff && addr_r < `AXI_ADDR_BITS'h7000_0000)
            enb[1] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h6fff_ffff && addr_r < `AXI_ADDR_BITS'h7400_0000)
            enb[2] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h73ff_ffff && addr_r < `AXI_ADDR_BITS'h8000_0000)
            enb[3] = 1'b1;
        else 
            enb = 4'b0;
    end
    always_comb begin
        case (STATE)
            IDLE    : {EPUIN.OE, EPUIN.CS} = {~s2axi_i.awvalid && arhns, s2axi_i.awvalid || s2axi_i.arvalid};
            R_CH    : {EPUIN.OE, EPUIN.CS} = 2'b11;
            W_CH    : {EPUIN.OE, EPUIN.CS} = 2'b1;
            B_CH    : {EPUIN.OE, EPUIN.CS} = 2'b1;
            default : {EPUIN.OE, EPUIN.CS} = 2'b0;
        endcase
    end

// }}}

// {{{ I/O transpose 
    // Input  : 5000_0000 ~ 5000_ffff  mode (0: input, 1: output)
    // Output : 6000_0000 ~ 6000_ffff  mode (0: output, 1: input)
    // CONV   : 8000_0000 ~ 8fff_ffff  mode (0: idle, 1: activate)

    always_ff @(posedge clk or negedge rst) begin
        if (~rst)
            {in_trans, out_trans, conv_start} <= 3'b0;
        else if (addr_r > `AXI_ADDR_BITS'h4fff_ffff && addr_r < `AXI_ADDR_BITS'h5001_0000)
            in_trans <= s2axi_i.wdata[0];
        else if (addr_r > `AXI_ADDR_BITS'h5fff_ffff && addr_r < `AXI_ADDR_BITS'h6001_0000)
            out_trans <= s2axi_i.wdata[0];
        else if (addr_r > `AXI_ADDR_BITS'h7fff_ffff && addr_r < `AXI_ADDR_BITS'h9000_0000)
            conv_start <= s2axi_i.wdata[0];
    end
// }}}

    sp_ram_intf bias_intf();
    sp_ram_intf weight_intf();
    sp_ram_intf input_intf();
    sp_ram_intf output_intf();
/*
    Input_wrapper input_wrapper (
        .clk          (clk              ),
        .rst          (rst              ),
        .enb_i        (enb[0]           ),
        .mode_i       (in_trans         ),
        // EPU          
        .epuin_i      (EPUIN.EPUin      ),
        .rvalid_o     (in_rvalid        ),
        .rdata_o      (in_rdata         ),
        // CONV
        .input_intf_o (input_intf.memory)
    );
    Output_wrapper output_wrapper (
        .clk           (clk               ),
        .rst           (rst               ),
        .enb_i         (enb[1]            ),
        .mode_i        (out_trans         ),
        // EPU            
        .epuin_i       (EPUIN.EPUin       ),
        .rvalid_o      (out_rvalid        ),
        .rdata_o       (out_rdata         ),
        // CONV            
        .output_intf_o (output_intf.memory)
    );
    Bias_wrapper bias_wrapper (
        .clk         (clk             ),
        .rst         (rst             ),
        .enb_i       (enb[2]          ),
        // EPU        
        .epuin_i     (EPUIN.EPUin     ),
        .rvalid_o    (bias_rvalid     ),
        .rdata_o     (bias_rdata      ),
        // CONV   
        .bias_intf_o (bias_intf.memory)
    );
    Weight_wrapper weight_wrapper (
        .clk           (clk               ),
        .rst           (rst               ),
        .enb_i         (enb[3]            ),
        // EPU          
        .epuin_i       (EPUIN.EPUin       ),
        .rvalid_o      (weight_rvalid     ),
        .rdata_o       (weight_rdata      ),
        // CONV          
        .weight_intf_o (weight_intf.memory)
    );
    
    CONV_wrapper conv_wrapper (
        .clk         (clk                ),
        .rst         (rst                ),
        .start_i     (conv_start         ),
        // EPU
        .epuin_i     (EPUIN.EPUin        ),
        // CONV
        .param_intf  (param_intf.compute ),
        .bias_intf   (bias_intf.compute  ),
        .weight_intf (weight_intf.compute),
        .input_intf  (input_intf.compute ),
        .output_intf (output_intf.compute),
        .finish_o    (conv_fin           )
    );

*/
endmodule
