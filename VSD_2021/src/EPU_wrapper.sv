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
    input  logic              clk,
    rst,
    output logic              epuint_o,
           inf_Slave.S2AXIin  s2axi_i,
           inf_Slave.S2AXIout s2axi_o
);


  // assign s2axi_o.rlast = 1'b1;
  // assign s2axi_o.rresp = `AXI_RESP_OKAY;
  // assign s2axi_o.bresp = `AXI_RESP_OKAY;
  // assign s2axi_o.rdata = `AXI_DATA_BITS'h0; 
  // assign s2axi_o.rid   = `AXI_IDS_BITS'h0;
  // assign s2axi_o.bid   = `AXI_IDS_BITS'h0;
  // assign {s2axi_o.awready, s2axi_o.arready, s2axi_o.wready} = 3'b0;
  // assign {s2axi_o.rvalid, s2axi_o.bvalid} = 2'b0;
  // assign epuint_o = 1'b0;

  // /*
  typedef enum logic [1:0] {
    IDLE = 2'h0,
    R_CH = 2'h1,
    W_CH = 2'h2,
    B_CH = 2'h3
  } epu_wrapper_state_t;

  epu_wrapper_state_t curr_state, next_state;
  // Handshake
  logic awhns, arhns, whns, rhns, bhns;
  logic rdfin, wrfin;
  // Sample
  logic [`AXI_ADDR_BITS -1:0] addr_r;
  logic [`AXI_LEN_BITS  -1:0] addr_offset;
  logic [`AXI_IDS_BITS  -1:0] ids_r;
  logic [`AXI_LEN_BITS  -1:0] len_r;
  logic [`AXI_STRB_BITS -1:0] wstrb_r;
  logic [`AXI_BURST_BITS-1:0] burst_r;
  logic [`AXI_DATA_BITS -1:0] wdata_r;
  // Other
  logic [  `AXI_LEN_BITS-1:0] cnt_r;
  logic [`DATA_BITS-1:0]
      in_rdata, out_rdata, bias_rdata, weight_rdata, param_rdata;
  logic in_rvalid, out_rvalid, bias_rvalid, weight_rvalid, param_rvalid;
  logic inout_trans;
  logic conv_start, conv_fin;
  logic [`DATA_BITS-1:0] conv_w8;
  logic [3:0] conv_mode;
  inf_EPUIN EPUIN ();

  localparam IN_SEL_B = 0, OUT_SEL_B = 1, WEIGHT_SEL_B = 2, BIAS_SEL_B = 3, PARAM_SEL_B = 4, EPU_CTRL_SEL_B = 5, SEL_NO_B = 6;
  typedef enum logic [SEL_NO_B:0] {
    SEL_NO       = 1 << SEL_NO_B,
    IN_SEL       = 1 << IN_SEL_B,
    OUT_SEL      = 1 << OUT_SEL_B,
    WEIGHT_SEL   = 1 << WEIGHT_SEL_B,
    BIAS_SEL     = 1 << BIAS_SEL_B,
    PARAM_SEL    = 1 << PARAM_SEL_B,
    EPU_CTRL_SEL = 1 << EPU_CTRL_SEL_B
  } buffer_sel_t;

  buffer_sel_t buffer_sel;

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
  assign EPUIN.whns = whns;
  assign EPUIN.rhns = rhns;
  // Interrupt
  assign epuint_o = conv_fin;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      addr_r  <= `AXI_ADDR_BITS'h0;
      ids_r   <= `AXI_IDS_BITS'h0;
      len_r   <= `AXI_LEN_BITS'h0;
      wstrb_r <= `AXI_STRB_BITS'h0;
      burst_r <= `AXI_BURST_BITS'h0;
      wdata_r <= `AXI_DATA_BITS'h0;
    end else begin
      addr_r  <= arhns ? s2axi_i.araddr : awhns ? s2axi_i.awaddr : addr_r;
      ids_r   <= arhns ? s2axi_i.arid : awhns ? s2axi_i.awid : ids_r;
      len_r   <= arhns ? s2axi_i.arlen : awhns ? s2axi_i.awlen : len_r;
      wstrb_r <= awhns ? s2axi_i.wstrb : wstrb_r;
      burst_r <= awhns ? s2axi_i.awburst : arhns ? s2axi_i.arburst : burst_r;
      wdata_r <= whns ? s2axi_i.wdata : wdata_r;
    end
  end

  always_ff @(posedge clk or posedge rst) begin
    curr_state <= rst ? IDLE : next_state;
  end
  always_comb begin
    case (curr_state)
      IDLE: begin
        case ({
          awhns, arhns
        })
          2'b10:   next_state = W_CH;
          2'b01:   next_state = R_CH;
          2'b11:   next_state = W_CH;
          default: next_state = IDLE;
        endcase
      end
      R_CH:    next_state = rdfin ? IDLE : R_CH;
      W_CH:    next_state = wrfin ? B_CH : W_CH;
      B_CH:    next_state = bhns ? IDLE : B_CH;
      default: next_state = curr_state;
    endcase
  end  // Next state (S)

  always_ff @(posedge clk or posedge rst) begin
    if (rst) cnt_r <= `AXI_LEN_BITS'h0;
    else begin
      case (curr_state)
        R_CH:
        cnt_r <= rdfin ? `AXI_LEN_BITS'h0 : rhns ? cnt_r + `AXI_LEN_BITS'h1 : cnt_r;
        W_CH:
        cnt_r <= wrfin ? `AXI_LEN_BITS'h0 : whns ? cnt_r + `AXI_LEN_BITS'h1 : cnt_r;
      endcase
    end
  end

  assign s2axi_o.rlast  = cnt_r == len_r;
  assign s2axi_o.rresp  = `AXI_RESP_OKAY;
  assign s2axi_o.bresp  = `AXI_RESP_OKAY;
  assign s2axi_o.rid    = ids_r;
  assign s2axi_o.bid    = ids_r;
  assign s2axi_o.bvalid = curr_state == B_CH;
  assign s2axi_o.awready = curr_state == IDLE;
  assign s2axi_o.arready = (curr_state == IDLE) && (~s2axi_i.awvalid);
  assign s2axi_o.wready  = curr_state == W_CH;
  always_comb begin
    unique case (1'b1)
      buffer_sel[IN_SEL_B]:    s2axi_o.rdata = in_rdata;
      buffer_sel[OUT_SEL_B]:   s2axi_o.rdata = out_rdata;
      buffer_sel[WEIGHT_SEL_B]:s2axi_o.rdata = weight_rdata;
      buffer_sel[BIAS_SEL_B]:  s2axi_o.rdata = bias_rdata;
      buffer_sel[PARAM_SEL_B]: s2axi_o.rdata = param_rdata;
      buffer_sel[SEL_NO_B]:    s2axi_o.rdata = `DATA_BITS'h0;
      buffer_sel[EPU_CTRL_SEL_B]:s2axi_o.rdata = `DATA_BITS'h0;
    endcase
  end

  always_comb begin
    s2axi_o.rvalid = 1'b0;
    if (curr_state == R_CH) begin
      unique case (1'b1)
        buffer_sel[IN_SEL_B]: s2axi_o.rvalid = in_rvalid;
        buffer_sel[OUT_SEL_B]: s2axi_o.rvalid = out_rvalid;
        buffer_sel[WEIGHT_SEL_B]: s2axi_o.rvalid = weight_rvalid;
        buffer_sel[BIAS_SEL_B]: s2axi_o.rvalid = bias_rvalid;
        buffer_sel[PARAM_SEL_B]: s2axi_o.rvalid = param_rvalid;
        buffer_sel[SEL_NO_B]: s2axi_o.rvalid = 1'b0;
        buffer_sel[EPU_CTRL_SEL_B]: s2axi_o.rvalid = 1'b0;
      endcase
    end
  end

  assign EPUIN.addr = addr_r + {addr_offset, 2'b00};
  always_ff @(posedge clk or posedge rst) begin
    if (rst) addr_offset <= `AXI_LEN_BITS'b0;
    else begin
      case ({
        (awhns | arhns), (whns | rhns)
      })
        2'b10:   addr_offset <= `AXI_LEN_BITS'b0;
        2'b01:   addr_offset <= addr_offset + 1'b1;
        default: ;
      endcase
    end
  end

  // Input   : 5000_0000 ~ 5fff_ffff
  // Output  : 6000_0000 ~ 6fff_ffff
  // Weight  : 7000_0000 ~ 70ff_ffff
  // Bias    : 7100_0000 ~ 71ff_ffff
  // Param   : 7200_0000 ~ 72ff_ffff
  // ConvAcc : 8000_0000 ~ 8fff_ffff
  always_comb begin
    case (addr_r[`AXI_ADDR_BITS-1-:8])
      8'h50: buffer_sel = IN_SEL;
      8'h60: buffer_sel = OUT_SEL;
      8'h70: buffer_sel = WEIGHT_SEL;
      8'h71: buffer_sel = BIAS_SEL;
      8'h72: buffer_sel = PARAM_SEL;
      8'h80, 8'h81, 8'h82: buffer_sel = EPU_CTRL_SEL;
      default: buffer_sel = SEL_NO;
    endcase
  end

  always_comb begin
    case (curr_state)
      IDLE:    {EPUIN.OE, EPUIN.CS} = 2'b0;
      R_CH:    {EPUIN.OE, EPUIN.CS} = 2'b11;
      W_CH:    {EPUIN.OE, EPUIN.CS} = 2'b01;
      B_CH:    {EPUIN.OE, EPUIN.CS} = 2'b0;
      default: {EPUIN.OE, EPUIN.CS} = 2'b0;
    endcase
  end

  // ConvAcc: 8000_0000 ~ 80FF_FFFF [   0] EPU start
  //                                [ 4:1] EPU mode
  //                                [   5] Input buffer transpose
  //                                [   6] Output buffer transpose
  //          8100_0000 ~ 81FF_FFFF [15: 0] EPU W8
  //          8200_0000 ~ 82FF_FFFF [31:16] EPU W8
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      {inout_trans, conv_start} <= 2'b0;
      conv_mode <= 4'h1;
    end else if (conv_fin) begin
      {inout_trans, conv_start} <= 2'b0;
      conv_mode <= 4'h1;
    end else if ((EPUIN.addr[`AXI_ADDR_BITS-1-:8] == 8'h80) & bhns) begin
      {inout_trans, conv_start} <= {wdata_r[5], wdata_r[0]};
      conv_mode <= wdata_r[4:1];
    end
  end

  // assign conv_w8_lower = ((EPUIN.addr[`AXI_ADDR_BITS-1-:8] == 8'h81) & EPUIN.whns);
  // assign conv_w8_upper = ((EPUIN.addr[`AXI_ADDR_BITS-1-:8] == 8'h82) & EPUIN.whns);
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      conv_w8 <= 32'h0;
    end else begin
      if (conv_fin) begin
        conv_w8 <= 32'h0;
      end else begin
        case ({
          ((EPUIN.addr[`AXI_ADDR_BITS-1-:8] == 8'h82) & bhns),
          ((EPUIN.addr[`AXI_ADDR_BITS-1-:8] == 8'h81) & bhns)
        })
          2'b10:   conv_w8[31:16] <= wdata_r[15:0];
          2'b01:   conv_w8[15:0] <= wdata_r[15:0];
          default: conv_w8 <= conv_w8;
        endcase
      end
    end
  end

  sp_ram_intf param_bus2EPU ();
  sp_ram_intf bias_bus2EPU ();
  sp_ram_intf weight_bus2EPU ();
  sp_ram_intf in_bus2EPU ();
  sp_ram_intf out_bus2EPU ();
  sp_ram_intf EPU_in_bus ();
  sp_ram_intf EPU_out_bus ();

  Input_wrapper i_Input_wrapper (
      .clk     (clk),
      .rst     (rst),
      .enb_i   (buffer_sel[IN_SEL_B]),
      // Connection to EPU wrapper (to AXI)       
      .epuin_i (EPUIN.EPUin),
      .rvalid_o(in_rvalid),
      .rdata_o (in_rdata),
      // Connection to EPU
      .start_i (conv_start),
      .finish_i(conv_fin),
      .bus2EPU (in_bus2EPU)
  );

  Output_wrapper i_Output_wrapper (
      .clk     (clk),
      .rst     (rst),
      .enb_i   (buffer_sel[OUT_SEL_B]),
      // Connection to EPU wrapper (to AXI)         
      .epuin_i (EPUIN.EPUin),
      .rvalid_o(out_rvalid),
      .rdata_o (out_rdata),
      // Connection to EPU     
      .start_i (conv_start),
      .finish_i(conv_fin),
      .bus2EPU (out_bus2EPU)
  );

  Weight_wrapper i_Weight_wrapper (
      .clk     (clk),
      .rst     (rst),
      .enb_i   (buffer_sel[WEIGHT_SEL_B]),
      // Connection to EPU wrapper (to AXI)          
      .epuin_i (EPUIN.EPUin),
      .rvalid_o(weight_rvalid),
      .rdata_o (weight_rdata),
      // Connection to EPU 
      .start_i (conv_start),
      .finish_i(conv_fin),
      .bus2EPU (weight_bus2EPU)
  );

  Bias_wrapper i_Bias_wrapper (
      .clk     (clk),
      .rst     (rst),
      .enb_i   (buffer_sel[BIAS_SEL_B]),
      // Connection to EPU wrapper (to AXI)          
      .epuin_i (EPUIN.EPUin),
      .rvalid_o(bias_rvalid),
      .rdata_o (bias_rdata),
      // Connection to EPU 
      .start_i (conv_start),
      .finish_i(conv_fin),
      .bus2EPU (bias_bus2EPU)
  );

  Param_wrapper i_Param_wrapper (
      .clk     (clk),
      .rst     (rst),
      .enb_i   (buffer_sel[PARAM_SEL_B]),
      // Connection to EPU wrapper (to AXI)          
      .epuin_i (EPUIN.EPUin),
      .rvalid_o(param_rvalid),
      .rdata_o (param_rdata),
      // Connection to EPU 
      .start_i (conv_start),
      .finish_i(conv_fin),
      .bus2EPU (param_bus2EPU)
  );

  InOut_switcher i_InOut_switcher (
      .inout_trans_i    (inout_trans),
      .from_in_buff_i   (in_bus2EPU),
      .from_out_buff_i  (out_bus2EPU),
      .to_EPU_in_buff_o (EPU_in_bus),
      .to_EPU_out_buff_o(EPU_out_bus)
  );

  ConvAcc_wrapper i_ConvAcc_wrapper (
      .clk        (clk),
      .rst        (rst),
      .start_i    (conv_start),
      .mode_i     (conv_mode),
      .weight_w8_i(conv_w8),
      .finish_o   (conv_fin),
      // Connection to EPU wrapper (to AXI)   
      .epuin_i    (EPUIN.EPUin),
      // Connection to buffer wrappers    
      .param_intf (param_bus2EPU),
      .bias_intf  (bias_bus2EPU),
      .weight_intf(weight_bus2EPU),
      .input_intf (EPU_in_bus),
      .output_intf(EPU_out_bus)
  );
  // */

endmodule
