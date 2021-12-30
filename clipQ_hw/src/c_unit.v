`ifndef C_UNIT_V
`define C_UNIT_V
module c_unit (
    clk,
    rst,
    l_in,
    d_in,
    en_pu,
    en_in,
    en,
    zero_en,
    w_en,
    w_in,
    d_out,
    w_out

);

  input clk, rst;
  input [7:0] d_in;
  input signed [31:0] l_in;

  input en_pu;
  input en_in;
  output reg en;
  input zero_en;

  input [7:0] w_in;
  input w_en;

  output reg signed [31:0] d_out;
  output reg signed [7:0] w_out;

  wire signed [ 7:0] in;

  wire signed [15:0] mul_r;
  //w_out
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      w_out <= 0;
    end else begin
      if (w_en) w_out <= w_in;
    end
  end

  //in
  assign in = en ? d_in : 8'b0;

  //mul_r & d_out
  assign mul_r = w_out * in;

  //d_out
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      d_out <= 0;
    end else begin
      d_out <= mul_r + l_in;
    end
  end

  //en
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      en <= 0;
    end else begin
      if (zero_en) en <= 0;
      else if (en_pu) en <= en_in;
    end
  end

endmodule
`endif
