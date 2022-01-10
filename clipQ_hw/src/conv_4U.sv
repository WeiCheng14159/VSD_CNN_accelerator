`ifndef CONV_4U_SV
`define CONV_4U_SV
`include "conv_25.sv"
`include "conv_acc.svh"

module conv_4U (
    input  logic                       rst,
    input  logic                       clk,
    input  logic [`DATA_BUS_WIDTH-1:0] din_32,
    output logic [`DATA_BUS_WIDTH-1:0] dout_32,
    input  logic                       unit_en,
    input  logic [                7:0] k_size,
    input  logic [                7:0] w_2b_4,
    input  logic                       w_en,
    input  logic                       z_en,
    input  logic [                7:0] pos_w,
    input  logic [                7:0] neg_w1,
    input  logic [                7:0] neg_w2
);

  logic [`QDATA_BUS_WIDTH-1:0] w_in[0:3];
  logic [`DATA_BUS_WIDTH-1:0] ans_out[0:3];
  logic [`DATA_BUS_WIDTH-1:0] in_32;

  assign in_32 = unit_en ? din_32 : `EMPTY_DATA;

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
    w_in[0] = `EMPTY_QDATA;
    if (unit_en) begin
      case (w_2b_4[7:6])
        2'b00: w_in[0] = neg_w2;
        2'b01: w_in[0] = neg_w1;
        2'b11: w_in[0] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[1] = `EMPTY_QDATA;
    if (unit_en) begin
      case (w_2b_4[5:4])
        2'b00: w_in[1] = neg_w2;
        2'b01: w_in[1] = neg_w1;
        2'b11: w_in[1] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[2] = `EMPTY_QDATA;
    if (unit_en) begin
      case (w_2b_4[3:2])
        2'b00: w_in[2] = neg_w2;
        2'b01: w_in[2] = neg_w1;
        2'b11: w_in[2] = pos_w;
      endcase
    end
  end

  always @(*) begin
    w_in[3] = `EMPTY_QDATA;
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
      dout_32 <= `EMPTY_DATA;
    end else begin
      dout_32 <= ans_out[0] + ans_out[1] + ans_out[2] + ans_out[3];
    end
  end

endmodule
`endif
