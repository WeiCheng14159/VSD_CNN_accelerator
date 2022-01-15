`include "ConvAcc.svh"
module Conv_1x1 (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] w8,
    input  logic        start,
    output logic        finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

endmodule
