`ifndef CONV_V
`define CONV_V

`include "../src/ctrl.v"
`include "../src/data_in.v"
`include "../src/conv_4U.v"
`include "../src/accum.v"
`include "../src/out_comb.v"

module conv (
    input logic rst,
    input logic clk,
    input logic start,
    input logic finish,
    bram_intf.compute param_intf,
    bram_intf.compute input_intf,
    bram_intf.compute output_intf,
    bram_intf.compute weight_intf,
    bram_intf.compute bias_intf,
    bram_intf.compute k0_p0_intf,
    bram_intf.compute k0_p1_intf,
    bram_intf.compute k1_p0_intf,
    bram_intf.compute k1_p1_intf,
    bram_intf.compute k2_p0_intf,
    bram_intf.compute k2_p1_intf,
    bram_intf.compute k3_p0_intf,
    bram_intf.compute k3_p1_intf
);

  reg  [15:0] cnt;

  wire [ 7:0] k_size;
  wire [ 3:0] u_en;
  wire        z_en;


  wire [ 7:0] pos_w;
  wire [ 7:0] neg_w1;
  wire [ 7:0] neg_w2;

  wire        in_en;
  wire [ 1:0] in_state;
  wire [ 1:0] padding_type;
  wire        group;
  wire        w8_chain;
  wire        wp_8;
  wire        wp_2;
  wire        bias_en;
  wire        three;
  wire        first;
  wire        last;
  wire        out_state;
  wire        out_en;

  wire [31:0] cal_data_in;
  wire [31:0] cal_bias;

  wire [31:0] result       [0:3];

  //in out channel(s5)
  wire [15:0] in_ch_cnt;
  wire [15:0] out_ch_cnt;
  wire        out_ch_c;

  wire [31:0] out_data     [0:3];


  wire [31:0] MinW_addr;
  wire        mb_push;
  wire [31:0] MoutW_addr;

  wire [31:0] bias         [0:3];

  wire [31:0] out_d;
  wire [ 3:0] out_wen;
  wire [31:0] out_addr;

  wire        w_en;

  assign input_intf.addr = {MinW_addr[29:0], 2'b00};
  assign out_addr = {MoutW_addr[29:0], 2'b00};

  assign param_intf.en = 1'b1;
  assign input_intf.en = 1'b1;
  assign weight_intf.en = 1'b1;
  assign bias_intf.en = 1'b1;
  assign output_intf.en = 1'b1;
  assign bias_intf.W_req = 4'b0;

  assign k0_p0_intf.en = 1'b1;
  assign k0_p1_intf.en = 1'b1;
  assign k0_p0_intf.W_req = 4'b0;

  assign k1_p0_intf.en = 1'b1;
  assign k1_p1_intf.en = 1'b1;
  assign k1_p0_intf.W_req = 4'b0;

  assign k2_p0_intf.en = 1'b1;
  assign k2_p1_intf.en = 1'b1;
  assign k2_p0_intf.W_req = 4'b0;

  assign k3_p0_intf.en = 1'b1;
  assign k3_p1_intf.en = 1'b1;
  assign k3_p0_intf.W_req = 4'b0;

  ctrl ctrl0 (
      .clk(clk),
      .rst(rst),
      .start(start),
      .finish(finish),
      // Param
      .Mp_addr(param_intf.addr),
      .Mp_R_data(param_intf.R_data),
      // Input
      .Min_addr(MinW_addr),
      // Output
      .Mout_addr(MoutW_addr),
      .Mout_W_req(out_wen),
      // Weight
      .Mw_addr(weight_intf.addr),
      .Mw_R_data(weight_intf.R_data),
      .mb_addr(bias_intf.addr),
      .mb_en(mb_push),
      .padding_type(padding_type),
      .k_size(k_size),
      .u_en(u_en),
      .w_en(w_en),
      .z_en(z_en),
      .pos_w(pos_w),
      .neg_w1(neg_w1),
      .neg_w2(neg_w2),
      .first(first),
      .last(last),
      .out_en(out_en),
      .out_state(out_state),
      .in_ch_cnt(in_ch_cnt),
      .out_ch_cnt(out_ch_cnt),
      .out_ch_c(out_ch_c)
  );

  data_in data_in0 (
      .clk(clk),
      .rst(rst),
      .Min_R_data(input_intf.R_data),
      .padding_type(padding_type),
      .cal_data_in(cal_data_in)
  );

  conv_4U c0 (
      .rst(rst),
      .clk(clk),
      .din_32(cal_data_in),
      .dout_32(result[0]),
      .unit_en(u_en[0]),
      .k_size(k_size),
      .w_2b_4(weight_intf.R_data[31:24]),
      .w_en(w_en),
      .z_en(z_en),
      .pos_w(pos_w),
      .neg_w1(neg_w1),
      .neg_w2(neg_w2)
  );

  conv_4U c1 (
      .rst(rst),
      .clk(clk),
      .din_32(cal_data_in),
      .dout_32(result[1]),
      .unit_en(u_en[1]),
      .k_size(k_size),
      .w_2b_4(weight_intf.R_data[23:16]),
      .w_en(w_en),
      .z_en(z_en),
      .pos_w(pos_w),
      .neg_w1(neg_w1),
      .neg_w2(neg_w2)
  );

  conv_4U c2 (
      .rst(rst),
      .clk(clk),
      .din_32(cal_data_in),
      .dout_32(result[2]),
      .unit_en(u_en[2]),
      .k_size(k_size),
      .w_2b_4(weight_intf.R_data[15:8]),
      .w_en(w_en),
      .z_en(z_en),
      .pos_w(pos_w),
      .neg_w1(neg_w1),
      .neg_w2(neg_w2)
  );

  conv_4U c3 (
      .rst(rst),
      .clk(clk),
      .din_32(cal_data_in),
      .dout_32(result[3]),
      .unit_en(u_en[3]),
      .k_size(k_size),
      .w_2b_4(weight_intf.R_data[7:0]),
      .w_en(w_en),
      .z_en(z_en),
      .pos_w(pos_w),
      .neg_w1(neg_w1),
      .neg_w2(neg_w2)
  );

  accum accum0 (
      .clk(clk),
      .rst(rst),
      .result(result[0]),
      .out_state(out_state),
      .out_en(out_en),
      .mk_p0_addr(k0_p0_intf.addr),
      .mk_p0_data(k0_p0_intf.R_data),
      .mk_p1_w(k0_p1_intf.W_req),
      .mk_p1_addr(k0_p1_intf.addr),
      .mk_p1_data(k0_p1_intf.W_data),
      .mb_push(mb_push),
      .mb_in(bias[2]),
      .bias(bias[3]),
      .first(first),
      .last(last),
      .in_ch_cnt(in_ch_cnt),
      .out_ch_cnt(out_ch_cnt),
      .out_ch_c(out_ch_c),
      .Mout_data(out_data[0])
  );


  accum accum1 (
      .clk(clk),
      .rst(rst),
      .result(result[1]),
      .out_state(out_state),
      .out_en(out_en),
      .mk_p0_addr(k1_p0_intf.addr),
      .mk_p0_data(k1_p0_intf.R_data),
      .mk_p1_w(k1_p1_intf.W_req),
      .mk_p1_addr(k1_p1_intf.addr),
      .mk_p1_data(k1_p1_intf.W_data),
      .mb_push(mb_push),
      .mb_in(bias[1]),
      .bias(bias[2]),
      .first(first),
      .last(last),
      .in_ch_cnt(in_ch_cnt),
      .out_ch_cnt(out_ch_cnt),
      .out_ch_c(out_ch_c),
      .Mout_data(out_data[1])
  );


  accum accum2 (
      .clk(clk),
      .rst(rst),
      .result(result[2]),
      .out_state(out_state),
      .out_en(out_en),
      .mk_p0_addr(k2_p0_intf.addr),
      .mk_p0_data(k2_p0_intf.R_data),
      .mk_p1_w(k2_p1_intf.W_req),
      .mk_p1_addr(k2_p1_intf.addr),
      .mk_p1_data(k2_p1_intf.W_data),
      .mb_push(mb_push),
      .mb_in(bias[0]),
      .bias(bias[1]),
      .first(first),
      .last(last),
      .in_ch_cnt(in_ch_cnt),
      .out_ch_cnt(out_ch_cnt),
      .out_ch_c(out_ch_c),
      .Mout_data(out_data[2])
  );


  accum accum3 (
      .clk(clk),
      .rst(rst),
      .result(result[3]),
      .out_state(out_state),
      .out_en(out_en),
      .mk_p0_addr(k3_p0_intf.addr),
      .mk_p0_data(k3_p0_intf.R_data),
      .mk_p1_w(k3_p1_intf.W_req),
      .mk_p1_addr(k3_p1_intf.addr),
      .mk_p1_data(k3_p1_intf.W_data),
      .mb_push(mb_push),
      .mb_in(bias_intf.R_data),
      .bias(bias[0]),
      .first(first),
      .last(last),
      .in_ch_cnt(in_ch_cnt),
      .out_ch_cnt(out_ch_cnt),
      .out_ch_c(out_ch_c),
      .Mout_data(out_data[3])
  );

  out_comb out0 (
      .out0(out_data[0]),
      .out1(out_data[1]),
      .out2(out_data[2]),
      .out3(out_data[3]),
      .out (out_d)
  );

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      output_intf.addr   <= 0;
      output_intf.W_req  <= 0;
      output_intf.W_data <= 0;
    end else begin
      output_intf.addr   <= out_addr;
      output_intf.W_req  <= out_wen;
      output_intf.W_data <= out_d;
    end
  end

endmodule

`endif