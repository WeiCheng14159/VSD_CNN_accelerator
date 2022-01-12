`include "conv_3x3.sv"
`include "conv_1x1.sv"
`include "bus_switcher.sv"

module conv (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [ 1:0] kernel_size,
    input  logic [31:0] w8,
    output logic        finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

  // For 3x3 conv unit
  sp_ram_intf param_3x3_intf ();
  sp_ram_intf bias_3x3_intf ();
  sp_ram_intf weight_3x3_intf ();
  sp_ram_intf input_3x3_intf ();
  sp_ram_intf output_3x3_intf ();
  logic finish_3x3, start_3x3;

  // For 1x1 conv unit
  sp_ram_intf param_1x1_intf ();
  sp_ram_intf bias_1x1_intf ();
  sp_ram_intf weight_1x1_intf ();
  sp_ram_intf input_1x1_intf ();
  sp_ram_intf output_1x1_intf ();
  logic finish_1x1, start_1x1;

  bus_switcher i_bus_switcher (
      .kernel_size(kernel_size),
      // External
      .param_o(param_intf),
      .bias_o(bias_intf),
      .weight_o(weight_intf),
      .input_o(input_intf),
      .output_o(output_intf),
      // For 3x3 conv unit
      .param_3x3_i(param_3x3_intf),
      .bias_3x3_i(bias_3x3_intf),
      .weight_3x3_i(weight_3x3_intf),
      .input_3x3_i(input_3x3_intf),
      .output_3x3_i(output_3x3_intf),
      // For 1x1 conv unit
      .param_1x1_i(param_1x1_intf),
      .bias_1x1_i(bias_1x1_intf),
      .weight_1x1_i(weight_1x1_intf),
      .input_1x1_i(input_1x1_intf),
      .output_1x1_i(output_1x1_intf)
  );

  always_comb begin
    start_1x1 = 1'b0;
    start_3x3 = 1'b0;
    if (kernel_size == 2'h1) begin
      finish = finish_1x1;
      start_1x1 = start;
    end else if (kernel_size == 2'h3) begin
      finish = finish_3x3;
      start_3x3 = start;
    end else begin  // Connect to nothing
      finish = 1'b0;
      start_1x1 = 1'b0;
      start_3x3 = 1'b0;
    end
  end

  conv_1x1 i_conv_1x1 (
      .rst(rst),
      .clk(clk),
      .w8(w8),
      .start(start_1x1),
      .finish(finish_1x1),
      .param_intf(param_1x1_intf),
      .bias_intf(bias_1x1_intf),
      .weight_intf(weight_1x1_intf),
      .input_intf(input_1x1_intf),
      .output_intf(output_1x1_intf)
  );

  conv_3x3 i_conv_3x3 (
      .rst(rst),
      .clk(clk),
      .w8(w8),
      .start(start_3x3),
      .finish(finish_3x3),
      .param_intf(param_3x3_intf),
      .bias_intf(bias_3x3_intf),
      .weight_intf(weight_3x3_intf),
      .input_intf(input_3x3_intf),
      .output_intf(output_3x3_intf)
  );

endmodule
