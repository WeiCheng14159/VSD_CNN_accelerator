`include "ConvAcc.svh"
module Conv_1x1 (
    input  logic        clk,
    input  logic        rstn,
    input  logic [31:0] w8,
    input  logic        start,
    output logic        finish,

    sp_ram_intf.compute param_intf,
    sp_ram_intf.compute bias_intf,
    sp_ram_intf.compute weight_intf,
    sp_ram_intf.compute input_intf,
    sp_ram_intf.compute output_intf
);

  parameter 	IDLE	 = 3'd0,
			LD_PARM	 = 3'd1,
			LD_BIAS	 = 3'd2,
			LD_WT	 = 3'd3,
			LD_I	 = 3'd4,
			CAL		 = 3'd5,
			SW_O	 = 3'd6,
			FIN		 = 3'd7;

  //parameter storage
  logic [5:0] num_row;
  logic [8:0] num_CH;
  logic [8:0] num_K;
  logic [31:0] w8_tmp;

  //bias
  logic signed [32:0] bias;

  //weight
  logic signed [7:0] weight[8:0];

  //data array
  logic signed [7:0] data[8:0];

  //partial sum
  logic signed [15:0] partial_sum[8:0];

  //sum
  logic signed [15:0] sum;

  logic [17:0] weight_rdata;
  logic [15:0] input_rdata;
  logic [15:0] output_wdata;

  //input size
  logic [31:0] total_elm;
  logic [10:0] input_2D_size;
  logic [31:0] input_size;

  //input number
  logic [3:0] num_input;

  //counter 
  logic [4:0] state_cnt;
  logic [8:0] CH_cnt;
  logic [4:0] row_cnt;
  logic [4:0] col_cnt;
  logic [9:0] K_cnt;
  logic [10:0] input_2D_cnt;

  //data_index
  logic [4:0] data_index;

  //last_addr
  logic last_addr;

  //parm
  assign param_intf.W_req 	= `WRITE_DIS;
  assign param_intf.W_data 	= 32'b0;
  assign param_intf.oe		= 1'b1;
  //Bias
  assign bias_intf.W_req 		= `WRITE_DIS;
  assign bias_intf.W_data 	= 32'b0;
  assign bias_intf.oe 		= 1'b1;
  //Input
  assign input_intf.W_req 	= `WRITE_DIS;
  assign input_intf.W_data 	= 16'b0;
  assign input_rdata 			= input_intf.R_data[15:0];
  assign input_intf.oe 		= 1'b1;
  // Weight
  assign weight_intf.W_req 	= `WRITE_DIS;
  assign weight_intf.W_data 	= 32'b0;
  assign weight_rdata 		= weight_intf.R_data[17:0];
  assign weight_intf.oe 		= 1'b1;
  // Output
  assign output_intf.W_data 	= {16'h0, output_wdata};
  assign output_intf.oe 		= 1'b1;

  //index
  logic [10:0] index;

  //FULL signal
  logic FULL;
  logic In_2D_FULL;
  logic In_2D_cnt_DLY;


  //last channel signal
  logic last_CH;
  logic [31:0] N_R_9;

  logic [2:0] STATE, NEXT;

  //store w8
  always_ff @(posedge clk or negedge rstn) begin
    w8_tmp <= (~rstn) ? 32'b0 : (start) ? w8 : w8_tmp;
  end

  assign FULL = (index == input_2D_size);
  assign In_2D_FULL = (input_2D_cnt == input_2D_size);

  assign last_addr = (input_intf.addr == (total_elm - 32'b1));

  assign sum = output_intf.R_data[15:0] + partial_sum[0];


  assign total_elm = num_row * num_row * num_CH;
  assign input_2D_size = num_row * num_row;
  assign input_size = num_row * num_row * CH_cnt;


  assign N_R_9 = num_CH - 32'd9;

  assign last_CH = CH_cnt > N_R_9;

  assign In_2D_cnt_DLY = input_2D_cnt == (input_2D_size - 32'b1);

  always_ff @(posedge clk or negedge rstn) begin
    STATE <= (~rstn) ? IDLE : NEXT;
  end

  always_comb begin
    case (STATE)
      IDLE: begin
        NEXT = start ? LD_PARM : IDLE;
      end
      LD_PARM: begin
        NEXT = (state_cnt == 5'd3) ? LD_BIAS : LD_PARM;
      end
      LD_BIAS: begin
        NEXT = (state_cnt == 5'd1) ? LD_WT : LD_BIAS;
      end
      LD_WT: begin
        NEXT = (state_cnt == 5'd1) ? LD_I : LD_WT;
      end
      LD_I: begin
        NEXT = (state_cnt == num_input) ? CAL : LD_I;
      end
      CAL: begin
        NEXT = (state_cnt == 5'd1) ? SW_O : CAL;
      end
      SW_O: begin
        if((state_cnt == 5'd2) & (K_cnt == num_K) & (last_CH) & (last_addr)) begin
          NEXT = FIN;
        end else if ((state_cnt == 5'd2) & (last_CH) & (last_addr)) begin
          NEXT = LD_BIAS;
        end else if ((state_cnt == 5'd2) & (In_2D_FULL)) begin
          NEXT = LD_WT;
        end else if (state_cnt == 5'd2) begin
          NEXT = LD_I;
        end else begin
          NEXT = SW_O;
        end
      end
      FIN: begin
        NEXT = IDLE;
      end
    endcase
  end

  always_comb begin
    param_intf.cs = 1'b0;
    bias_intf.cs = 1'b0;
    weight_intf.cs = 1'b0;
    input_intf.cs = 1'b0;
    output_intf.cs = 1'b0;
    finish = 1'b0;
    case (STATE)
      IDLE: param_intf.cs = 1'b1;
      LD_PARM: param_intf.cs = 1'b1;
      LD_BIAS: bias_intf.cs = 1'b1;
      LD_WT: weight_intf.cs = 1'b1;
      LD_I: input_intf.cs = 1'b1;
      CAL:  /*--Don't need to change any signal--*/;
      SW_O: output_intf.cs = 1'b1;
      FIN: finish = 1'b1;
    endcase
  end

  //counter control
  //--------------------------------------------------------------//
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) state_cnt <= 5'd0;
    else begin
      if (STATE == LD_PARM) begin
        state_cnt <= (state_cnt == 5'd3) ? 5'd0 : state_cnt + 5'd1;
      end else if (STATE == LD_BIAS) begin
        state_cnt <= (state_cnt == 5'd1) ? 5'd0 : state_cnt + 5'd1;
      end else if (STATE == LD_WT) begin
        state_cnt <= (state_cnt == 5'd1) ? 5'd0 : state_cnt + 5'd1;
      end else if (STATE == LD_I) begin
        state_cnt <= (state_cnt == num_input) ? 5'd0 : state_cnt + 5'd1;
      end else if (STATE == CAL) begin
        state_cnt <= (state_cnt == 5'd1) ? 5'd0 : state_cnt + 5'd1;
      end else if (STATE == SW_O) begin
        state_cnt <= (state_cnt == 5'd2) ? 5'd0 : state_cnt + 5'd1;
      end
    end
  end

  //channel counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) CH_cnt <= 9'd0;
    else if (STATE == LD_BIAS) CH_cnt <= 9'd0;
    else if (STATE == SW_O) begin
      if (state_cnt == 5'd1) begin
        CH_cnt <= FULL ? CH_cnt + 9'd9 : CH_cnt;
      end
    end
  end

  //kernel counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) K_cnt <= 10'b0;
    else if ((STATE == LD_BIAS) & (state_cnt == 5'd1)) begin
      K_cnt <= K_cnt + 10'b1;
    end
  end

  //input 2D  counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) input_2D_cnt <= 11'd0;
    else if (STATE == LD_BIAS) input_2D_cnt <= 11'd0;
    else if (STATE == SW_O) begin
      if (state_cnt == 5'd1) input_2D_cnt <= input_2D_cnt + 11'd1;
      else if (state_cnt == 5'd2)
        input_2D_cnt <= In_2D_FULL ? 11'd0 : input_2D_cnt;
    end
  end
  //--------------------------------------------------------------//

  //load parameter
  //--------------------------------------------------------------//
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) param_intf.addr <= 32'b0;
    else if (STATE == LD_PARM) begin
      param_intf.addr <= (state_cnt == 5'd3) ? 32'b0 : param_intf.addr + 5'd1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      num_row <= 32'b0;
      num_CH  <= 32'b0;
      num_K   <= 32'b0;
    end else if (STATE == LD_PARM) begin
      case (state_cnt)
        5'd1: num_row <= param_intf.R_data;
        5'd2: num_CH <= param_intf.R_data;
        5'd3: num_K <= param_intf.R_data;
      endcase
    end
  end
  //--------------------------------------------------------------//

  //load bias
  //--------------------------------------------------------------//
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) bias_intf.addr <= 32'b0;
    else if ((STATE == LD_BIAS) & (state_cnt == 5'd0)) begin
      bias_intf.addr <= bias_intf.addr + 3'd1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) bias <= 33'd0;
    else if ((STATE == LD_BIAS) & (state_cnt == 5'd1)) begin
      bias <= bias_intf.R_data;
    end
  end
  //--------------------------------------------------------------//

  //load weight
  //--------------------------------------------------------------//
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) weight_intf.addr <= 32'b0;
    else if ((STATE == LD_WT) & (state_cnt == 5'd0)) begin
      weight_intf.addr <= weight_intf.addr + 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      weight[0] <= 8'b0;
      weight[1] <= 8'b0;
      weight[2] <= 8'b0;
      weight[3] <= 8'b0;
      weight[4] <= 8'b0;
      weight[5] <= 8'b0;
      weight[6] <= 8'b0;
      weight[7] <= 8'b0;
      weight[8] <= 8'b0;
    end else if ((STATE == LD_WT) & (state_cnt == 5'd1)) begin
      weight[0] <= w8_tmp[{weight_rdata[1:0], 3'b0}+:8];
      weight[1] <= w8_tmp[{weight_rdata[3:2], 3'b0}+:8];
      weight[2] <= w8_tmp[{weight_rdata[5:4], 3'b0}+:8];
      weight[3] <= w8_tmp[{weight_rdata[7:6], 3'b0}+:8];
      weight[4] <= w8_tmp[{weight_rdata[9:8], 3'b0}+:8];
      weight[5] <= w8_tmp[{weight_rdata[11:10], 3'b0}+:8];
      weight[6] <= w8_tmp[{weight_rdata[13:12], 3'b0}+:8];
      weight[7] <= w8_tmp[{weight_rdata[15:14], 3'b0}+:8];
      weight[8] <= w8_tmp[{weight_rdata[17:16], 3'b0}+:8];
    end
  end
  //--------------------------------------------------------------//

  //load input
  //--------------------------------------------------------------//
  //data_index
  always_ff @(posedge clk or negedge rstn) begin
    data_index <= (~rstn) ? 5'd0 : state_cnt;
  end

  //Load input
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
    end else if (STATE == LD_I) begin
      data[data_index] <= input_rdata[7:0];
    end
  end

  //input number, check last few input channels
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) num_input <= 4'd0;
    else if (STATE == LD_BIAS) num_input <= 4'd9;
    else if ((STATE == SW_O) & (state_cnt == 5'd2)) begin
      if (last_CH) begin
        case (num_CH)
          32'd160: num_input <= 4'd7;
          32'd192: num_input <= 4'd3;
          default: num_input <= 4'd6;
        endcase
      end else num_input <= 4'd9;
    end
  end

  //input number counter
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) index <= 11'd0;
    else if (STATE == LD_BIAS) index <= 11'd0;
    else if (STATE == SW_O) begin
      if (state_cnt == 5'd0) index <= index + 11'd1;
      else if (state_cnt == 5'd1) index <= FULL ? 11'd0 : index;
    end
  end

  //input address
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) input_intf.addr <= 32'b0;
    else if (STATE == LD_BIAS) input_intf.addr <= 32'b0;
    else if (STATE == LD_I) begin
      input_intf.addr <= (state_cnt > (num_input - 4'd2)) ?  input_intf.addr : input_intf.addr + input_2D_size;
    end else if (STATE == SW_O) begin
      input_intf.addr <= (state_cnt == 5'd2) ? index + input_size : input_intf.addr;
    end
  end

  //--------------------------------------------------------------//

  //Calculate
  //--------------------------------------------------------------//
  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      partial_sum[0] <= 32'b0;
      partial_sum[1] <= 32'b0;
      partial_sum[2] <= 32'b0;
      partial_sum[3] <= 32'b0;
      partial_sum[4] <= 32'b0;
      partial_sum[5] <= 32'b0;
      partial_sum[6] <= 32'b0;
      partial_sum[7] <= 32'b0;
      partial_sum[8] <= 32'b0;
    end else if (STATE == CAL) begin
      if (state_cnt == 5'd0) begin
        partial_sum[0] <= data[0] * weight[0];
        partial_sum[1] <= data[1] * weight[1];
        partial_sum[2] <= data[2] * weight[2];
        partial_sum[3] <= data[3] * weight[3];
        partial_sum[4] <= data[4] * weight[4];
        partial_sum[5] <= data[5] * weight[5];
        partial_sum[6] <= data[6] * weight[6];
        partial_sum[7] <= data[7] * weight[7];
        partial_sum[8] <= data[8] * weight[8];
      end else if (state_cnt == 5'd1) begin
        partial_sum[0] <= partial_sum[0] + partial_sum[1] + partial_sum[2] + partial_sum[3] + partial_sum[4] + partial_sum[5] + partial_sum[6] + partial_sum[7] + partial_sum[8];
      end
    end
  end
  //--------------------------------------------------------------//


  //Store output
  //--------------------------------------------------------------//

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.W_req <= `WRITE_DIS;
    else if ((STATE == SW_O) & (state_cnt == 5'd0))
      output_intf.W_req <= `WRITE_ENB;
    else output_intf.W_req <= `WRITE_DIS;
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_intf.addr <= 32'b0;
    else if ((STATE == SW_O) & (state_cnt == 5'd1)) begin
      if (In_2D_cnt_DLY & last_addr) begin  //SW_O to LD_BIAS
        output_intf.addr <= output_intf.addr + 32'b1;
      end else if (In_2D_cnt_DLY) begin  //SW_O to LD_WT
        output_intf.addr <= output_intf.addr - input_2D_size + 32'b1;
      end else  //normal situation
        output_intf.addr <= output_intf.addr + 32'b1;
    end
  end


  always_ff @(posedge clk or negedge rstn) begin
    if (~rstn) output_wdata <= 16'b0;
    else if ((STATE == SW_O) & (state_cnt == 5'd0)) begin
      if (CH_cnt == 9'd0) begin
        output_wdata <= bias[15:0] + partial_sum[0];
      end else if (last_CH) begin
        if (sum[15]) begin
          output_wdata <= 16'h0;
        end else begin
          output_wdata <= (|sum[15:12]) ? 16'h7f : {8'b0, sum[12:5]};
        end
      end else begin
        output_wdata <= output_intf.R_data + partial_sum[0];
      end
    end
  end

  //--------------------------------------------------------------//

endmodule
