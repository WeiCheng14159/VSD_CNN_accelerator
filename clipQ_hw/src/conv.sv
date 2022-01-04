`ifndef CONV_SV
`define CONV_SV

`include "ctrl.sv"
`include "data_in.sv"
`include "conv_4U.sv"
`include "accum.sv"
`include "out_comb.sv"
`include "bram_intf.sv"

module conv (
    input logic rst,
    input logic clk,

    output logic        Mp_en,
    output logic [31:0] Mp_addr,
    input  logic [31:0] Mp_R_data,
    output logic [ 3:0] Mp_W_req,
    output logic [31:0] Mp_W_data,

    output logic        Min_en,
    output logic [31:0] Min_addr,
    input  logic [31:0] Min_R_data,
    output logic [ 3:0] Min_W_req,
    output logic [31:0] Min_W_data,

    output logic        Mout_en,
    output logic [31:0] Mout_addr,
    input  logic [31:0] Mout_R_data,
    output logic [ 3:0] Mout_W_req,
    output logic [31:0] Mout_W_data,

    output logic        Mw_en,
    output logic [31:0] Mw_addr,
    input  logic [31:0] Mw_R_data,
    output logic [ 3:0] Mw_W_req,
    output logic [31:0] Mw_W_data,

    output logic        Mb_en,
    output logic [31:0] Mb_addr,
    input  logic [31:0] Mb_R_data,
    output logic [ 3:0] Mb_W_req,
    output logic [31:0] Mb_W_data,

    output logic        Mk0_p0_en,
    output logic [31:0] Mk0_p0_addr,
    input  logic [31:0] Mk0_p0_R_data,
    output logic [ 3:0] Mk0_p0_W_req,
    output logic [31:0] Mk0_p0_W_data,

    output logic        Mk0_p1_en,
    output logic [31:0] Mk0_p1_addr,
    input  logic [31:0] Mk0_p1_R_data,
    output logic [ 3:0] Mk0_p1_W_req,
    output logic [31:0] Mk0_p1_W_data,

    output logic        Mk1_p0_en,
    output logic [31:0] Mk1_p0_addr,
    input  logic [31:0] Mk1_p0_R_data,
    output logic [ 3:0] Mk1_p0_W_req,
    output logic [31:0] Mk1_p0_W_data,

    output logic        Mk1_p1_en,
    output logic [31:0] Mk1_p1_addr,
    input  logic [31:0] Mk1_p1_R_data,
    output logic [ 3:0] Mk1_p1_W_req,
    output logic [31:0] Mk1_p1_W_data,

    output logic        Mk2_p0_en,
    output logic [31:0] Mk2_p0_addr,
    input  logic [31:0] Mk2_p0_R_data,
    output logic [ 3:0] Mk2_p0_W_req,
    output logic [31:0] Mk2_p0_W_data,

    output logic        Mk2_p1_en,
    output logic [31:0] Mk2_p1_addr,
    input  logic [31:0] Mk2_p1_R_data,
    output logic [ 3:0] Mk2_p1_W_req,
    output logic [31:0] Mk2_p1_W_data,

    output logic        Mk3_p0_en,
    output logic [31:0] Mk3_p0_addr,
    input  logic [31:0] Mk3_p0_R_data,
    output logic [ 3:0] Mk3_p0_W_req,
    output logic [31:0] Mk3_p0_W_data,

    output logic        Mk3_p1_en,
    output logic [31:0] Mk3_p1_addr,
    input  logic [31:0] Mk3_p1_R_data,
    output logic [ 3:0] Mk3_p1_W_req,
    output logic [31:0] Mk3_p1_W_data,
    input  logic        start,
    output logic        finish
);

  logic [15:0] cnt;

  logic [ 7:0] k_size;
  logic [ 3:0] u_en;
  logic        z_en;

  logic [ 7:0] pos_w;
  logic [ 7:0] neg_w1;
  logic [ 7:0] neg_w2;

  logic        in_en;
  logic [ 1:0] in_state;
  logic [ 1:0] padding_type;
  logic        group;
  logic        w8_chain;
  logic        wp_8;
  logic        wp_2;
  logic        bias_en;
  logic        three;
  logic        first;
  logic        last;
  logic        out_state;
  logic        out_en;

  logic [31:0] cal_data_in;
  logic [31:0] cal_bias;

  logic [31:0] result       [0:3];

  //in out channel(s5)
  logic [15:0] in_ch_cnt;
  logic [15:0] out_ch_cnt;
  logic        out_ch_c;

  logic [31:0] out_data     [0:3];


  logic [31:0] MinW_addr;
  logic        mb_push;
  logic [31:0] MoutW_addr;

  logic [31:0] bias         [0:3];

  logic [31:0] out_d;
  logic [ 3:0] out_wen;
  logic [31:0] out_addr;

  logic        w_en;

  assign Min_addr = {MinW_addr[29:0], 2'b00};
  assign out_addr = {MoutW_addr[29:0], 2'b00};

  assign Mp_en = 1'b1;
  assign Min_en = 1'b1;
  assign Mw_en = 1'b1;
  assign Mb_en = 1'b1;
  assign Mb_W_req = 4'b0;
  assign Mout_en = 1'b1;

  assign Mk0_p0_en = 1'b1;
  assign Mk0_p1_en = 1'b1;
  assign Mk0_p0_W_req = 4'b0;

  assign Mk1_p0_en = 1'b1;
  assign Mk1_p1_en = 1'b1;
  assign Mk1_p0_W_req = 4'b0;

  assign Mk2_p0_en = 1'b1;
  assign Mk2_p1_en = 1'b1;
  assign Mk2_p0_W_req = 4'b0;

  assign Mk3_p0_en = 1'b1;
  assign Mk3_p1_en = 1'b1;
  assign Mk3_p0_W_req = 4'b0;

  ctrl ctrl0 (
      .clk(clk),
      .rst(rst),
      .start(start),
      .finish(finish),
      .Mp_addr(Mp_addr),
      .Mp_R_data(Mp_R_data),
      .Min_addr(MinW_addr),
      .Mout_addr(MoutW_addr),
      .Mout_W_req(out_wen),
      .Mw_addr(Mw_addr),
      .Mw_R_data(Mw_R_data),
      .mb_addr(Mb_addr),
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
      .Min_R_data(Min_R_data),
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
      .w_2b_4(Mw_R_data[31:24]),
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
      .w_2b_4(Mw_R_data[23:16]),
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
      .w_2b_4(Mw_R_data[15:8]),
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
      .w_2b_4(Mw_R_data[7:0]),
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
      .mk_p0_addr(Mk0_p0_addr),
      .mk_p0_data(Mk0_p0_R_data),
      .mk_p1_w(Mk0_p1_W_req),
      .mk_p1_addr(Mk0_p1_addr),
      .mk_p1_data(Mk0_p1_W_data),
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
      .mk_p0_addr(Mk1_p0_addr),
      .mk_p0_data(Mk1_p0_R_data),
      .mk_p1_w(Mk1_p1_W_req),
      .mk_p1_addr(Mk1_p1_addr),
      .mk_p1_data(Mk1_p1_W_data),
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
      .mk_p0_addr(Mk2_p0_addr),
      .mk_p0_data(Mk2_p0_R_data),
      .mk_p1_w(Mk2_p1_W_req),
      .mk_p1_addr(Mk2_p1_addr),
      .mk_p1_data(Mk2_p1_W_data),
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
      .mk_p0_addr(Mk3_p0_addr),
      .mk_p0_data(Mk3_p0_R_data),
      .mk_p1_w(Mk3_p1_W_req),
      .mk_p1_addr(Mk3_p1_addr),
      .mk_p1_data(Mk3_p1_W_data),
      .mb_push(mb_push),
      .mb_in(Mb_R_data),
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
      Mout_addr   <= 0;
      Mout_W_req  <= 0;
      Mout_W_data <= 0;
    end else begin
      Mout_addr   <= out_addr;
      Mout_W_req  <= out_wen;
      Mout_W_data <= out_d;
    end
  end

endmodule

`endif
