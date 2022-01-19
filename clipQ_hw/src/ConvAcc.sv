`include "ConvAcc.svh"
`include "Conv_3x3.sv"
`include "Conv_1x1.sv"
`include "Max_pool.sv"
`include "Bus_switcher.sv"
`include "sp_ram_intf.sv"

module ConvAcc
(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    input  logic [3:0]            mode,
    input  logic           [31:0] w8,
    output logic                  finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf_0,
    sp_ram_intf.compute input_intf_1,
    sp_ram_intf.compute output_intf_0,
    sp_ram_intf.compute output_intf_1
);

  // For 3x3 conv unit
  sp_ram_intf param_conv_3x3_intf ();
  sp_ram_intf bias_conv_3x3_intf ();
  sp_ram_intf weight_conv_3x3_intf ();
  sp_ram_intf input_conv_3x3_intf_0 ();
  sp_ram_intf input_conv_3x3_intf_1 ();
  sp_ram_intf output_conv_3x3_intf_0 ();
  sp_ram_intf output_conv_3x3_intf_1 ();
  logic finish_conv_3x3, start_conv_3x3;
  logic gated_conv_3x3_clk;

  // For 1x1 conv unit
  sp_ram_intf param_conv_1x1_intf ();
  sp_ram_intf bias_conv_1x1_intf ();
  sp_ram_intf weight_conv_1x1_intf ();
  sp_ram_intf input_conv_1x1_intf_0 ();
  sp_ram_intf input_conv_1x1_intf_1 ();
  sp_ram_intf output_conv_1x1_intf_0 ();
  sp_ram_intf output_conv_1x1_intf_1 ();
  logic finish_conv_1x1, start_conv_1x1;
  logic gated_conv_1x1_clk;

  // For max pooling unit  
  sp_ram_intf param_maxpool_intf ();
  sp_ram_intf bias_maxpool_intf ();
  sp_ram_intf weight_maxpool_intf ();
  sp_ram_intf input_maxpool_intf_0 ();
  sp_ram_intf input_maxpool_intf_1 ();
  sp_ram_intf output_maxpool_intf_0 ();
  sp_ram_intf output_maxpool_intf_1 ();
  logic finish_maxpool, start_maxpool;
  logic gated_maxpool_clk;

  Bus_switcher i_Bus_switcher (
      .mode(mode),
      // External
      .clk(clk),
      .param_o(param_intf),
      .bias_o(bias_intf),
      .weight_o(weight_intf),
      .input_0_o(input_intf_0),
      .input_1_o(input_intf_1),
      .output_0_o(output_intf_0),
      .output_1_o(output_intf_1),
      // For 3x3 conv unit
      .gated_conv_3x3_clk(gated_conv_3x3_clk),
      .param_conv_3x3_i(param_conv_3x3_intf),
      .bias_conv_3x3_i(bias_conv_3x3_intf),
      .weight_conv_3x3_i(weight_conv_3x3_intf),
      .input_0_conv_3x3_i(input_conv_3x3_intf_0),
      .input_1_conv_3x3_i(input_conv_3x3_intf_1),
      .output_0_conv_3x3_i(output_conv_3x3_intf_0),
      .output_1_conv_3x3_i(output_conv_3x3_intf_1),
      // For 1x1 conv unit
      .gated_conv_1x1_clk(gated_conv_1x1_clk),
      .param_conv_1x1_i(param_conv_1x1_intf),
      .bias_conv_1x1_i(bias_conv_1x1_intf),
      .weight_conv_1x1_i(weight_conv_1x1_intf),
      .input_0_conv_1x1_i(input_conv_1x1_intf_0),
      .input_1_conv_1x1_i(input_conv_1x1_intf_1),
      .output_0_conv_1x1_i(output_conv_1x1_intf_0),
      .output_1_conv_1x1_i(output_conv_1x1_intf_1),
      // For max pooling unit
      .gated_maxpool_clk(gated_maxpool_clk),
      .param_maxpool_i(param_maxpool_intf),
      .bias_maxpool_i(bias_maxpool_intf),
      .weight_maxpool_i(weight_maxpool_intf),
      .input_0_maxpool_i(input_maxpool_intf_0),
      .input_1_maxpool_i(input_maxpool_intf_1),
      .output_0_maxpool_i(output_maxpool_intf_0),
      .output_1_maxpool_i(output_maxpool_intf_1)
  );

  // start
  always_comb begin
    {start_conv_1x1, start_conv_3x3, start_maxpool} = 3'b0;
    if (mode == `CONV_1x1_MODE) start_conv_1x1 = start;
    else if (mode == `CONV_3x3_MODE) start_conv_3x3 = start;
    else if (mode == `MAX_POOL_MODE) start_maxpool = start;
    else {start_conv_1x1, start_conv_3x3, start_maxpool} = 3'b0;
  end

  // finish
  always_comb begin
    finish = 1'b0;
    if (mode == `CONV_1x1_MODE) finish = finish_conv_1x1;
    else if (mode == `CONV_3x3_MODE) finish = finish_conv_3x3;
    else if (mode == `MAX_POOL_MODE) finish = finish_maxpool;
    else  // Connect to nothing
      finish = 1'b0;
  end

  Conv_1x1 i_Conv_1x1 (
      .rst(rst),
      .clk(clk),  // gated_conv_1x1_clk
      .w8(w8),
      .start(start_conv_1x1),
      .finish(finish_conv_1x1),
      .param_intf(param_conv_1x1_intf),
      .bias_intf(bias_conv_1x1_intf),
      .weight_intf(weight_conv_1x1_intf),
      .input_intf_0(input_conv_1x1_intf_0),
      .input_intf_1(input_conv_1x1_intf_1),
      .output_intf_0(output_conv_1x1_intf_0),
      .output_intf_1(output_conv_1x1_intf_1)
  );

  Conv_3x3 i_Conv_3x3 (
      .rst(rst),
      .clk(clk),  // gated_conv_3x3_clk
      .w8(w8),
      .start(start_conv_3x3),
      .finish(finish_conv_3x3),
      .param_intf(param_conv_3x3_intf),
      .bias_intf(bias_conv_3x3_intf),
      .weight_intf(weight_conv_3x3_intf),
      .input_intf_0(input_conv_3x3_intf_0),
      .input_intf_1(input_conv_3x3_intf_1),
      .output_intf_0(output_conv_3x3_intf_0),
      .output_intf_1(output_conv_3x3_intf_1)
  );

  Max_pool i_Max_pool (
      .clk(clk),  // gated_maxpool_clk
      .rst(rst),
      .start(start_maxpool),
      .finish(finish_maxpool),
      .param_intf(param_maxpool_intf),
      .bias_intf(bias_maxpool_intf),
      .weight_intf(weight_maxpool_intf),
      .input_intf_0(input_maxpool_intf_0),
      .input_intf_1(input_maxpool_intf_1),
      .output_intf_0(output_maxpool_intf_0),
      .output_intf_1(output_maxpool_intf_1)
  );

endmodule
