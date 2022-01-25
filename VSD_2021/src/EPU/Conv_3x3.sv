`include "ConvAcc.svh"

module Conv_3x3 (
    input               clk,
    input               rstn,
    input        [31:0] w8,
    input               start,
    output logic        finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

  logic [2:0] num_input;
  logic [31:0] num_row;
  logic [31:0] num_channel;
  logic [31:0] num_kernel;
  logic [31:0] w8_temp;

  logic [31:0] input_2D_size;

  logic signed [7:0] data[8:0];
  logic signed [7:0] weight_0[8:0];
  logic signed [7:0] weight_1[8:0];
  logic signed [7:0] weight_2[8:0];
  logic signed [7:0] weight_3[8:0];
  logic signed [15:0] partial_sum_0[8:0];
  logic signed [15:0] partial_sum_1[8:0];
  logic signed [15:0] partial_sum_2[8:0];
  logic signed [15:0] partial_sum_3[8:0];
  logic signed [31:0] bias_0;
  logic signed [31:0] bias_1;
  logic signed [31:0] bias_2;
  logic signed [31:0] bias_3;
  logic signed [15:0] sum_0;
  logic signed [15:0] sum_1;
  logic signed [15:0] sum_2;
  logic signed [15:0] sum_3;

  logic [17:0] weight_rdata;
  logic [15:0] input_rdata;
  logic [15:0] output_rdata;
  logic [15:0] output_wdata;

  logic [3:0] counter;
  logic [4:0] row_counter;
  logic [4:0] col_counter;
  logic [9:0] cha_counter;
  logic [9:0] ker_counter;
  logic [3:0] index;

  logic [2:0] CurrentState;
  logic [2:0] NextState;

  parameter	idle_state = 3'h0,
				load_parameter_state = 3'h1,
				load_bias_state = 3'h2,
				load_weight_state = 3'h3,
				load_input_state = 3'h4,
				calculate_state = 3'h5,
				write_state = 3'h6,
				finish_state = 3'h7;

  // Param
  assign param_intf.W_req = `WRITE_DIS;
  assign param_intf.W_data = 32'b0;
  assign param_intf.oe = 1'b1;
  // Bias
  assign bias_intf.W_req = `WRITE_DIS;
  assign bias_intf.W_data = 32'b0;
  assign bias_intf.oe = 1'b1;
  // Weight
  assign weight_intf.W_req = `WRITE_DIS;
  assign weight_intf.W_data = 32'b0;
  assign weight_rdata = weight_intf.R_data[17:0];
  assign weight_intf.oe = 1'b1;
  // Input 
  assign input_intf.W_req = `WRITE_DIS;
  assign input_intf.W_data = 16'b0;
  assign input_rdata = input_intf.R_data[15:0];
  assign input_intf.oe = 1'b1;
  // Output
  assign output_rdata = output_intf.R_data[15:0];
  assign output_intf.W_data = {16'h0, output_wdata};
  assign output_intf.oe = 1'b1;

  assign input_2D_size = num_row * num_row;

  //*********************************************//
  //PE
  assign sum_0 = output_rdata + partial_sum_0[0];
  assign sum_1 = output_rdata + partial_sum_1[0];
  assign sum_2 = output_rdata + partial_sum_2[0];
  assign sum_3 = output_rdata + partial_sum_3[0];

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) w8_temp <= 32'b0;
    else if (start) w8_temp <= w8;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      partial_sum_0[0] <= 16'b0;
      partial_sum_0[1] <= 16'b0;
      partial_sum_0[2] <= 16'b0;
      partial_sum_0[3] <= 16'b0;
      partial_sum_0[4] <= 16'b0;
      partial_sum_0[5] <= 16'b0;
      partial_sum_0[6] <= 16'b0;
      partial_sum_0[7] <= 16'b0;
      partial_sum_0[8] <= 16'b0;
    end else if (CurrentState == calculate_state) begin
      partial_sum_0[0] <= data[0] * weight_0[0];
      partial_sum_0[1] <= data[1] * weight_0[1];
      partial_sum_0[2] <= data[2] * weight_0[2];
      partial_sum_0[3] <= data[3] * weight_0[3];
      partial_sum_0[4] <= data[4] * weight_0[4];
      partial_sum_0[5] <= data[5] * weight_0[5];
      partial_sum_0[6] <= data[6] * weight_0[6];
      partial_sum_0[7] <= data[7] * weight_0[7];
      partial_sum_0[8] <= data[8] * weight_0[8];
    end else if ((CurrentState == write_state) & (counter == 4'b0))
      partial_sum_0[0] <= partial_sum_0[0] + partial_sum_0[1] + partial_sum_0[2] + partial_sum_0[3] + partial_sum_0[4] + partial_sum_0[5] + partial_sum_0[6] + partial_sum_0[7] + partial_sum_0[8];
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      partial_sum_1[0] <= 16'b0;
      partial_sum_1[1] <= 16'b0;
      partial_sum_1[2] <= 16'b0;
      partial_sum_1[3] <= 16'b0;
      partial_sum_1[4] <= 16'b0;
      partial_sum_1[5] <= 16'b0;
      partial_sum_1[6] <= 16'b0;
      partial_sum_1[7] <= 16'b0;
      partial_sum_1[8] <= 16'b0;
    end else if (CurrentState == calculate_state) begin
      partial_sum_1[0] <= data[0] * weight_1[0];
      partial_sum_1[1] <= data[1] * weight_1[1];
      partial_sum_1[2] <= data[2] * weight_1[2];
      partial_sum_1[3] <= data[3] * weight_1[3];
      partial_sum_1[4] <= data[4] * weight_1[4];
      partial_sum_1[5] <= data[5] * weight_1[5];
      partial_sum_1[6] <= data[6] * weight_1[6];
      partial_sum_1[7] <= data[7] * weight_1[7];
      partial_sum_1[8] <= data[8] * weight_1[8];
    end else if ((CurrentState == write_state) & (counter == 4'b0))
      partial_sum_1[0] <= partial_sum_1[0] + partial_sum_1[1] + partial_sum_1[2] + partial_sum_1[3] + partial_sum_1[4] + partial_sum_1[5] + partial_sum_1[6] + partial_sum_1[7] + partial_sum_1[8];
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      partial_sum_2[0] <= 16'b0;
      partial_sum_2[1] <= 16'b0;
      partial_sum_2[2] <= 16'b0;
      partial_sum_2[3] <= 16'b0;
      partial_sum_2[4] <= 16'b0;
      partial_sum_2[5] <= 16'b0;
      partial_sum_2[6] <= 16'b0;
      partial_sum_2[7] <= 16'b0;
      partial_sum_2[8] <= 16'b0;
    end else if (CurrentState == calculate_state) begin
      partial_sum_2[0] <= data[0] * weight_2[0];
      partial_sum_2[1] <= data[1] * weight_2[1];
      partial_sum_2[2] <= data[2] * weight_2[2];
      partial_sum_2[3] <= data[3] * weight_2[3];
      partial_sum_2[4] <= data[4] * weight_2[4];
      partial_sum_2[5] <= data[5] * weight_2[5];
      partial_sum_2[6] <= data[6] * weight_2[6];
      partial_sum_2[7] <= data[7] * weight_2[7];
      partial_sum_2[8] <= data[8] * weight_2[8];
    end else if ((CurrentState == write_state) & (counter == 4'b0))
      partial_sum_2[0] <= partial_sum_2[0] + partial_sum_2[1] + partial_sum_2[2] + partial_sum_2[3] + partial_sum_2[4] + partial_sum_2[5] + partial_sum_2[6] + partial_sum_2[7] + partial_sum_2[8];
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      partial_sum_3[0] <= 16'b0;
      partial_sum_3[1] <= 16'b0;
      partial_sum_3[2] <= 16'b0;
      partial_sum_3[3] <= 16'b0;
      partial_sum_3[4] <= 16'b0;
      partial_sum_3[5] <= 16'b0;
      partial_sum_3[6] <= 16'b0;
      partial_sum_3[7] <= 16'b0;
      partial_sum_3[8] <= 16'b0;
    end else if (CurrentState == calculate_state) begin
      partial_sum_3[0] <= data[0] * weight_3[0];
      partial_sum_3[1] <= data[1] * weight_3[1];
      partial_sum_3[2] <= data[2] * weight_3[2];
      partial_sum_3[3] <= data[3] * weight_3[3];
      partial_sum_3[4] <= data[4] * weight_3[4];
      partial_sum_3[5] <= data[5] * weight_3[5];
      partial_sum_3[6] <= data[6] * weight_3[6];
      partial_sum_3[7] <= data[7] * weight_3[7];
      partial_sum_3[8] <= data[8] * weight_3[8];
    end else if ((CurrentState == write_state) & (counter == 4'b0))
      partial_sum_3[0] <= partial_sum_3[0] + partial_sum_3[1] + partial_sum_3[2] + partial_sum_3[3] + partial_sum_3[4] + partial_sum_3[5] + partial_sum_3[6] + partial_sum_3[7] + partial_sum_3[8];
  end
  //PE
  //*********************************************//

  //*********************************************//
  //counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) counter <= 4'b0;
    else if (CurrentState == load_parameter_state) begin
      if (counter == 4'h3) counter <= 4'b0;
      else counter <= counter + 4'b1;
    end else if (CurrentState == load_bias_state) begin
      if (counter == 4'h4) counter <= 4'b0;
      else counter <= counter + 4'b1;
    end else if (CurrentState == load_weight_state) begin
      if (counter == 4'h4) counter <= 4'b0;
      else counter <= counter + 4'b1;
    end else if (CurrentState == load_input_state) begin
      if (counter == num_input) counter <= 4'b0;
      else counter <= counter + 4'b1;
    end else if (CurrentState == write_state) begin
      if (counter == 4'hb) counter <= 4'b0;
      else counter <= counter + 4'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) row_counter <= 5'b0;
    else if ((CurrentState == load_input_state) & (counter == num_input)) begin
      if (row_counter == (num_row - 32'b1)) row_counter <= 5'b0;
      else row_counter <= row_counter + 5'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) col_counter <= 5'b0;
    else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 32'b1)))begin
      if (col_counter == (num_row - 32'b1)) col_counter <= 5'b0;
      else col_counter <= col_counter + 5'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) cha_counter <= 10'b0;
    else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 32'b1)) & (col_counter == (num_row - 32'b1)))begin
      if (cha_counter == (num_channel - 32'b1)) cha_counter <= 10'b0;
      else cha_counter <= cha_counter + 10'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) ker_counter <= 10'b0;
    else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 32'b1)) & (col_counter == (num_row - 32'b1)) & (cha_counter == (num_channel - 32'b1)))begin
      if (ker_counter == (num_kernel - 32'h4)) ker_counter <= 10'b0;
      else ker_counter <= ker_counter + 10'h4;
    end
  end
  //counter
  //*********************************************//

  //*********************************************//
  //load parameter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) param_intf.addr <= 32'b0;
    else if ((CurrentState == load_parameter_state)) begin
      if (counter == 4'h3) param_intf.addr <= 32'b0;
      else param_intf.addr <= param_intf.addr + 32'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      num_row <= 32'b0;
      num_channel <= 32'b0;
      num_kernel <= 32'b0;
    end else if ((CurrentState == load_parameter_state)) begin
      case (counter)
        4'h1: num_row <= param_intf.R_data;
        4'h2: num_channel <= param_intf.R_data;
        4'h3: num_kernel <= param_intf.R_data;
      endcase
    end
  end
  //load parameter
  //*********************************************//

  //*********************************************//
  //load bias
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) bias_intf.addr <= 32'b0;
    else if ((CurrentState == load_bias_state) & (counter != 4'h4))
      bias_intf.addr <= bias_intf.addr + 32'b1;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      bias_0 <= 32'b0;
      bias_1 <= 32'b0;
      bias_2 <= 32'b0;
      bias_3 <= 32'b0;
    end else if (CurrentState == load_bias_state) begin
      case (counter)
        4'h1: bias_0 <= bias_intf.R_data;
        4'h2: bias_1 <= bias_intf.R_data;
        4'h3: bias_2 <= bias_intf.R_data;
        4'h4: bias_3 <= bias_intf.R_data;
      endcase
    end
  end
  //load bias
  //*********************************************//

  //*********************************************//
  //load weight
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) weight_intf.addr <= 32'b0;
    else if (CurrentState == load_weight_state) begin
      if (counter == 4'h3) begin
        if (cha_counter == (num_channel - 32'b1))
          weight_intf.addr <= weight_intf.addr + 32'h1;
        else weight_intf.addr <= weight_intf.addr - 32'h8;
      end else if (counter != 4'h4)
        weight_intf.addr <= weight_intf.addr + 32'h3;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      weight_0[0] <= 8'b0;
      weight_0[1] <= 8'b0;
      weight_0[2] <= 8'b0;
      weight_0[3] <= 8'b0;
      weight_0[4] <= 8'b0;
      weight_0[5] <= 8'b0;
      weight_0[6] <= 8'b0;
      weight_0[7] <= 8'b0;
      weight_0[8] <= 8'b0;
    end else if ((CurrentState == load_weight_state) & (counter == 4'h1)) begin
      case (weight_rdata[1:0])
        2'b00: weight_0[0] <= w8_temp[7:0];
        2'b01: weight_0[0] <= w8_temp[15:8];
        2'b10: weight_0[0] <= w8_temp[23:16];
        2'b11: weight_0[0] <= w8_temp[31:24];
      endcase
      case (weight_rdata[3:2])
        2'b00: weight_0[1] <= w8_temp[7:0];
        2'b01: weight_0[1] <= w8_temp[15:8];
        2'b10: weight_0[1] <= w8_temp[23:16];
        2'b11: weight_0[1] <= w8_temp[31:24];
      endcase
      case (weight_rdata[5:4])
        2'b00: weight_0[2] <= w8_temp[7:0];
        2'b01: weight_0[2] <= w8_temp[15:8];
        2'b10: weight_0[2] <= w8_temp[23:16];
        2'b11: weight_0[2] <= w8_temp[31:24];
      endcase
      case (weight_rdata[7:6])
        2'b00: weight_0[3] <= w8_temp[7:0];
        2'b01: weight_0[3] <= w8_temp[15:8];
        2'b10: weight_0[3] <= w8_temp[23:16];
        2'b11: weight_0[3] <= w8_temp[31:24];
      endcase
      case (weight_rdata[9:8])
        2'b00: weight_0[4] <= w8_temp[7:0];
        2'b01: weight_0[4] <= w8_temp[15:8];
        2'b10: weight_0[4] <= w8_temp[23:16];
        2'b11: weight_0[4] <= w8_temp[31:24];
      endcase
      case (weight_rdata[11:10])
        2'b00: weight_0[5] <= w8_temp[7:0];
        2'b01: weight_0[5] <= w8_temp[15:8];
        2'b10: weight_0[5] <= w8_temp[23:16];
        2'b11: weight_0[5] <= w8_temp[31:24];
      endcase
      case (weight_rdata[13:12])
        2'b00: weight_0[6] <= w8_temp[7:0];
        2'b01: weight_0[6] <= w8_temp[15:8];
        2'b10: weight_0[6] <= w8_temp[23:16];
        2'b11: weight_0[6] <= w8_temp[31:24];
      endcase
      case (weight_rdata[15:14])
        2'b00: weight_0[7] <= w8_temp[7:0];
        2'b01: weight_0[7] <= w8_temp[15:8];
        2'b10: weight_0[7] <= w8_temp[23:16];
        2'b11: weight_0[7] <= w8_temp[31:24];
      endcase
      case (weight_rdata[17:16])
        2'b00: weight_0[8] <= w8_temp[7:0];
        2'b01: weight_0[8] <= w8_temp[15:8];
        2'b10: weight_0[8] <= w8_temp[23:16];
        2'b11: weight_0[8] <= w8_temp[31:24];
      endcase
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      weight_1[0] <= 8'b0;
      weight_1[1] <= 8'b0;
      weight_1[2] <= 8'b0;
      weight_1[3] <= 8'b0;
      weight_1[4] <= 8'b0;
      weight_1[5] <= 8'b0;
      weight_1[6] <= 8'b0;
      weight_1[7] <= 8'b0;
      weight_1[8] <= 8'b0;
    end else if ((CurrentState == load_weight_state) & (counter == 4'h2)) begin
      case (weight_rdata[1:0])
        2'b00: weight_1[0] <= w8_temp[7:0];
        2'b01: weight_1[0] <= w8_temp[15:8];
        2'b10: weight_1[0] <= w8_temp[23:16];
        2'b11: weight_1[0] <= w8_temp[31:24];
      endcase
      case (weight_rdata[3:2])
        2'b00: weight_1[1] <= w8_temp[7:0];
        2'b01: weight_1[1] <= w8_temp[15:8];
        2'b10: weight_1[1] <= w8_temp[23:16];
        2'b11: weight_1[1] <= w8_temp[31:24];
      endcase
      case (weight_rdata[5:4])
        2'b00: weight_1[2] <= w8_temp[7:0];
        2'b01: weight_1[2] <= w8_temp[15:8];
        2'b10: weight_1[2] <= w8_temp[23:16];
        2'b11: weight_1[2] <= w8_temp[31:24];
      endcase
      case (weight_rdata[7:6])
        2'b00: weight_1[3] <= w8_temp[7:0];
        2'b01: weight_1[3] <= w8_temp[15:8];
        2'b10: weight_1[3] <= w8_temp[23:16];
        2'b11: weight_1[3] <= w8_temp[31:24];
      endcase
      case (weight_rdata[9:8])
        2'b00: weight_1[4] <= w8_temp[7:0];
        2'b01: weight_1[4] <= w8_temp[15:8];
        2'b10: weight_1[4] <= w8_temp[23:16];
        2'b11: weight_1[4] <= w8_temp[31:24];
      endcase
      case (weight_rdata[11:10])
        2'b00: weight_1[5] <= w8_temp[7:0];
        2'b01: weight_1[5] <= w8_temp[15:8];
        2'b10: weight_1[5] <= w8_temp[23:16];
        2'b11: weight_1[5] <= w8_temp[31:24];
      endcase
      case (weight_rdata[13:12])
        2'b00: weight_1[6] <= w8_temp[7:0];
        2'b01: weight_1[6] <= w8_temp[15:8];
        2'b10: weight_1[6] <= w8_temp[23:16];
        2'b11: weight_1[6] <= w8_temp[31:24];
      endcase
      case (weight_rdata[15:14])
        2'b00: weight_1[7] <= w8_temp[7:0];
        2'b01: weight_1[7] <= w8_temp[15:8];
        2'b10: weight_1[7] <= w8_temp[23:16];
        2'b11: weight_1[7] <= w8_temp[31:24];
      endcase
      case (weight_rdata[17:16])
        2'b00: weight_1[8] <= w8_temp[7:0];
        2'b01: weight_1[8] <= w8_temp[15:8];
        2'b10: weight_1[8] <= w8_temp[23:16];
        2'b11: weight_1[8] <= w8_temp[31:24];
      endcase
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      weight_2[0] <= 8'b0;
      weight_2[1] <= 8'b0;
      weight_2[2] <= 8'b0;
      weight_2[3] <= 8'b0;
      weight_2[4] <= 8'b0;
      weight_2[5] <= 8'b0;
      weight_2[6] <= 8'b0;
      weight_2[7] <= 8'b0;
      weight_2[8] <= 8'b0;
    end else if ((CurrentState == load_weight_state) & (counter == 4'h3)) begin
      case (weight_rdata[1:0])
        2'b00: weight_2[0] <= w8_temp[7:0];
        2'b01: weight_2[0] <= w8_temp[15:8];
        2'b10: weight_2[0] <= w8_temp[23:16];
        2'b11: weight_2[0] <= w8_temp[31:24];
      endcase
      case (weight_rdata[3:2])
        2'b00: weight_2[1] <= w8_temp[7:0];
        2'b01: weight_2[1] <= w8_temp[15:8];
        2'b10: weight_2[1] <= w8_temp[23:16];
        2'b11: weight_2[1] <= w8_temp[31:24];
      endcase
      case (weight_rdata[5:4])
        2'b00: weight_2[2] <= w8_temp[7:0];
        2'b01: weight_2[2] <= w8_temp[15:8];
        2'b10: weight_2[2] <= w8_temp[23:16];
        2'b11: weight_2[2] <= w8_temp[31:24];
      endcase
      case (weight_rdata[7:6])
        2'b00: weight_2[3] <= w8_temp[7:0];
        2'b01: weight_2[3] <= w8_temp[15:8];
        2'b10: weight_2[3] <= w8_temp[23:16];
        2'b11: weight_2[3] <= w8_temp[31:24];
      endcase
      case (weight_rdata[9:8])
        2'b00: weight_2[4] <= w8_temp[7:0];
        2'b01: weight_2[4] <= w8_temp[15:8];
        2'b10: weight_2[4] <= w8_temp[23:16];
        2'b11: weight_2[4] <= w8_temp[31:24];
      endcase
      case (weight_rdata[11:10])
        2'b00: weight_2[5] <= w8_temp[7:0];
        2'b01: weight_2[5] <= w8_temp[15:8];
        2'b10: weight_2[5] <= w8_temp[23:16];
        2'b11: weight_2[5] <= w8_temp[31:24];
      endcase
      case (weight_rdata[13:12])
        2'b00: weight_2[6] <= w8_temp[7:0];
        2'b01: weight_2[6] <= w8_temp[15:8];
        2'b10: weight_2[6] <= w8_temp[23:16];
        2'b11: weight_2[6] <= w8_temp[31:24];
      endcase
      case (weight_rdata[15:14])
        2'b00: weight_2[7] <= w8_temp[7:0];
        2'b01: weight_2[7] <= w8_temp[15:8];
        2'b10: weight_2[7] <= w8_temp[23:16];
        2'b11: weight_2[7] <= w8_temp[31:24];
      endcase
      case (weight_rdata[17:16])
        2'b00: weight_2[8] <= w8_temp[7:0];
        2'b01: weight_2[8] <= w8_temp[15:8];
        2'b10: weight_2[8] <= w8_temp[23:16];
        2'b11: weight_2[8] <= w8_temp[31:24];
      endcase
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      weight_3[0] <= 8'b0;
      weight_3[1] <= 8'b0;
      weight_3[2] <= 8'b0;
      weight_3[3] <= 8'b0;
      weight_3[4] <= 8'b0;
      weight_3[5] <= 8'b0;
      weight_3[6] <= 8'b0;
      weight_3[7] <= 8'b0;
      weight_3[8] <= 8'b0;
    end else if ((CurrentState == load_weight_state) & (counter == 4'h4)) begin
      case (weight_rdata[1:0])
        2'b00: weight_3[0] <= w8_temp[7:0];
        2'b01: weight_3[0] <= w8_temp[15:8];
        2'b10: weight_3[0] <= w8_temp[23:16];
        2'b11: weight_3[0] <= w8_temp[31:24];
      endcase
      case (weight_rdata[3:2])
        2'b00: weight_3[1] <= w8_temp[7:0];
        2'b01: weight_3[1] <= w8_temp[15:8];
        2'b10: weight_3[1] <= w8_temp[23:16];
        2'b11: weight_3[1] <= w8_temp[31:24];
      endcase
      case (weight_rdata[5:4])
        2'b00: weight_3[2] <= w8_temp[7:0];
        2'b01: weight_3[2] <= w8_temp[15:8];
        2'b10: weight_3[2] <= w8_temp[23:16];
        2'b11: weight_3[2] <= w8_temp[31:24];
      endcase
      case (weight_rdata[7:6])
        2'b00: weight_3[3] <= w8_temp[7:0];
        2'b01: weight_3[3] <= w8_temp[15:8];
        2'b10: weight_3[3] <= w8_temp[23:16];
        2'b11: weight_3[3] <= w8_temp[31:24];
      endcase
      case (weight_rdata[9:8])
        2'b00: weight_3[4] <= w8_temp[7:0];
        2'b01: weight_3[4] <= w8_temp[15:8];
        2'b10: weight_3[4] <= w8_temp[23:16];
        2'b11: weight_3[4] <= w8_temp[31:24];
      endcase
      case (weight_rdata[11:10])
        2'b00: weight_3[5] <= w8_temp[7:0];
        2'b01: weight_3[5] <= w8_temp[15:8];
        2'b10: weight_3[5] <= w8_temp[23:16];
        2'b11: weight_3[5] <= w8_temp[31:24];
      endcase
      case (weight_rdata[13:12])
        2'b00: weight_3[6] <= w8_temp[7:0];
        2'b01: weight_3[6] <= w8_temp[15:8];
        2'b10: weight_3[6] <= w8_temp[23:16];
        2'b11: weight_3[6] <= w8_temp[31:24];
      endcase
      case (weight_rdata[15:14])
        2'b00: weight_3[7] <= w8_temp[7:0];
        2'b01: weight_3[7] <= w8_temp[15:8];
        2'b10: weight_3[7] <= w8_temp[23:16];
        2'b11: weight_3[7] <= w8_temp[31:24];
      endcase
      case (weight_rdata[17:16])
        2'b00: weight_3[8] <= w8_temp[7:0];
        2'b01: weight_3[8] <= w8_temp[15:8];
        2'b10: weight_3[8] <= w8_temp[23:16];
        2'b11: weight_3[8] <= w8_temp[31:24];
      endcase
    end
  end
  //load weight
  //*********************************************//

  //*********************************************//
  //load input
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) num_input <= 3'b0;
    else if (CurrentState == load_weight_state) num_input <= 3'h4;
    else if (CurrentState == write_state) begin
      if ((row_counter == 5'b0) & (col_counter == (num_row - 32'b1)))
        num_input <= 3'h4;
      else if (row_counter == 5'b0) num_input <= 3'h6;
      else if (row_counter == (num_row - 32'b1)) num_input <= 3'h0;
      else if (col_counter == 5'b0) num_input <= 3'h2;
      else if (col_counter == (num_row - 32'b1)) num_input <= 3'h2;
      else num_input <= 3'h3;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) index <= 4'b0;
    else if (CurrentState == load_input_state) begin
      if ((row_counter == 5'b0) & (col_counter == 5'b0)) begin
        case (counter)
          4'h0: index <= 4'h4;
          4'h1: index <= 4'h5;
          4'h2: index <= 4'h7;
          4'h3: index <= 4'h8;
        endcase
      end
			else if((row_counter == 5'b0) & (col_counter == (num_row - 32'b1)))begin
        case (counter)
          4'h0: index <= 4'h1;
          4'h1: index <= 4'h2;
          4'h2: index <= 4'h4;
          4'h3: index <= 4'h5;
        endcase
      end else if (row_counter == 5'b0) begin
        case (counter)
          4'h0: index <= 4'h1;
          4'h1: index <= 4'h2;
          4'h2: index <= 4'h4;
          4'h3: index <= 4'h5;
          4'h4: index <= 4'h7;
          4'h5: index <= 4'h8;
        endcase
      end else if (col_counter == 5'b0) begin
        case (counter)
          4'h0: index <= 4'h5;
          4'h1: index <= 4'h8;
        endcase
      end else if (col_counter == (num_row - 32'b1)) begin
        case (counter)
          4'h0: index <= 4'h2;
          4'h1: index <= 4'h5;
        endcase
      end else begin
        case (counter)
          4'h0: index <= 4'h2;
          4'h1: index <= 4'h5;
          4'h2: index <= 4'h8;
        endcase
      end
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) input_intf.addr <= 32'b0;
    else if (CurrentState == load_weight_state)
      input_intf.addr <= cha_counter * input_2D_size;
    else if (CurrentState == load_input_state) begin
      if ((row_counter == 5'b0) & (col_counter == 5'b0)) begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + 32'b1;
          4'h1: input_intf.addr <= input_intf.addr + num_row - 32'b1;
          4'h2: input_intf.addr <= input_intf.addr + 32'b1;
          4'h3: input_intf.addr <= input_intf.addr - num_row + 32'b1;
        endcase
      end
			else if((row_counter == 5'b0) & (col_counter == (num_row - 32'b1)))begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + 32'b1;
          4'h1: input_intf.addr <= input_intf.addr + num_row - 32'b1;
          4'h2: input_intf.addr <= input_intf.addr + 32'b1;
          4'h3: input_intf.addr <= input_intf.addr - num_row + 32'b1;
        endcase
      end else if (row_counter == 5'b0) begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + 32'b1;
          4'h1: input_intf.addr <= input_intf.addr + num_row - 32'b1;
          4'h2: input_intf.addr <= input_intf.addr + 32'b1;
          4'h3: input_intf.addr <= input_intf.addr + num_row - 32'b1;
          4'h4: input_intf.addr <= input_intf.addr + 32'b1;
          4'h5: input_intf.addr <= input_intf.addr - (2 * num_row) + 32'b1;
        endcase
      end else if (row_counter == (num_row - 32'b1)) begin
        if (col_counter == 5'b0) input_intf.addr <= input_intf.addr - num_row;
        else if (col_counter == (num_row - 32'b1))
          input_intf.addr <= input_intf.addr + num_row;
      end else if (col_counter == 5'b0) begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + num_row;
          4'h1: input_intf.addr <= input_intf.addr - num_row + 32'b1;
        endcase
      end else if (col_counter == (num_row - 32'b1)) begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + num_row;
          4'h1: input_intf.addr <= input_intf.addr - num_row + 32'b1;
        endcase
      end else begin
        case (counter)
          4'h0: input_intf.addr <= input_intf.addr + num_row;
          4'h1: input_intf.addr <= input_intf.addr + num_row;
          4'h2: input_intf.addr <= input_intf.addr - (2 * num_row) + 32'b1;
        endcase
      end
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      data[0] <= 8'b0;
      data[1] <= 8'b0;
      data[2] <= 8'b0;
      data[3] <= 8'b0;
      data[4] <= 8'b0;
      data[5] <= 8'b0;
      data[6] <= 8'b0;
      data[7] <= 8'b0;
      data[8] <= 8'b0;
    end else if (CurrentState == load_input_state) begin
      if (counter == 4'h0) begin
        if (row_counter == 5'b0) begin
          data[0] <= 8'b0;
          data[1] <= 8'b0;
          data[2] <= 8'b0;
          data[3] <= 8'b0;
          data[4] <= 8'b0;
          data[5] <= 8'b0;
          data[6] <= 8'b0;
          data[7] <= 8'b0;
          data[8] <= 8'b0;
        end else begin
          data[0] <= data[1];
          data[1] <= data[2];
          data[2] <= 8'b0;
          data[3] <= data[4];
          data[4] <= data[5];
          data[5] <= 8'b0;
          data[6] <= data[7];
          data[7] <= data[8];
          data[8] <= 8'b0;
        end
      end else data[index] <= input_rdata[7:0];
    end
  end
  //load input
  //*********************************************//

  //*********************************************//
  //write output
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.addr <= 32'b0;
    else if (CurrentState == write_state) begin
      case (counter)
        4'h2: output_intf.addr <= output_intf.addr + input_2D_size;
        4'h5: output_intf.addr <= output_intf.addr + input_2D_size;
        4'h8: output_intf.addr <= output_intf.addr + input_2D_size;
        4'hb: begin
          if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))
            output_intf.addr <= output_intf.addr + 32'b1;
          else if ((row_counter == 5'b0) & (col_counter == 5'b0))
            output_intf.addr <= output_intf.addr - (4 * input_2D_size) + 32'b1;
          else
            output_intf.addr <= output_intf.addr - (3 * input_2D_size) + 32'b1;
        end
      endcase
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.W_req <= `WRITE_DIS;
    else if (CurrentState == write_state) begin
      case (counter)
        4'h1: output_intf.W_req <= `WRITE_ENB;
        4'h4: output_intf.W_req <= `WRITE_ENB;
        4'h7: output_intf.W_req <= `WRITE_ENB;
        4'ha: output_intf.W_req <= `WRITE_ENB;
        default: output_intf.W_req <= `WRITE_DIS;
      endcase
    end else output_intf.W_req <= `WRITE_DIS;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_wdata <= 16'b0;
    else if ((CurrentState == write_state) & (counter == 4'h1)) begin
      if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))begin
        if (sum_0[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_0[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_0[12:5]};
        end
      end else if (cha_counter == 10'b0)
        output_wdata <= bias_0[15:0] + partial_sum_0[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b1))
        output_wdata <= bias_0[15:0] + partial_sum_0[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == (num_channel - 32'b1)))
        output_wdata <= output_rdata + partial_sum_0[0];
      else if (cha_counter == (num_channel - 32'b1)) begin
        if (sum_0[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_0[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_0[12:5]};
        end
      end else output_wdata <= output_rdata + partial_sum_0[0];
    end else if ((CurrentState == write_state) & (counter == 4'h4)) begin
      if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))begin
        if (sum_1[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_1[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_1[12:5]};
        end
      end else if (cha_counter == 10'b0)
        output_wdata <= bias_1[15:0] + partial_sum_1[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b1))
        output_wdata <= bias_1[15:0] + partial_sum_1[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == (num_channel - 32'b1)))
        output_wdata <= output_rdata + partial_sum_1[0];
      else if (cha_counter == (num_channel - 32'b1)) begin
        if (sum_1[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_1[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_1[12:5]};
        end
      end else output_wdata <= output_rdata + partial_sum_1[0];
    end else if ((CurrentState == write_state) & (counter == 4'h7)) begin
      if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))begin
        if (sum_2[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_2[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_2[12:5]};
        end
      end else if (cha_counter == 10'b0)
        output_wdata <= bias_2[15:0] + partial_sum_2[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b1))
        output_wdata <= bias_2[15:0] + partial_sum_2[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == (num_channel - 32'b1)))
        output_wdata <= output_rdata + partial_sum_2[0];
      else if (cha_counter == (num_channel - 32'b1)) begin
        if (sum_2[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_2[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_2[12:5]};
        end
      end else output_wdata <= output_rdata + partial_sum_2[0];
    end else if ((CurrentState == write_state) & (counter == 4'ha)) begin
      if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))begin
        if (sum_3[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_3[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_3[12:5]};
        end
      end else if (cha_counter == 10'b0)
        output_wdata <= bias_3[15:0] + partial_sum_3[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b1))
        output_wdata <= bias_3[15:0] + partial_sum_3[0];
      else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == (num_channel - 32'b1)))
        output_wdata <= output_rdata + partial_sum_3[0];
      else if (cha_counter == (num_channel - 32'b1)) begin
        if (sum_3[15]) begin
          output_wdata <= 16'b0;
        end else begin
          if (|sum_3[15:12]) output_wdata <= 16'h7f;
          else output_wdata <= {8'b0, sum_3[12:5]};
        end
      end else output_wdata <= output_rdata + partial_sum_3[0];
    end
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
        if (counter == 4'h3) NextState = load_bias_state;
        else NextState = load_parameter_state;
      end
      load_bias_state: begin
        if (counter == 4'h4) NextState = load_weight_state;
        else NextState = load_bias_state;
      end
      load_weight_state: begin
        if (counter == 4'h4) NextState = load_input_state;
        else NextState = load_weight_state;
      end
      load_input_state: begin
        if (counter == num_input) NextState = calculate_state;
        else NextState = load_input_state;
      end
      calculate_state: begin
        NextState = write_state;
      end
      write_state: begin
        if((counter == 4'hb) & (row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0) & (ker_counter == 10'b0))
          NextState = finish_state;
        else if((counter == 4'hb) & (row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 10'b0))
          NextState = load_bias_state;
        else if((counter == 4'hb) & (row_counter == 5'b0) & (col_counter == 5'b0))
          NextState = load_weight_state;
        else if (counter == 4'hb) NextState = load_input_state;
        else NextState = write_state;
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
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_parameter_state: begin
        param_intf.cs = 1'b1;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_bias_state: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b1;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_weight_state: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b1;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      load_input_state: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b1;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      calculate_state: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b0;
      end
      write_state: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b1;
        finish = 1'b0;
      end
      default: begin
        param_intf.cs = 1'b0;
        bias_intf.cs = 1'b0;
        weight_intf.cs = 1'b0;
        input_intf.cs = 1'b0;
        output_intf.cs = 1'b0;
        finish = 1'b1;
      end
    endcase
  end
endmodule
