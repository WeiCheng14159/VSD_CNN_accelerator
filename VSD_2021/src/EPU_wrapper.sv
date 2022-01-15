`include "../include/EPU_def.svh"
`include "../include/AXI_define.svh"
`include "./Interface/inf_Slave.sv"
`include "./Interface/inf_EPUIN.sv"
`include "./Interface/sp_ram_intf.sv"
`include "EPU/Input_wrapper.sv"
`include "EPU/Output_wrapper.sv"
`include "EPU/Bias_wrapper.sv"
`include "EPU/Weight_wrapper.sv"
`include "EPU/ConvAcc_wrapper.sv"
`include "EPU/InOut_switcher.sv"
`include "EPU/Param_wrapper.sv"


module EPU_wrapper (
    input logic        clk, rst,
    output logic       epuint_o,
    inf_Slave.S2AXIin  s2axi_i,
    inf_Slave.S2AXIout s2axi_o
);

    typedef enum logic [1:0] {
        IDLE = 2'h0,
        R_CH = 2'h1, 
        W_CH = 2'h2, 
        B_CH = 2'h3
    } epu_wrapper_state_t;

    epu_wrapper_state_t STATE, NEXT;
    // Handshake
    logic awhns, arhns, whns, rhns, bhns;
    logic rdfin, wrfin;
    // Sample
    logic [`AXI_ADDR_BITS -1:0] addr_r;
    logic [`AXI_IDS_BITS  -1:0] ids_r;
    logic [`AXI_LEN_BITS  -1:0] len_r;
    logic [`AXI_STRB_BITS -1:0] wstrb_r;
    logic [`AXI_BURST_BITS-1:0] burst_r;
    // rlast
    logic [`AXI_LEN_BITS-1:0] cnt_r;
    // SRAM enable
    logic [5:0] enb;
    // 
    inf_EPUIN EPUIN();
    logic [`DATA_BITS-1:0] in_rdata, out_rdata, bias_rdata, weight_rdata, param_rdata;
    logic in_rvalid, out_rvalid, bias_rvalid, weight_rvalid, param_rvalid;
    logic in_trans, out_trans;
    logic conv_start, conv_fin;
    logic  [`DATA_BITS-1:0] conv_w8;
    logic [3:0] conv_mode;

    // Handshake
    assign rdfin = s2axi_o.rlast & rhns;
    assign wrfin = s2axi_i.wlast & whns;
    assign awhns = s2axi_i.awvalid & s2axi_o.awready;
    assign arhns = s2axi_i.arvalid & s2axi_o.arready;
    assign whns = s2axi_i.wvalid & s2axi_o.wready;
    assign rhns = s2axi_o.rvalid & s2axi_i.rready;
    assign bhns = s2axi_o.bvalid & s2axi_i.bready;
    // EPU interface
    assign EPUIN.rdfin = rdfin;
    assign EPUIN.wrfin = wrfin;
    assign EPUIN.awhns = awhns;
    assign EPUIN.arhns = arhns;
    assign EPUIN.wdata = s2axi_i.wdata;
    
    // Interrupt
    assign epuint_o = conv_fin;

