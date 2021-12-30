`ifndef CONV_4U_V
`define CONV_4U_V
`include "../src/conv_25.v"

module conv_4U (
    rst,
    clk,
    din_32,
    dout_32,
    unit_en,
    k_size,
    w_2b_4,
    w_en,
    z_en,
    pos_w,
    neg_w1,
    neg_w2
);

  input rst;
  input clk;

  input [31:0] din_32;
  output reg [31:0] dout_32;

  input unit_en;
  input [7:0] k_size;
  input [7:0] w_2b_4;
  input w_en;
  input z_en;
  input [7:0] pos_w;
  input [7:0] neg_w1;
  input [7:0] neg_w2;

  reg [7:0] w_in[0:3];
  wire [31:0] ans_out[0:3];
  wire [31:0] in_32;

  assign in_32 = unit_en ? din_32 : 32'b0;

  conv_25 conv_0 (
      .clk(clk),
      .rst(rst),
      .d_in(in_32[31:24]),
      .z_en(z_en),
      .w_in(w_in[0]),
      .w_en(w_en),
      .ans_out(ans_out[0])

  );

  conv_25 conv_1 (
      .clk(clk),
      .rst(rst),
      .d_in(in_32[23:16]),
      .z_en(z_en),
      .w_in(w_in[1]),
      .w_en(w_en),
      .ans_out(ans_out[1])

  );

  conv_25 conv_2 (
      .clk(clk),
      .rst(rst),
      .d_in(in_32[15:8]),
      .z_en(z_en),
      .w_in(w_in[2]),
      .w_en(w_en),
      .ans_out(ans_out[2])

  );

  conv_25 conv_3 (
      .clk(clk),
      .rst(rst),
      .d_in(in_32[7:0]),
      .z_en(z_en),
      .w_in(w_in[3]),
      .w_en(w_en),
      .ans_out(ans_out[3])
  );

  always @(*) begin
    w_in[0] = 8'b0;
    if (unit_en) begin
      case (w_2b_4[7:6])
        2'b00: w_in[0] = neg_w2;
        2'b01: w_in[0] = neg_w1;
        2'b11: w_in[0] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[1] = 8'b0;
    if (unit_en) begin
      case (w_2b_4[5:4])
        2'b00: w_in[1] = neg_w2;
        2'b01: w_in[1] = neg_w1;
        2'b11: w_in[1] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[2] = 8'b0;
    if (unit_en) begin
      case (w_2b_4[3:2])
        2'b00: w_in[2] = neg_w2;
        2'b01: w_in[2] = neg_w1;
        2'b11: w_in[2] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[3] = 8'b0;
    if (unit_en) begin
      case (w_2b_4[1:0])
        2'b00: w_in[3] = neg_w2;
        2'b01: w_in[3] = neg_w1;
        2'b11: w_in[3] = pos_w;
      endcase
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      dout_32 <= 0;
    end else begin
      dout_32 <= ans_out[0] + ans_out[1] + ans_out[2] + ans_out[3];
    end
  end

endmodule
`endif
