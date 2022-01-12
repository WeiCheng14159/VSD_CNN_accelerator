`include "conv_acc.svh"

module max_pool (
    input        clk,
    input        rst,
    input        start,
    output logic finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

endmodule
