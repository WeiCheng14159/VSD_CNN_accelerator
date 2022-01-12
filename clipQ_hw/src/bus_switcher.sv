
module bus_switcher (
    input logic [1:0] kernel_size,
    // External bus
    sp_ram_intf.compute param_o,
    sp_ram_intf.compute bias_o,
    sp_ram_intf.compute weight_o,
    sp_ram_intf.compute input_o,
    sp_ram_intf.compute output_o,
    // For 3x3 conv unit
    sp_ram_intf.memory param_3x3_i,
    sp_ram_intf.memory bias_3x3_i,
    sp_ram_intf.memory weight_3x3_i,
    sp_ram_intf.memory input_3x3_i,
    sp_ram_intf.memory output_3x3_i,
    // For 1x1 conv unit
    sp_ram_intf.memory param_1x1_i,
    sp_ram_intf.memory bias_1x1_i,
    sp_ram_intf.memory weight_1x1_i,
    sp_ram_intf.memory input_1x1_i,
    sp_ram_intf.memory output_1x1_i
);

  // Param Bus
  always_comb begin
    if (kernel_size == 2'h1) begin
      param_1x1_i.R_data = param_o.R_data;
      param_o.cs         = param_1x1_i.memory.cs;
      param_o.oe         = param_1x1_i.memory.oe;
      param_o.addr       = param_1x1_i.memory.addr;
      param_o.W_req      = param_1x1_i.memory.W_req;
      param_o.W_data     = param_1x1_i.memory.W_data;
    end else if (kernel_size == 2'h3) begin
      param_3x3_i.R_data = param_o.R_data;
      param_o.cs         = param_3x3_i.cs;
      param_o.oe         = param_3x3_i.oe;
      param_o.addr       = param_3x3_i.addr;
      param_o.W_req      = param_3x3_i.W_req;
      param_o.W_data     = param_3x3_i.W_data;
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
    if (kernel_size == 2'h1) begin
      bias_1x1_i.R_data = bias_o.R_data;
      bias_o.cs         = bias_1x1_i.memory.cs;
      bias_o.oe         = bias_1x1_i.memory.oe;
      bias_o.addr       = bias_1x1_i.memory.addr;
      bias_o.W_req      = bias_1x1_i.memory.W_req;
      bias_o.W_data     = bias_1x1_i.memory.W_data;
    end else if (kernel_size == 2'h3) begin
      bias_3x3_i.R_data = bias_o.R_data;
      bias_o.cs         = bias_3x3_i.cs;
      bias_o.oe         = bias_3x3_i.oe;
      bias_o.addr       = bias_3x3_i.addr;
      bias_o.W_req      = bias_3x3_i.W_req;
      bias_o.W_data     = bias_3x3_i.W_data;
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
    if (kernel_size == 2'h1) begin
      weight_1x1_i.R_data = weight_o.R_data;
      weight_o.cs         = weight_1x1_i.memory.cs;
      weight_o.oe         = weight_1x1_i.memory.oe;
      weight_o.addr       = weight_1x1_i.memory.addr;
      weight_o.W_req      = weight_1x1_i.memory.W_req;
      weight_o.W_data     = weight_1x1_i.memory.W_data;
    end else if (kernel_size == 2'h3) begin
      weight_3x3_i.R_data = weight_o.R_data;
      weight_o.cs         = weight_3x3_i.cs;
      weight_o.oe         = weight_3x3_i.oe;
      weight_o.addr       = weight_3x3_i.addr;
      weight_o.W_req      = weight_3x3_i.W_req;
      weight_o.W_data     = weight_3x3_i.W_data;
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
    if (kernel_size == 2'h1) begin
      input_1x1_i.R_data = input_o.R_data;
      input_o.cs         = input_1x1_i.memory.cs;
      input_o.oe         = input_1x1_i.memory.oe;
      input_o.addr       = input_1x1_i.memory.addr;
      input_o.W_req      = input_1x1_i.memory.W_req;
      input_o.W_data     = input_1x1_i.memory.W_data;
    end else if (kernel_size == 2'h3) begin
      input_3x3_i.R_data = input_o.R_data;
      input_o.cs         = input_3x3_i.cs;
      input_o.oe         = input_3x3_i.oe;
      input_o.addr       = input_3x3_i.addr;
      input_o.W_req      = input_3x3_i.W_req;
      input_o.W_data     = input_3x3_i.W_data;
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
    if (kernel_size == 2'h1) begin
      output_1x1_i.R_data = output_o.R_data;
      output_o.cs         = output_1x1_i.memory.cs;
      output_o.oe         = output_1x1_i.memory.oe;
      output_o.addr       = output_1x1_i.memory.addr;
      output_o.W_req      = output_1x1_i.memory.W_req;
      output_o.W_data     = output_1x1_i.memory.W_data;
    end else if (kernel_size == 2'h3) begin
      output_3x3_i.R_data = output_o.R_data;
      output_o.cs         = output_3x3_i.cs;
      output_o.oe         = output_3x3_i.oe;
      output_o.addr       = output_3x3_i.addr;
      output_o.W_req      = output_3x3_i.W_req;
      output_o.W_data     = output_3x3_i.W_data;
    end else begin  // Connect to nothing
      output_o.cs     = 0;
      output_o.oe     = 0;
      output_o.addr   = 0;
      output_o.W_req  = 0;
      output_o.W_data = 0;
    end
  end

endmodule
