`include "ConvAcc.svh"
`include "Interface/sp_ram_intf.sv"

module Conv_bus_switcher (
    input  logic               [3:0] mode,
    // External bus
    input  logic                     clk,
           sp_ram_intf.compute       param_o,
           sp_ram_intf.compute       bias_o,
           sp_ram_intf.compute       weight_o,
           sp_ram_intf.compute       input_o,
           sp_ram_intf.compute       output_o,
    // For 3x3 conv unit
    output logic                     gated_conv_3x3_clk,
           sp_ram_intf.memory        param_conv_3x3_i,
           sp_ram_intf.memory        bias_conv_3x3_i,
           sp_ram_intf.memory        weight_conv_3x3_i,
           sp_ram_intf.memory        input_conv_3x3_i,
           sp_ram_intf.memory        output_conv_3x3_i,
    // For 1x1 conv unit
    output logic                     gated_conv_1x1_clk,
           sp_ram_intf.memory        param_conv_1x1_i,
           sp_ram_intf.memory        bias_conv_1x1_i,
           sp_ram_intf.memory        weight_conv_1x1_i,
           sp_ram_intf.memory        input_conv_1x1_i,
           sp_ram_intf.memory        output_conv_1x1_i,
    // For max pooling unit
    output logic                     gated_maxpool_clk,
           sp_ram_intf.memory        param_maxpool_i,
           sp_ram_intf.memory        bias_maxpool_i,
           sp_ram_intf.memory        weight_maxpool_i,
           sp_ram_intf.memory        input_maxpool_i,
           sp_ram_intf.memory        output_maxpool_i
);

  logic conv_3x3_enb, conv_1x1_enb, maxpool_enb;
  logic [2:0] sel;

  assign conv_3x3_enb = (mode == `CONV_3x3_MODE);
  assign conv_1x1_enb = (mode == `CONV_1x1_MODE);
  assign maxpool_enb = (mode == `MAX_POOL_MODE);
  assign sel = {conv_1x1_enb, conv_3x3_enb, maxpool_enb};

  // Param Bus
  always_comb begin
    param_conv_1x1_i.R_data = 0;
    param_conv_3x3_i.R_data = 0;
    param_maxpool_i.R_data  = 0;
    unique case (1'b1)
      mode[`CONV_1x1_MODE]: begin
        param_conv_1x1_i.R_data = param_o.R_data;
        param_o.cs              = param_conv_1x1_i.cs;
        param_o.oe              = param_conv_1x1_i.oe;
        param_o.addr            = param_conv_1x1_i.addr;
        param_o.W_req           = param_conv_1x1_i.W_req;
        param_o.W_data          = param_conv_1x1_i.W_data;
      end
      mode[`CONV_3x3_MODE]: begin
        param_conv_3x3_i.R_data = param_o.R_data;
        param_o.cs              = param_conv_3x3_i.cs;
        param_o.oe              = param_conv_3x3_i.oe;
        param_o.addr            = param_conv_3x3_i.addr;
        param_o.W_req           = param_conv_3x3_i.W_req;
        param_o.W_data          = param_conv_3x3_i.W_data;
      end
      mode[`MAX_POOL_MODE]: begin
        param_maxpool_i.R_data = param_o.R_data;
        param_o.cs             = param_maxpool_i.cs;
        param_o.oe             = param_maxpool_i.oe;
        param_o.addr           = param_maxpool_i.addr;
        param_o.W_req          = param_maxpool_i.W_req;
        param_o.W_data         = param_maxpool_i.W_data;
      end
      mode[`IDLE_MODE]: begin  // Connect to nothing
        param_o.cs     = 0;
        param_o.oe     = 0;
        param_o.addr   = 0;
        param_o.W_req  = `WRITE_DIS;
        param_o.W_data = 0;
      end
    endcase
  end

  // Bias Bus
  always_comb begin
    bias_conv_1x1_i.R_data = 0;
    bias_conv_3x3_i.R_data = 0;
    bias_maxpool_i.R_data  = 0;
    unique case (1'b1)
      mode[`CONV_1x1_MODE]: begin
        bias_conv_1x1_i.R_data = bias_o.R_data;
        bias_o.cs              = bias_conv_1x1_i.cs;
        bias_o.oe              = bias_conv_1x1_i.oe;
        bias_o.addr            = bias_conv_1x1_i.addr;
        bias_o.W_req           = bias_conv_1x1_i.W_req;
        bias_o.W_data          = bias_conv_1x1_i.W_data;
      end
      mode[`CONV_3x3_MODE]: begin
        bias_conv_3x3_i.R_data = bias_o.R_data;
        bias_o.cs              = bias_conv_3x3_i.cs;
        bias_o.oe              = bias_conv_3x3_i.oe;
        bias_o.addr            = bias_conv_3x3_i.addr;
        bias_o.W_req           = bias_conv_3x3_i.W_req;
        bias_o.W_data          = bias_conv_3x3_i.W_data;
      end
      mode[`MAX_POOL_MODE]: begin
        bias_maxpool_i.R_data = bias_o.R_data;
        bias_o.cs             = bias_maxpool_i.cs;
        bias_o.oe             = bias_maxpool_i.oe;
        bias_o.addr           = bias_maxpool_i.addr;
        bias_o.W_req          = bias_maxpool_i.W_req;
        bias_o.W_data         = bias_maxpool_i.W_data;
      end
      mode[`IDLE_MODE]: begin  // Connect to nothing
        bias_o.cs     = 0;
        bias_o.oe     = 0;
        bias_o.addr   = 0;
        bias_o.W_req  = `WRITE_DIS;
        bias_o.W_data = 0;
      end
    endcase
  end

  // Weight Bus
  always_comb begin
    weight_conv_1x1_i.R_data = 0;
    weight_conv_3x3_i.R_data = 0;
    weight_maxpool_i.R_data  = 0;
    unique case (1'b1)
      mode[`CONV_1x1_MODE]: begin
        weight_conv_1x1_i.R_data = weight_o.R_data;
        weight_o.cs              = weight_conv_1x1_i.cs;
        weight_o.oe              = weight_conv_1x1_i.oe;
        weight_o.addr            = weight_conv_1x1_i.addr;
        weight_o.W_req           = weight_conv_1x1_i.W_req;
        weight_o.W_data          = weight_conv_1x1_i.W_data;
      end
      mode[`CONV_3x3_MODE]: begin
        weight_conv_3x3_i.R_data = weight_o.R_data;
        weight_o.cs              = weight_conv_3x3_i.cs;
        weight_o.oe              = weight_conv_3x3_i.oe;
        weight_o.addr            = weight_conv_3x3_i.addr;
        weight_o.W_req           = weight_conv_3x3_i.W_req;
        weight_o.W_data          = weight_conv_3x3_i.W_data;
      end
      mode[`MAX_POOL_MODE]: begin
        weight_maxpool_i.R_data = weight_o.R_data;
        weight_o.cs             = weight_maxpool_i.cs;
        weight_o.oe             = weight_maxpool_i.oe;
        weight_o.addr           = weight_maxpool_i.addr;
        weight_o.W_req          = weight_maxpool_i.W_req;
        weight_o.W_data         = weight_maxpool_i.W_data;
      end
      mode[`IDLE_MODE]: begin  // Connect to nothing
        weight_o.cs     = 0;
        weight_o.oe     = 0;
        weight_o.addr   = 0;
        weight_o.W_req  = `WRITE_DIS;
        weight_o.W_data = 0;
      end
    endcase
  end

  // Input Bus (port 0)
  always_comb begin
    input_conv_1x1_i.R_data = 0;
    input_conv_3x3_i.R_data = 0;
    input_maxpool_i.R_data  = 0;
    unique case (1'b1)
      mode[`CONV_1x1_MODE]: begin
        input_conv_1x1_i.R_data = input_o.R_data;
        input_o.cs              = input_conv_1x1_i.cs;
        input_o.oe              = input_conv_1x1_i.oe;
        input_o.addr            = input_conv_1x1_i.addr;
        input_o.W_req           = input_conv_1x1_i.W_req;
        input_o.W_data          = input_conv_1x1_i.W_data;
      end
      mode[`CONV_3x3_MODE]: begin
        input_conv_3x3_i.R_data = input_o.R_data;
        input_o.cs              = input_conv_3x3_i.cs;
        input_o.oe              = input_conv_3x3_i.oe;
        input_o.addr            = input_conv_3x3_i.addr;
        input_o.W_req           = input_conv_3x3_i.W_req;
        input_o.W_data          = input_conv_3x3_i.W_data;
      end
      mode[`MAX_POOL_MODE]: begin
        input_maxpool_i.R_data = input_o.R_data;
        input_o.cs             = input_maxpool_i.cs;
        input_o.oe             = input_maxpool_i.oe;
        input_o.addr           = input_maxpool_i.addr;
        input_o.W_req          = input_maxpool_i.W_req;
        input_o.W_data         = input_maxpool_i.W_data;
      end
      mode[`IDLE_MODE]: begin  // Connect to nothing
        input_o.cs     = 0;
        input_o.oe     = 0;
        input_o.addr   = 0;
        input_o.W_req  = `WRITE_DIS;
        input_o.W_data = 0;
      end
    endcase
  end

  // Output Bus (port 0)
  always_comb begin
    output_conv_1x1_i.R_data = 0;
    output_conv_3x3_i.R_data = 0;
    output_maxpool_i.R_data  = 0;
    unique case (1'b1)
      mode[`CONV_1x1_MODE]: begin
        output_conv_1x1_i.R_data = output_o.R_data;
        output_o.cs              = output_conv_1x1_i.cs;
        output_o.oe              = output_conv_1x1_i.oe;
        output_o.addr            = output_conv_1x1_i.addr;
        output_o.W_req           = output_conv_1x1_i.W_req;
        output_o.W_data          = output_conv_1x1_i.W_data;
      end
      mode[`CONV_3x3_MODE]: begin
        output_conv_3x3_i.R_data = output_o.R_data;
        output_o.cs              = output_conv_3x3_i.cs;
        output_o.oe              = output_conv_3x3_i.oe;
        output_o.addr            = output_conv_3x3_i.addr;
        output_o.W_req           = output_conv_3x3_i.W_req;
        output_o.W_data          = output_conv_3x3_i.W_data;
      end
      mode[`MAX_POOL_MODE]: begin
        output_maxpool_i.R_data = output_o.R_data;
        output_o.cs             = output_maxpool_i.cs;
        output_o.oe             = output_maxpool_i.oe;
        output_o.addr           = output_maxpool_i.addr;
        output_o.W_req          = output_maxpool_i.W_req;
        output_o.W_data         = output_maxpool_i.W_data;
      end
      mode[`IDLE_MODE]: begin  // Connect to nothing
        output_o.cs     = 0;
        output_o.oe     = 0;
        output_o.addr   = 0;
        output_o.W_req  = `WRITE_DIS;
        output_o.W_data = 0;
      end
    endcase
  end

  // CG i_CG_conv_3x3(
  //   .CK(clk),
  //   .EN(conv_3x3_enb),
  //   .CKEN(gated_conv_3x3_clk)
  // );

  // CG i_CG_conv_1x1(
  //   .CK(clk),
  //   .EN(conv_1x1_enb),
  //   .CKEN(gated_conv_1x1_clk)
  // );

  // CG i_CG_maxpool(
  //   .CK(clk),
  //   .EN(maxpool_enb),
  //   .CKEN(gated_maxpool_clk)
  // );

endmodule
