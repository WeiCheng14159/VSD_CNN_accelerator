`include "ConvAcc.svh"
`include "sp_ram_intf.sv"

module Max_pool (
    input        clk,
    input        rstn,
    input        start,
    output logic finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

  logic [ 5:0] num_row;
  logic [ 7:0] num_channel;
  logic [31:0] kernel_size;
  logic [10:0] num_input;
  logic [31:0] output_size;

  logic [ 7:0] input_rdata;
  logic [ 7:0] output_wdata;

  logic [10:0] counter;
  logic [ 4:0] row_counter;

  logic [ 2:0] CurrentState;
  logic [ 2:0] NextState;

  parameter	idle_state = 3'h0,
				load_parameter_state = 3'h1,
				load_input_state = 3'h2,
				write_state = 3'h3,
				finish_state = 3'h4;

  assign num_input = (kernel_size == 32'h2) ? 11'h4 : ((kernel_size == 32'h2) ? 11'h40 : 11'h400);
  assign output_size = (kernel_size == 32'h2) ? (((num_row * num_row) >> 2) * num_channel) : ((kernel_size == 32'h2) ? (((num_row * num_row) >> 6) * num_channel) : 32'h2);

  // Param
  assign param_intf.W_req = `WRITE_DIS;
  assign param_intf.W_data = 32'b0;
  assign param_intf.oe = 1'b1;
  // Bias
  assign bias_intf.cs = 1'b0;
  assign bias_intf.addr = 32'b0;
  assign bias_intf.W_req = `WRITE_DIS;
  assign bias_intf.W_data = 32'b0;
  assign bias_intf.oe = 1'b1;
  // Weight
  assign weight_intf.cs = 1'b0;
  assign weight_intf.addr = 32'b0;
  assign weight_intf.W_req = `WRITE_DIS;
  assign weight_intf.W_data = 32'b0;
  assign weight_intf.oe = 1'b1;
  // Input 
  assign input_rdata = input_intf.R_data[7:0];
  assign input_intf.W_req = `WRITE_DIS;
  assign input_intf.W_data = 16'b0;
  assign input_intf.oe = 1'b1;
  // Output
  assign output_intf.W_data = {24'h0, output_wdata};
  assign output_intf.oe = 1'b1;

  //*********************************************//
  //counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) counter <= 11'b0;
    else if (CurrentState == load_parameter_state) begin
      if (counter == 11'h4) counter <= 11'b0;
      else counter <= counter + 11'b1;
    end else if (CurrentState == load_input_state) begin
      if (counter == num_input) counter <= 11'b0;
      else counter <= counter + 11'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) row_counter <= 5'b0;
    else if ((CurrentState == load_input_state) & (counter == num_input)) begin
      if (row_counter == ((num_row >> 1) - 32'b1)) row_counter <= 5'b0;
      else row_counter <= row_counter + 5'b1;
    end
  end
  //counter
  //*********************************************//

  //*********************************************//
  //load parameter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) param_intf.addr <= 32'b0;
    else if ((CurrentState == load_parameter_state)) begin
      if (counter == num_input) param_intf.addr <= 32'b0;
      else param_intf.addr <= param_intf.addr + 3'h1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      num_row <= 32'b0;
      num_channel <= 32'b0;
      kernel_size <= 32'h0;
    end else if ((CurrentState == load_parameter_state)) begin
      case (counter)
        11'h1: num_row <= param_intf.R_data;
        11'h2: num_channel <= param_intf.R_data;
        11'h4: kernel_size <= param_intf.R_data;
      endcase
    end
  end
  //load parameter
  //*********************************************//

  //*********************************************//
  //load input
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) input_intf.addr <= 32'b0;
    else if (CurrentState == load_input_state) begin
      if (kernel_size == 32'h2) begin
        case (counter)
          11'h0: input_intf.addr <= input_intf.addr + 32'b1;
          11'h1: input_intf.addr <= input_intf.addr + num_row - 32'b1;
          11'h2: input_intf.addr <= input_intf.addr + 32'b1;
          11'h3: begin
            if (row_counter == ((num_row >> 1) - 32'b1))
              input_intf.addr <= input_intf.addr + 32'b1;
            else input_intf.addr <= input_intf.addr - num_row + 32'b1;
          end
        endcase
      end else begin
        if (counter != num_input) input_intf.addr <= input_intf.addr + 32'b1;
      end
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_wdata <= 8'b0;
    else if (CurrentState == load_input_state) begin
      if (counter == 11'b0) output_wdata <= 8'h80;
      else begin
        case ({
          output_wdata[7], input_rdata[7]
        })
          2'h0: begin
            if (input_rdata > output_wdata) output_wdata <= input_rdata;
          end
          2'h2: begin
            output_wdata <= input_rdata;
          end
          2'h3: begin
            if (input_rdata > output_wdata) output_wdata <= input_rdata;
          end
        endcase
      end
    end
  end
  //load input
  //*********************************************//

  //*********************************************//
  //write output
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.addr <= 32'b0;
    else if (CurrentState == write_state)
      output_intf.addr <= output_intf.addr + 32'b1;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.W_req <= `WRITE_DIS;
    else if ((CurrentState == load_input_state) & (counter == num_input))
      output_intf.W_req <= `WRITE_ENB;
    else output_intf.W_req <= `WRITE_DIS;
  end
  //write output
  //*********************************************//

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) CurrentState <= idle_state;
    else CurrentState <= NextState;
  end

  always_comb begin
    case (CurrentState)
      idle_state: begin
        if (start) NextState = load_parameter_state;
        else NextState = idle_state;
      end
      load_parameter_state: begin
        if (counter == 11'h4) NextState = load_input_state;
        else NextState = load_parameter_state;
      end
      load_input_state: begin
        if (counter == num_input) NextState = write_state;
        else NextState = load_input_state;
      end
      write_state: begin
        if (output_intf.addr == (output_size - 32'b1)) NextState = finish_state;
        else NextState = load_input_state;
      end
      default: begin
        NextState = idle_state;
      end
    endcase
  end

  always_comb begin
    case (CurrentState)
      idle_state: begin
        param_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_parameter_state: begin
        param_intf.cs = 1'b1;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_input_state: begin
        param_intf.cs = 1'b0;
        input_intf.cs = 1'b1;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      write_state: begin
        param_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b1;
        finish = 1'b0;
      end
      default: begin
        param_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b1;
      end
    endcase
  end


endmodule
