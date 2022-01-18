`include "../../include/CPU_def.svh"
`include "../../include/AXI_define.svh"
`include "ConvAcc.svh"
`include "EPU/ConvAcc.sv"

module ConvAcc_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic                      start_i,
    input  logic               [ 3:0] mode_i,
    input  logic               [31:0] weight_w8_i,
    output logic                      finish_o,
           inf_EPUIN.EPUin            epuin_i,
           sp_ram_intf.compute        param_intf,
           sp_ram_intf.compute        bias_intf,
           sp_ram_intf.compute        weight_intf,
           sp_ram_intf.compute        input_intf,
           sp_ram_intf.compute        output_intf
);

  ConvAcc i_ConvAcc (
      .clk(clk),
      .rst(rst),
      .start(start_i),
      .mode(mode_i),
      .w8(weight_w8_i),
      .finish(finish_o),
      .param_intf(param_intf),
      .bias_intf(bias_intf),
      .weight_intf(weight_intf),
      .input_intf(input_intf),
      .output_intf(output_intf)
  );

endmodule
