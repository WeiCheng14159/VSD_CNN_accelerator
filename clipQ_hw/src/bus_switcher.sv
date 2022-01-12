module bus_switcher
  import conv_acc_pkg::*;
(
    input conv_acc_mode_t mode,
    // External bus
    sp_ram_intf.compute param_o,
    sp_ram_intf.compute bias_o,
    sp_ram_intf.compute weight_o,
    sp_ram_intf.compute input_o,
    sp_ram_intf.compute output_o,
    // For 3x3 conv unit
    sp_ram_intf.memory param_conv_3x3_i,
    sp_ram_intf.memory bias_conv_3x3_i,
    sp_ram_intf.memory weight_conv_3x3_i,
    sp_ram_intf.memory input_conv_3x3_i,
    sp_ram_intf.memory output_conv_3x3_i,
    // For 1x1 conv unit
    sp_ram_intf.memory param_conv_1x1_i,
    sp_ram_intf.memory bias_conv_1x1_i,
    sp_ram_intf.memory weight_conv_1x1_i,
    sp_ram_intf.memory input_conv_1x1_i,
    sp_ram_intf.memory output_conv_1x1_i,
    // For max pooling unit
    sp_ram_intf.memory param_maxpool_i,
    sp_ram_intf.memory bias_maxpool_i,
    sp_ram_intf.memory weight_maxpool_i,
    sp_ram_intf.memory input_maxpool_i,
    sp_ram_intf.memory output_maxpool_i
);

  // Param Bus
  always_comb begin
    if (mode == CONV_1x1_MODE) begin
      param_conv_1x1_i.R_data = param_o.R_data;
      param_o.cs              = param_conv_1x1_i.memory.cs;
      param_o.oe              = param_conv_1x1_i.memory.oe;
      param_o.addr            = param_conv_1x1_i.memory.addr;
      param_o.W_req           = param_conv_1x1_i.memory.W_req;
      param_o.W_data          = param_conv_1x1_i.memory.W_data;
    end else if (mode == CONV_3x3_MODE) begin
      param_conv_3x3_i.R_data = param_o.R_data;
      param_o.cs              = param_conv_3x3_i.cs;
      param_o.oe              = param_conv_3x3_i.oe;
      param_o.addr            = param_conv_3x3_i.addr;
      param_o.W_req           = param_conv_3x3_i.W_req;
      param_o.W_data          = param_conv_3x3_i.W_data;
    end else if (mode == MAX_POOL_MODE) begin
      param_maxpool_i.R_data = param_o.R_data;
      param_o.cs             = param_maxpool_i.cs;
      param_o.oe             = param_maxpool_i.oe;
      param_o.addr           = param_maxpool_i.addr;
      param_o.W_req          = param_maxpool_i.W_req;
      param_o.W_data         = param_maxpool_i.W_data;
    end else begin  // Connect to nothing
      param_o.cs     = 0;
      param_o.oe     = 0;
      param_o.addr   = 0;
      param_o.W_req  = 0;
      param_o.W_data = 0;
    end
  end

  // Bias Bus
  always_comb begin
    if (mode == CONV_1x1_MODE) begin
      bias_conv_1x1_i.R_data = bias_o.R_data;
      bias_o.cs              = bias_conv_1x1_i.memory.cs;
      bias_o.oe              = bias_conv_1x1_i.memory.oe;
      bias_o.addr            = bias_conv_1x1_i.memory.addr;
      bias_o.W_req           = bias_conv_1x1_i.memory.W_req;
      bias_o.W_data          = bias_conv_1x1_i.memory.W_data;
    end else if (mode == CONV_3x3_MODE) begin
      bias_conv_3x3_i.R_data = bias_o.R_data;
      bias_o.cs              = bias_conv_3x3_i.cs;
      bias_o.oe              = bias_conv_3x3_i.oe;
      bias_o.addr            = bias_conv_3x3_i.addr;
      bias_o.W_req           = bias_conv_3x3_i.W_req;
      bias_o.W_data          = bias_conv_3x3_i.W_data;
    end else if (mode == MAX_POOL_MODE) begin
      bias_maxpool_i.R_data = bias_o.R_data;
      bias_o.cs             = bias_maxpool_i.cs;
      bias_o.oe             = bias_maxpool_i.oe;
      bias_o.addr           = bias_maxpool_i.addr;
      bias_o.W_req          = bias_maxpool_i.W_req;
      bias_o.W_data         = bias_maxpool_i.W_data;
    end else begin  // Connect to nothing
      bias_o.cs     = 0;
      bias_o.oe     = 0;
      bias_o.addr   = 0;
      bias_o.W_req  = 0;
      bias_o.W_data = 0;
    end
  end

  // Weight Bus
  always_comb begin
    if (mode == CONV_1x1_MODE) begin
      weight_conv_1x1_i.R_data = weight_o.R_data;
      weight_o.cs              = weight_conv_1x1_i.memory.cs;
      weight_o.oe              = weight_conv_1x1_i.memory.oe;
      weight_o.addr            = weight_conv_1x1_i.memory.addr;
      weight_o.W_req           = weight_conv_1x1_i.memory.W_req;
      weight_o.W_data          = weight_conv_1x1_i.memory.W_data;
    end else if (mode == CONV_3x3_MODE) begin
      weight_conv_3x3_i.R_data = weight_o.R_data;
      weight_o.cs              = weight_conv_3x3_i.cs;
      weight_o.oe              = weight_conv_3x3_i.oe;
      weight_o.addr            = weight_conv_3x3_i.addr;
      weight_o.W_req           = weight_conv_3x3_i.W_req;
      weight_o.W_data          = weight_conv_3x3_i.W_data;
    end else if (mode == MAX_POOL_MODE) begin
      weight_maxpool_i.R_data = weight_o.R_data;
      weight_o.cs             = weight_maxpool_i.cs;
      weight_o.oe             = weight_maxpool_i.oe;
      weight_o.addr           = weight_maxpool_i.addr;
      weight_o.W_req          = weight_maxpool_i.W_req;
      weight_o.W_data         = weight_maxpool_i.W_data;
    end else begin  // Connect to nothing
      weight_o.cs     = 0;
      weight_o.oe     = 0;
      weight_o.addr   = 0;
      weight_o.W_req  = 0;
      weight_o.W_data = 0;
    end
  end

  // Input Bus
  always_comb begin
    if (mode == CONV_1x1_MODE) begin
      input_conv_1x1_i.R_data = input_o.R_data;
      input_o.cs              = input_conv_1x1_i.memory.cs;
      input_o.oe              = input_conv_1x1_i.memory.oe;
      input_o.addr            = input_conv_1x1_i.memory.addr;
      input_o.W_req           = input_conv_1x1_i.memory.W_req;
      input_o.W_data          = input_conv_1x1_i.memory.W_data;
    end else if (mode == CONV_3x3_MODE) begin
      input_conv_3x3_i.R_data = input_o.R_data;
      input_o.cs              = input_conv_3x3_i.cs;
      input_o.oe              = input_conv_3x3_i.oe;
      input_o.addr            = input_conv_3x3_i.addr;
      input_o.W_req           = input_conv_3x3_i.W_req;
      input_o.W_data          = input_conv_3x3_i.W_data;
    end else if (mode == MAX_POOL_MODE) begin
      input_maxpool_i.R_data = input_o.R_data;
      input_o.cs             = input_maxpool_i.cs;
      input_o.oe             = input_maxpool_i.oe;
      input_o.addr           = input_maxpool_i.addr;
      input_o.W_req          = input_maxpool_i.W_req;
      input_o.W_data         = input_maxpool_i.W_data;
    end else begin  // Connect to nothing
      input_o.cs     = 0;
      input_o.oe     = 0;
      input_o.addr   = 0;
      input_o.W_req  = 0;
      input_o.W_data = 0;
    end
  end

  // Output Bus
  always_comb begin
    if (mode == CONV_1x1_MODE) begin
      output_conv_1x1_i.R_data = output_o.R_data;
      output_o.cs              = output_conv_1x1_i.memory.cs;
      output_o.oe              = output_conv_1x1_i.memory.oe;
      output_o.addr            = output_conv_1x1_i.memory.addr;
      output_o.W_req           = output_conv_1x1_i.memory.W_req;
      output_o.W_data          = output_conv_1x1_i.memory.W_data;
    end else if (mode == CONV_3x3_MODE) begin
      output_conv_3x3_i.R_data = output_o.R_data;
      output_o.cs              = output_conv_3x3_i.cs;
      output_o.oe              = output_conv_3x3_i.oe;
      output_o.addr            = output_conv_3x3_i.addr;
      output_o.W_req           = output_conv_3x3_i.W_req;
      output_o.W_data          = output_conv_3x3_i.W_data;
    end else if (mode == MAX_POOL_MODE) begin
      output_maxpool_i.R_data = output_o.R_data;
      output_o.cs             = output_maxpool_i.cs;
      output_o.oe             = output_maxpool_i.oe;
      output_o.addr           = output_maxpool_i.addr;
      output_o.W_req          = output_maxpool_i.W_req;
      output_o.W_data         = output_maxpool_i.W_data;
    end else begin  // Connect to nothing
      output_o.cs     = 0;
      output_o.oe     = 0;
      output_o.addr   = 0;
      output_o.W_req  = 0;
      output_o.W_data = 0;
    end
  end

endmodule