// {{{ Sample
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_r  <= `AXI_ADDR_BITS'h0;
            ids_r   <= `AXI_IDS_BITS'h0;
            len_r   <= `AXI_LEN_BITS'h0;
            wstrb_r <= `AXI_STRB_BITS'h0;
            burst_r <= `AXI_BURST_BITS'h0;
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
    always_ff@(posedge clk or posedge rst) begin
        STATE <= rst ? IDLE : NEXT;
    end
    always_comb begin
        case(STATE)
            IDLE    : begin
                case ({awhns, arhns})
                    2'b10   : NEXT = B_CH;
                    2'b01   : NEXT = R_CH;
                    default : NEXT = IDLE;
                endcase
            end
            R_CH    : NEXT = rdfin ? IDLE : R_CH;
            W_CH    : NEXT = wrfin ? B_CH : W_CH;
            B_CH    : NEXT = bhns        ? IDLE : B_CH;
            default : NEXT = STATE;
        endcase
    end
// }}}

// {{{ Counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
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
            5'b00001 : s2axi_o.rdata = in_rdata;
            5'b00010 : s2axi_o.rdata = out_rdata;
            5'b00100 : s2axi_o.rdata = bias_rdata;
            5'b01000 : s2axi_o.rdata = weight_rdata;
            5'b10000 : s2axi_o.rdata = param_rdata;
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

    always_comb begin
        case ({{STATE == R_CH}, enb})
            6'b100001 : s2axi_o.rvalid = in_rvalid;
            6'b100010 : s2axi_o.rvalid = out_rvalid;
            6'b100100 : s2axi_o.rvalid = bias_rvalid;
            6'b101000 : s2axi_o.rvalid = weight_rvalid;
            6'b110000 : s2axi_o.rvalid = param_rvalid;
            default  : s2axi_o.rvalid = 1'b0;
        endcase
    end

// }}}


// {{{ SRAM
    always_ff @(posedge clk or posedge rst) begin
        if (rst)               EPUIN.addr <= {`EPU_ADDR_BITS{1'b0}};
        else if (awhns)         EPUIN.addr <= s2axi_i.awaddr;
        else if (arhns)         EPUIN.addr <= s2axi_i.araddr + `EPU_ADDR_BITS'h1;//{{(`EPU_ADDR_BITS-1){1'b0}}, 1'b1};
        else if (wrfin | rdfin) EPUIN.addr <= {`EPU_ADDR_BITS{1'b0}};
        else if (whns | rhns)   EPUIN.addr <= EPUIN.addr + `EPU_ADDR_BITS'h1;//{{(`EPU_ADDR_BITS-1){1'b0}}, 1'b1};
    end

    // Input  : 5000_0000 ~ 5000_ffff
    //          5001_0000 ~ 5fff_ffff
    // Output : 6000_0000 ~ 6000_ffff
    //          6001_0000 ~ 6fff_ffff
    // Weight  : 7000_0000 ~ 70ff_ffff
    // Bias    : 7100_0000 ~ 71ff_ffff
    // Param   : 7200_0000 ~ 72ff_ffff
    // ConvAcc : 8000_0000 ~ 8fff_ffff

    always_comb begin
        enb = 5'b0;
        if (addr_r > `AXI_ADDR_BITS'h5000_ffff && addr_r < `AXI_ADDR_BITS'h6000_0000)
            enb[0] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h6000_ffff && addr_r < `AXI_ADDR_BITS'h7000_0000)
            enb[1] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h6fff_ffff && addr_r < `AXI_ADDR_BITS'h7100_0000)
            enb[2] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h70ff_ffff && addr_r < `AXI_ADDR_BITS'h7200_0000)
            enb[3] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h71ff_ffff && addr_r < `AXI_ADDR_BITS'h7300_0000)
            enb[4] = 1'b1;
        else if (addr_r > `AXI_ADDR_BITS'h7fff_ffff && addr_r < `AXI_ADDR_BITS'h9000_0000)
            enb[5] = 1'b1;
        else 
            enb = 5'b0;
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

// {{{ ConvAcc control
    // ConvAcc: 8000_0000 EPU W8
    //          8000_0004 [  0] EPU start
    //                    [4:1] EPU mode
    //                    [  5] Input buffer transpose
    //                    [  6] Output buffer transpose
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            {in_trans, out_trans, conv_start} <= 3'b0;
            conv_w8 <= 32'h0; 
            conv_mode <= 4'h0;
        end else if (enb[5]) begin
            if (addr_r == `AXI_ADDR_BITS'h8000_0000)
                conv_w8 <= s2axi_i.wdata;
            else if (addr_r == `AXI_ADDR_BITS'h8000_0004) begin
                {in_trans, out_trans, conv_start} <= {s2axi_i.wdata[5], s2axi_i.wdata[6], s2axi_i.wdata[0]};
                conv_mode <= s2axi_i.wdata[4:1];
            end
        end else begin
            {in_trans, out_trans, conv_start} <= {in_trans, out_trans, conv_start};
            conv_w8 <= conv_w8; 
            conv_mode <= conv_mode;
        end
    end
// }}}

    sp_ram_intf param_bus2EPU();
    sp_ram_intf bias_bus2EPU();
    sp_ram_intf weight_bus2EPU();
    sp_ram_intf in_bus2EPU();
    sp_ram_intf out_bus2EPU();
    sp_ram_intf EPU_in_bus();
    sp_ram_intf EPU_out_bus();

    Input_wrapper i_Input_wrapper (
        .clk          (clk              ),
        .rst          (rst              ),
        .enb_i        (enb[0]           ),
        // Connection to EPU wrapper (to AXI)       
        .epuin_i      (EPUIN.EPUin      ),
        .rvalid_o     (in_rvalid        ),
        .rdata_o      (in_rdata         ),
        // Connection to EPU
        .bus2EPU      (in_bus2EPU       )
    );

    Output_wrapper i_Output_wrapper (
        .clk           (clk               ),
        .rst           (rst               ),
        .enb_i         (enb[1]            ),
        // Connection to EPU wrapper (to AXI)         
        .epuin_i       (EPUIN.EPUin       ),
        .rvalid_o      (out_rvalid        ),
        .rdata_o       (out_rdata         ),
        // Connection to EPU           
        .bus2EPU       (out_bus2EPU       )
    );

    Weight_wrapper i_Weight_wrapper (
        .clk           (clk             ),
        .rst           (rst             ),
        .enb_i         (enb[2]          ),
        // Connection to EPU wrapper (to AXI)          
        .epuin_i       (EPUIN.EPUin     ),
        .rvalid_o      (weight_rvalid   ),
        .rdata_o       (weight_rdata    ),
        // Connection to EPU 
        .bus2EPU       (weight_bus2EPU  )
    );
    
    Bias_wrapper i_Bias_wrapper (
        .clk         (clk             ),
        .rst         (rst             ),
        .enb_i       (enb[3]          ),
        // Connection to EPU wrapper (to AXI)          
        .epuin_i     (EPUIN.EPUin     ),
        .rvalid_o    (bias_rvalid     ),
        .rdata_o     (bias_rdata      ),
        // Connection to EPU 
        .bus2EPU     (bias_bus2EPU    )
    );
    
    Param_wrapper i_Param_wrapper (
        .clk         (clk             ),
        .rst         (rst             ),
        .enb_i       (enb[4]          ),
        // Connection to EPU wrapper (to AXI)          
        .epuin_i     (EPUIN.EPUin     ),
        .rvalid_o    (param_rvalid    ),
        .rdata_o     (param_rdata     ),
        // Connection to EPU 
        .bus2EPU     (param_bus2EPU   )
    );

    InOut_switcher i_InOut_switcher(
        .in_trans_i    (in_trans          ),
        .out_trans_i   (out_trans         ),
        .from_in_buff_i(in_bus2EPU        ),
        .from_out_buff_i(out_bus2EPU      ),
        .to_EPU_in_buff_o(EPU_in_bus      ),
        .to_EPU_out_buff_o(EPU_out_bus    )
    );
    
    ConvAcc_wrapper i_ConvAcc_wrapper (
        .clk            (clk                    ),
        .rst            (rst                    ),
        .start_i        (conv_start             ),
        .mode_i         (conv_mode              ),
        .weight_w8_i    (conv_w8                ),
        .finish_o       (conv_fin               ),
        // Connection to EPU wrapper (to AXI)   
        .epuin_i        (EPUIN.EPUin            ),
        // Connection to buffer wrappers    
        .param_intf     (param_bus2EPU          ),
        .bias_intf      (bias_bus2EPU           ),
        .weight_intf    (weight_bus2EPU         ),
        .input_intf     (EPU_in_bus             ),
        .output_intf    (EPU_out_bus            )
    );

endmodule
