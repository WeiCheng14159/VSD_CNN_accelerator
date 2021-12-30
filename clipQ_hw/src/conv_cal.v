`ifndef CONV_CAL_V
`define CONV_CAL_V

module conv_cal (
    clk,
    rst,
    data_in,
    w_in,
    group,
    ans_out

);

  input clk, rst;
  input [23:0] data_in;
  input [8*9-1:0] w_in;
  input group;
  output  reg [31:0] ans_out;

  integer i;

  wire signed [7:0] in[2:0];
  wire signed [7:0] w[8:0];
  wire signed [15:0] mul[8:0];
  wire signed [31:0] add[2:0];

  reg signed [31:0] pip[4:0];

  assign in[0]  = data_in[23:16];
  assign in[1]  = data_in[15:8];
  assign in[2]  = data_in[7:0];

  assign w[0]   = group ? w_in[71:64] : w_in[55:48];
  assign w[1]   = w_in[63:56];
  assign w[2]   = group ? w_in[55:48] : w_in[71:64];

  assign w[3]   = group ? w_in[47:40] : w_in[31:24];
  assign w[4]   = w_in[39:32];
  assign w[5]   = group ? w_in[31:24] : w_in[47:40];

  assign w[6]   = group ? w_in[23:16] : w_in[7:0];
  assign w[7]   = w_in[15:8];
  assign w[8]   = group ? w_in[7:0] : w_in[23:16];


  assign mul[0] = in[0] * w[0];
  assign mul[1] = in[1] * w[1];
  assign mul[2] = in[2] * w[2];

  assign mul[3] = in[0] * w[3];
  assign mul[4] = in[1] * w[4];
  assign mul[5] = in[2] * w[5];

  assign mul[6] = in[0] * w[6];
  assign mul[7] = in[1] * w[7];
  assign mul[8] = in[2] * w[8];

  assign add[0] = mul[0] + mul[1];
  assign add[1] = mul[3] + mul[4];
  assign add[2] = mul[6] + mul[7];

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      ans_out <= 32'b0;
    end else begin
      ans_out <= pip[4] + mul[8];
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      for (i = 0; i < 5; i = i + 1) pip[i] <= 0;
    end else begin
      pip[0] <= add[0];
      pip[1] <= pip[0] + mul[2];
      pip[2] <= pip[1] + add[1];
      pip[3] <= pip[2] + mul[5];
      pip[4] <= pip[3] + add[2];

    end
  end

endmodule
`endif
