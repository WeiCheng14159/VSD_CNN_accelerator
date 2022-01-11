`timescale 1ns/10ps

`include "conv_acc.svh"

module  conv(
	input					clk,
	input					rst,
			
	output	logic			param_en,
	output	logic	[31:0]	param_addr,
	input			[31:0]	param_rdata,
	output	logic	[ 3:0]	param_write,
	output	logic	[31:0]	param_wdata,

	output	logic			bias_en,
	output	logic	[31:0]	bias_addr,
	input			[31:0]	bias_rdata,
	output	logic	[ 3:0]	bias_write,
	output	logic	[31:0]	bias_wdata,

	output	logic			weight_en,
	output	logic	[31:0]	weight_addr,
	input			[17:0]	weight_rdata,
	output	logic	[ 3:0]	weight_write,
	output	logic	[17:0]	weight_wdata,

	output	logic			input_en,
	output	logic	[31:0]	input_addr,
	input			[15:0]	input_rdata,
	output	logic	[ 3:0]	input_write,
	output	logic	[15:0]	input_wdata,

	output	logic			output_en,
	output	logic	[31:0]	output_addr,
	input			[15:0]	output_rdata,
	output	logic	[ 3:0]	output_write,
	output	logic	[15:0]	output_wdata,

	input			[31:0]	w8,

	input					start,
	output	logic			finish
);

	logic 	[ 2:0]	num_input;
	logic	[31:0]	num_row;
	logic	[31:0]	num_channel;
	logic	[31:0]	num_kernel;
	logic	[31:0]	kernel_size;
	logic 	[31:0]	w8_temp;

	logic	[31:0]	input_size;
	logic	[31:0]	input_2D_size;

	logic 	signed	[ 7:0]	data[8:0];
	logic 	signed	[ 7:0]	weight[8:0];
	logic	signed	[15:0]	partial_sum[8:0];
	logic	signed	[32:0]	bias;
	logic	signed	[15:0]	sum;

	logic 	[ 2:0]	counter;
	logic 	[ 4:0]	row_counter;
	logic 	[ 4:0]	col_counter;
	logic 	[ 9:0]	cha_counter;
	logic 	[ 9:0]	ker_counter;
	logic 	[ 3:0]	index;
	integer 		i;

	logic	[ 2:0]	CurrentState;
	logic	[ 2:0]	NextState;

	parameter	idle_state = 3'h0,
				load_parameter_state = 3'h1,
				load_bias_state = 3'h2,
				load_weight_state = 3'h3,
				load_input_state = 3'h4,
				calculate_state = 3'h5,
				write_state = 3'h6,
				finish_state = 3'h7;

	assign param_wdata = 32'b0;
	assign bias_wdata = 32'b0;
	assign weight_wdata = 18'b0;
	assign input_wdata = 16'b0;

	assign input_size = num_row * num_row * num_channel;
	assign input_2D_size = num_row * num_row;
	assign kernel_size = 32'h3;

	assign sum = output_rdata + partial_sum[0];

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			w8_temp <= 32'b0;
		else if(start)
			w8_temp <= w8;
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)begin
			// for(i = 0; i < 9; i = i + 1)
			// 	partial_sum[i] <= 32'b0;
			partial_sum[0] <= 32'b0;
			partial_sum[1] <= 32'b0;
			partial_sum[2] <= 32'b0;
			partial_sum[3] <= 32'b0;
			partial_sum[4] <= 32'b0;
			partial_sum[5] <= 32'b0;
			partial_sum[6] <= 32'b0;
			partial_sum[7] <= 32'b0;
			partial_sum[8] <= 32'b0;
		end
		else if(CurrentState == calculate_state)begin
			// for(i = 0; i < 9; i = i + 1)
			// 	partial_sum[i] <= data[i] * weight[i];
			partial_sum[0] <= data[0] * weight[0];
			partial_sum[1] <= data[1] * weight[1];
			partial_sum[2] <= data[2] * weight[2];
			partial_sum[3] <= data[3] * weight[3];
			partial_sum[4] <= data[4] * weight[4];
			partial_sum[5] <= data[5] * weight[5];
			partial_sum[6] <= data[6] * weight[6];
			partial_sum[7] <= data[7] * weight[7];
			partial_sum[8] <= data[8] * weight[8];
		end
		else if((CurrentState == write_state) & (counter == 3'b0))
			partial_sum[0] <= partial_sum[0] + partial_sum[1] + partial_sum[2] + partial_sum[3] + partial_sum[4] + partial_sum[5] + partial_sum[6] + partial_sum[7] + partial_sum[8];
	end

	//*********************************************//
	//counter
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			counter <= 3'b0;
		else if(CurrentState == load_parameter_state)begin
			if(counter == 3'h3)
				counter <= 3'b0;
			else 
				counter <= counter + 1'b1;
		end
		else if(CurrentState == load_bias_state)begin
			if(counter == 3'h1)
				counter <= 3'b0;
			else 
				counter <= counter + 1'b1;
		end
		else if(CurrentState == load_weight_state)begin
			if(counter == 3'h1)
				counter <= 3'b0;
			else 
				counter <= counter + 1'b1;
		end
		else if(CurrentState == load_input_state)begin
			if(counter == num_input)
				counter <= 3'b0;
			else 
				counter <= counter + 1'b1;
		end
		else if(CurrentState == write_state)begin
			if(counter == 3'h2)
				counter <= 3'b0;
			else 
				counter <= counter + 1'b1;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			row_counter <= 5'b0;
		else if((CurrentState == load_input_state) & (counter == num_input))begin
			if(row_counter == (num_row - 1'b1))
				row_counter <= 5'b0;
			else
				row_counter <= row_counter + 1'b1;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			col_counter <= 5'b0;
		else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 1'b1)))begin
			if(col_counter == (num_row - 1'b1))
				col_counter <= 5'b0;
			else
				col_counter <= col_counter + 1'b1;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			cha_counter <= 10'b0;
		else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 1'b1)) & (col_counter == (num_row - 1'b1)))begin
			if(cha_counter == (num_channel - 1'b1))
				cha_counter <= 10'b0;
			else
				cha_counter <= cha_counter + 1'b1;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			ker_counter <= 10'b0;
		else if((CurrentState == load_input_state) & (counter == num_input) & (row_counter == (num_row - 1'b1)) & (col_counter == (num_row - 1'b1)) & (cha_counter == (num_channel - 1'b1)))begin
			if(ker_counter == (num_kernel - 1'b1))
				ker_counter <= 10'b0;
			else
				ker_counter <= ker_counter + 1'b1;
		end
	end
	//counter
	//*********************************************//

	//*********************************************//
	//load parameter
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			param_addr <= 32'b0;
		else if((CurrentState == load_parameter_state))begin
			if(counter == 2'h3)
				param_addr <= 32'b0;
			else
				param_addr <= param_addr + 3'h4;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)begin
			num_row <= 32'b0;
			num_channel <= 32'b0;
			num_kernel <= 32'b0;
		end
		else if((CurrentState == load_parameter_state))begin
			case(counter)
				2'h1: num_row <= param_rdata;
				2'h2: num_channel <= param_rdata;
				2'h3: num_kernel <= param_rdata;
			endcase
		end
	end
	//load parameter
	//*********************************************//

	//*********************************************//
	//load bias
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			bias_addr <= 32'b0;
		else if((CurrentState == load_bias_state) & (counter == 1'b0))
			bias_addr <= bias_addr + 3'h4;
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			bias <= 32'b0;
		else if((CurrentState == load_bias_state) & (counter == 2'h1))
			bias <= bias_rdata;
	end
	//load bias
	//*********************************************//

	//*********************************************//
	//load weight
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			weight_addr <= 32'b0;
		else if((CurrentState == load_weight_state) & (counter == 1'b0))
			weight_addr <= weight_addr + 3'h4;
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)begin
			// for(i = 0; i < 9; i = i + 1)
			// 	weight[i] <= 32'b0;
			weight[0] <= 32'b0;
			weight[1] <= 32'b0;
			weight[2] <= 32'b0;
			weight[3] <= 32'b0;
			weight[4] <= 32'b0;
			weight[5] <= 32'b0;
			weight[6] <= 32'b0;
			weight[7] <= 32'b0;
			weight[8] <= 32'b0;
		end
		else if((CurrentState == load_weight_state) & (counter == 2'h1))begin
			case(weight_rdata[1:0])
				2'b00: weight[0] <= w8_temp[ 7: 0];
				2'b01: weight[0] <= w8_temp[15: 8];
				2'b10: weight[0] <= w8_temp[23:16];
				2'b11: weight[0] <= w8_temp[31:24];
			endcase
			case(weight_rdata[3:2])
				2'b00: weight[1] <= w8_temp[ 7: 0];
				2'b01: weight[1] <= w8_temp[15: 8];
				2'b10: weight[1] <= w8_temp[23:16];
				2'b11: weight[1] <= w8_temp[31:24];
			endcase
			case(weight_rdata[5:4])
				2'b00: weight[2] <= w8_temp[ 7: 0];
				2'b01: weight[2] <= w8_temp[15: 8];
				2'b10: weight[2] <= w8_temp[23:16];
				2'b11: weight[2] <= w8_temp[31:24];
			endcase
			case(weight_rdata[7:6])
				2'b00: weight[3] <= w8_temp[ 7: 0];
				2'b01: weight[3] <= w8_temp[15: 8];
				2'b10: weight[3] <= w8_temp[23:16];
				2'b11: weight[3] <= w8_temp[31:24];
			endcase
			case(weight_rdata[9:8])
				2'b00: weight[4] <= w8_temp[ 7: 0];
				2'b01: weight[4] <= w8_temp[15: 8];
				2'b10: weight[4] <= w8_temp[23:16];
				2'b11: weight[4] <= w8_temp[31:24];
			endcase
			case(weight_rdata[11:10])
				2'b00: weight[5] <= w8_temp[ 7: 0];
				2'b01: weight[5] <= w8_temp[15: 8];
				2'b10: weight[5] <= w8_temp[23:16];
				2'b11: weight[5] <= w8_temp[31:24];
			endcase
			case(weight_rdata[13:12])
				2'b00: weight[6] <= w8_temp[ 7: 0];
				2'b01: weight[6] <= w8_temp[15: 8];
				2'b10: weight[6] <= w8_temp[23:16];
				2'b11: weight[6] <= w8_temp[31:24];
			endcase
			case(weight_rdata[15:14])
				2'b00: weight[7] <= w8_temp[ 7: 0];
				2'b01: weight[7] <= w8_temp[15: 8];
				2'b10: weight[7] <= w8_temp[23:16];
				2'b11: weight[7] <= w8_temp[31:24];
			endcase
			case(weight_rdata[17:16])
				2'b00: weight[8] <= w8_temp[ 7: 0];
				2'b01: weight[8] <= w8_temp[15: 8];
				2'b10: weight[8] <= w8_temp[23:16];
				2'b11: weight[8] <= w8_temp[31:24];
			endcase
		end
	end
	//load weight
	//*********************************************//

	//*********************************************//
	//load input
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			num_input <= 3'b0;
		else if(CurrentState == load_weight_state)
			num_input <= 3'h4;
		else if(CurrentState == write_state)begin
			if((row_counter == 5'b0) & (col_counter == (num_row - 1'b1)))
				num_input <= 3'h4;
			else if(row_counter == 5'b0)
				num_input <= 3'h6;
			else if(row_counter == (num_row - 1'b1))
				num_input <= 3'h0;
			else if(col_counter == 5'b0)
				num_input <= 3'h2;
			else if(col_counter == (num_row - 1'b1))
				num_input <= 3'h2;
			else
				num_input <= 3'h3;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			index <= 4'b0;
		else if(CurrentState == load_input_state)begin
			if((row_counter == 5'b0) & (col_counter == 5'b0))begin
				case(counter)
					3'h0: index <= 4'h4;
					3'h1: index <= 4'h5;
					3'h2: index <= 4'h7;
					3'h3: index <= 4'h8;
				endcase
			end
			else if((row_counter == 5'b0) & (col_counter == (num_row - 1'b1)))begin
				case(counter)
					3'h0: index <= 4'h1;
					3'h1: index <= 4'h2;
					3'h2: index <= 4'h4;
					3'h3: index <= 4'h5;
				endcase
			end
			else if(row_counter == 5'b0)begin
				case(counter)
					3'h0: index <= 4'h1;
					3'h1: index <= 4'h2;
					3'h2: index <= 4'h4;
					3'h3: index <= 4'h5;
					3'h4: index <= 4'h7;
					3'h5: index <= 4'h8;
				endcase
			end
			// else if(row_counter == (num_row - 1'b1))begin
			// 	case(counter)
			// 		3'h0: index <= 3'h4;
			// 	endcase
			// end
			else if(col_counter == 5'b0)begin
				case(counter)
					3'h0: index <= 4'h5;
					3'h1: index <= 4'h8;
				endcase
			end
			else if(col_counter == (num_row - 1'b1))begin
				case(counter)
					3'h0: index <= 4'h2;
					3'h1: index <= 4'h5;
				endcase
			end
			else begin
				case(counter)
					3'h0: index <= 4'h2;
					3'h1: index <= 4'h5;
					3'h2: index <= 4'h8;
				endcase
			end
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			input_addr <= 32'b0;
		else if(CurrentState == load_weight_state)
			input_addr <= 4 * cha_counter * input_2D_size;
		else if(CurrentState == load_input_state)begin
			if((row_counter == 5'b0) & (col_counter == 5'b0))begin
				case(counter)
					3'h0: input_addr <= input_addr + 3'h4;
					3'h1: input_addr <= input_addr + (4 * num_row) - 3'h4;
					3'h2: input_addr <= input_addr + 3'h4;
					3'h3: input_addr <= input_addr - (4 * num_row) + 3'h4;
				endcase
			end
			else if((row_counter == 5'b0) & (col_counter == (num_row - 1'b1)))begin
				case(counter)
					3'h0: input_addr <= input_addr + 3'h4;
					3'h1: input_addr <= input_addr + (4 * num_row) - 3'h4;
					3'h2: input_addr <= input_addr + 3'h4;
					3'h3: input_addr <= input_addr - (4 * num_row) + 3'h4;
				endcase
			end
			else if(row_counter == 5'b0)begin
				case(counter)
					3'h0: input_addr <= input_addr + 3'h4;
					3'h1: input_addr <= input_addr + (4 * num_row) - 3'h4;
					3'h2: input_addr <= input_addr + 3'h4;
					3'h3: input_addr <= input_addr + (4 * num_row) - 3'h4;
					3'h4: input_addr <= input_addr + 3'h4;
					3'h5: input_addr <= input_addr - (8 * num_row) + 3'h4;
				endcase
			end
			else if(row_counter == (num_row - 1'b1))begin
				if(col_counter == 5'b0)
					input_addr <= input_addr - (4 * num_row);
				else if(col_counter == (num_row - 1'b1))
					input_addr <= input_addr + (4 * num_row);
			end
			else if(col_counter == 5'b0)begin
				case(counter)
					3'h0: input_addr <= input_addr + (4 * num_row);
					3'h1: input_addr <= input_addr - (4 * num_row) + 3'h4;
				endcase
			end
			else if(col_counter == (num_row - 1'b1))begin
				case(counter)
					3'h0: input_addr <= input_addr + (4 * num_row);
					3'h1: input_addr <= input_addr - (4 * num_row) + 3'h4;
				endcase
			end
			else begin
				case(counter)
					3'h0: input_addr <= input_addr + (4 * num_row);
					3'h1: input_addr <= input_addr + (4 * num_row);
					3'h2: input_addr <= input_addr - (8 * num_row) + 3'h4;
				endcase
			end
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)begin
			// for(i = 0; i < 9; i = i + 1)
			// 	data[i] <= 32'b0;
			data[0] <= 32'b0;
			data[1] <= 32'b0;
			data[2] <= 32'b0;
			data[3] <= 32'b0;
			data[4] <= 32'b0;
			data[5] <= 32'b0;
			data[6] <= 32'b0;
			data[7] <= 32'b0;
			data[8] <= 32'b0;
		end
		else if(CurrentState == load_input_state)begin
			if(counter == 3'h0)begin
				if(row_counter == 5'b0)begin
					// for(i = 0; i < 9; i = i + 1)
					// 	data[i] <= 32'b0;
					data[0] <= 32'b0;
					data[1] <= 32'b0;
					data[2] <= 32'b0;
					data[3] <= 32'b0;
					data[4] <= 32'b0;
					data[5] <= 32'b0;
					data[6] <= 32'b0;
					data[7] <= 32'b0;
					data[8] <= 32'b0;
				end
				else begin
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
			end
			else
				data[index] <= input_rdata[7:0];
		end
	end
	//load input
	//*********************************************//

	//*********************************************//
	//write output
	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			output_en <= 1'b0;
		else if(CurrentState == calculate_state)
			output_en <= 1'b1;
		else if((CurrentState == write_state) & (counter == 3'h1))
			output_en <= 1'b1;
		else
			output_en <= 1'b0;
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			output_addr <= 32'b0;
		else if((CurrentState == write_state) & (counter == 3'h2))begin
			if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 5'b0))
				output_addr <= output_addr + 3'h4;
			else if((row_counter == 5'b0) & (col_counter == 5'b0))
				output_addr <= output_addr - (4 * input_2D_size) + 3'h4;
			else 
				output_addr <= output_addr + 3'h4;
		end
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			output_write <= 4'b0;
		else if((CurrentState == write_state) & (counter == 3'h1))
			output_write <= 4'hf;
		else 
			output_write <= 4'b0;
	end

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			output_wdata <= 8'b0;
		else if((CurrentState == write_state) & (counter == 3'h1))begin
			if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 5'b0))begin
				if(sum[15])begin
					if(~&sum[15:12])
						output_wdata <= 8'h80;
					else 
						output_wdata <= sum[12:5] + 1'b1;
				end
				else begin
					if(|sum[15:12])
						output_wdata <= 8'h7f;
					else
						output_wdata <= sum[12:5];
				end
			end
			else if(cha_counter == 5'b0)
				output_wdata <= bias[15:0] + partial_sum[0];
			else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 5'b1))
				output_wdata <= bias[15:0] + partial_sum[0];
			else if((row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == (num_channel - 1'b1)))
				output_wdata <= output_rdata + partial_sum[0];
			else if(cha_counter == (num_channel - 1'b1))begin
				if(sum[15])begin
					if(~&sum[15:12])
						output_wdata <= 8'h80;
					else 
						output_wdata <= sum[12:5] + 1'b1;
				end
				else begin
					if(|sum[15:12])
						output_wdata <= 8'h7f;
					else
						output_wdata <= sum[12:5];
				end
			end
			else 
				output_wdata <= output_rdata + partial_sum[0];
		end
	end

	//write output
	//*********************************************//

	always_ff @(posedge clk or negedge rst) begin
		if(~rst)
			CurrentState <= idle_state;
		else 
			CurrentState <= NextState;
	end

	always_comb begin
		case(CurrentState)
			idle_state:begin
				if(start)
					NextState = load_parameter_state;
				else 
					NextState = idle_state;
			end
			load_parameter_state:begin
				if(counter == 2'h3)
					NextState = load_bias_state;
				else
					NextState = load_parameter_state;
			end
			load_bias_state:begin
				if(counter == 1'h1)
					NextState = load_weight_state;
				else
					NextState = load_bias_state;
			end
			load_weight_state:begin
				if(counter == 1'h1)
					NextState = load_input_state;
				else
					NextState = load_weight_state;
			end
			load_input_state:begin
				if(counter == num_input)
					NextState = calculate_state;
				else
					NextState = load_input_state;
			end
			calculate_state:begin
				NextState = write_state;
			end
			write_state:begin
				if((counter == 3'h2) & (row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 5'b0) & (ker_counter == 5'b0))
					NextState = finish_state;
				else if((counter == 3'h2) & (row_counter == 5'b0) & (col_counter == 5'b0) & (cha_counter == 5'b0))
					NextState = load_bias_state;
				else if((counter == 3'h2) & (row_counter == 5'b0) & (col_counter == 5'b0))
					NextState = load_weight_state;
				else if(counter == 3'h2)
					NextState = load_input_state;
				else 
					NextState = write_state;
			end
			default:begin
				NextState = idle_state;
			end
		endcase
	end

	always_comb begin
		case(CurrentState)
			idle_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			load_parameter_state:begin
				param_en = 1'b1;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			load_bias_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b1;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			load_weight_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b1;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			load_input_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b1;
				input_write = 4'b0;
				finish = 1'b0;
			end
			calculate_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			write_state:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b0;
			end
			default:begin
				param_en = 1'b0;
				param_write = 4'b0;
				bias_en = 1'b0;
				bias_write = 4'b0;
				weight_en = 1'b0;
				weight_write = 4'b0;
				input_en = 1'b0;
				input_write = 4'b0;
				finish = 1'b1;
			end
		endcase
	end

endmodule
