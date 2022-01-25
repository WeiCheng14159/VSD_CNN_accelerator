`include "sp_ram_intf.sv"
`include "InOut_SRAM_384k.sv"  // Input SRAM or Output SRAM (384 KB)
`include "InOut_dp_SRAM_384k.sv"  // Input SRAM or Output SRAM (384 KB) (dual port)
`include "Weight_SRAM_180k.sv"  // Weight SRAM (180 KB)
`include "Bias_SRAM_2k.sv"  // Bias SRAM (2KB)
`include "Param_SRAM_16B.sv"  // Param SRAM (16B)
`include "ConvAcc.sv"

module top (
    input  logic        clk,
    input  logic        rstn,
    input  logic        start_i,
    input  logic [ 3:0] mode_i,
    input  logic [31:0] w8_i,
    output logic        finish_o
);

  // Interface
  sp_ram_intf param_intf ();
  sp_ram_intf input_intf ();
  sp_ram_intf weight_intf ();
  sp_ram_intf output_intf ();
  sp_ram_intf bias_intf ();

  Param_SRAM_16B i_param_mem (
      .clk(clk),
      .mem(param_intf)
  );

  InOut_SRAM_384k i_Input_SRAM_384k (
      .clk(clk),
      .mem(input_intf)
  );

  InOut_SRAM_384k i_Output_SRAM_384k (
      .clk(clk),
      .mem(output_intf)
  );

  Weight_SRAM_180k i_Weight_SRAM_180k (
      .clk(clk),
      .mem(weight_intf)
  );

  Bias_SRAM_2k i_Bias_SRAM_2k (
      .clk(clk),
      .mem(bias_intf)
  );

  ConvAcc i_ConvAcc (
      .rstn(rstn),
      .clk(clk),
      .w8(w8_i),
      .start(start_i),
      .finish(finish_o),
      .mode(mode_i),
      .param_intf(param_intf),
      .bias_intf(bias_intf),
      .weight_intf(weight_intf),
      .input_intf(input_intf),
      .output_intf(output_intf)
  );

endmodule
