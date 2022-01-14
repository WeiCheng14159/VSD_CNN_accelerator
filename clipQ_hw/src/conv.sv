`include "conv_acc_pkg.sv"
`include "conv_3x3.sv"
`include "conv_1x1.sv"
`include "max_pool.sv"
`include "bus_switcher.sv"

module conv
  import conv_acc_pkg::*;
(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    input  conv_acc_mode_t        mode,
    input  logic           [31:0] w8,
    output logic                  finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

  // For 3x3 conv unit
  sp_ram_intf param_conv_3x3_intf ();
  sp_ram_intf bias_conv_3x3_intf ();
  sp_ram_intf weight_conv_3x3_intf ();
  sp_ram_intf input_conv_3x3_intf ();
  sp_ram_intf output_conv_3x3_intf ();
  logic finish_conv_3x3, start_conv_3x3;
  logic gated_conv_3x3_clk;

  // For 1x1 conv unit
  sp_ram_intf param_conv_1x1_intf ();
  sp_ram_intf bias_conv_1x1_intf ();
  sp_ram_intf weight_conv_1x1_intf ();
  sp_ram_intf input_conv_1x1_intf ();
  sp_ram_intf output_conv_1x1_intf ();
  logic finish_conv_1x1, start_conv_1x1;
  logic gated_conv_1x1_clk;

  // For max pooling unit  
  sp_ram_intf param_maxpool_intf ();
  sp_ram_intf bias_maxpool_intf ();
  sp_ram_intf weight_maxpool_intf ();
  sp_ram_intf input_maxpool_intf ();
  sp_ram_intf output_maxpool_intf ();
  logic finish_maxpool, start_maxpool;
  logic gated_maxpool_clk;

  bus_switcher i_bus_switcher (
      .mode(mode),
      // External
      .clk(clk),
      .param_o(param_intf),
      .bias_o(bias_intf),
      .weight_o(weight_intf),
      .input_o(input_intf),
      .output_o(output_intf),
      // For 3x3 conv unit
      .gated_conv_3x3_clk(gated_conv_3x3_clk),
      .param_conv_3x3_i(param_conv_3x3_intf),
      .bias_conv_3x3_i(bias_conv_3x3_intf),
      .weight_conv_3x3_i(weight_conv_3x3_intf),
      .input_conv_3x3_i(input_conv_3x3_intf),
      .output_conv_3x3_i(output_conv_3x3_intf),
      // For 1x1 conv unit
      .gated_conv_1x1_clk(gated_conv_1x1_clk),
      .param_conv_1x1_i(param_conv_1x1_intf),
      .bias_conv_1x1_i(bias_conv_1x1_intf),
      .weight_conv_1x1_i(weight_conv_1x1_intf),
      .input_conv_1x1_i(input_conv_1x1_intf),
      .output_conv_1x1_i(output_conv_1x1_intf),
      // For max pooling unit
      .gated_maxpool_clk(gated_maxpool_clk),
      .param_maxpool_i(param_maxpool_intf),
      .bias_maxpool_i(bias_maxpool_intf),
      .weight_maxpool_i(weight_maxpool_intf),
      .input_maxpool_i(input_maxpool_intf),
      .output_maxpool_i(output_maxpool_intf)
  );

  // start
  always_comb begin
    {start_conv_1x1, start_conv_3x3, start_maxpool} = 3'b0;
    if (mode == CONV_1x1_MODE) start_conv_1x1 = start;
    else if (mode == CONV_3x3_MODE) start_conv_3x3 = start;
    else if (mode == MAX_POOL_MODE) start_maxpool = start;
    else {start_conv_1x1, start_conv_3x3, start_maxpool} = 3'b0;
  end

  // finish
  always_comb begin
    finish = 1'b0;
    if (mode == CONV_1x1_MODE) finish = finish_conv_1x1;
    else if (mode == CONV_3x3_MODE) finish = finish_conv_3x3;
    else if (mode == MAX_POOL_MODE) finish = finish_maxpool;
    else  // Connect to nothing
      finish = 1'b0;
  end

  conv_1x1 i_conv_1x1 (
      .rst(rst),
      .clk(clk), // gated_conv_1x1_clk
      .w8(w8),
      .start(start_conv_1x1),
      .finish(finish_conv_1x1),
      .param_intf(param_conv_1x1_intf),
      .bias_intf(bias_conv_1x1_intf),
      .weight_intf(weight_conv_1x1_intf),
      .input_intf(input_conv_1x1_intf),
      .output_intf(output_conv_1x1_intf)
  );

  conv_3x3 i_conv_3x3 (
      .rst(rst),
      .clk(clk), // gated_conv_3x3_clk
      .w8(w8),
      .start(start_conv_3x3),
      .finish(finish_conv_3x3),
      .param_intf(param_conv_3x3_intf),
      .bias_intf(bias_conv_3x3_intf),
      .weight_intf(weight_conv_3x3_intf),
      .input_intf(input_conv_3x3_intf),
      .output_intf(output_conv_3x3_intf)
  );

  max_pool i_max_pool (
      .clk(clk), // gated_maxpool_clk
      .rst(rst),
      .start(start_maxpool),
      .finish(finish_maxpool),
      .param_intf(param_maxpool_intf),
      .bias_intf(bias_maxpool_intf),
      .weight_intf(weight_maxpool_intf),
      .input_intf(input_maxpool_intf),
      .output_intf(output_maxpool_intf)
  );

endmodule
