`ifndef C_UNIT_SV
`define C_UNIT_SV
module c_unit (
    input  logic               clk,
    input  logic               rst,
    input  logic signed [31:0] l_in,
    input  logic        [ 7:0] d_in,
    input  logic               en_pu,
    input  logic               en_in,
    output logic               en,
    input  logic               zero_en,
    input  logic               w_en,
    input  logic        [ 7:0] w_in,
    output logic signed [31:0] d_out,
    output logic signed [ 7:0] w_out
);

  logic signed [ 7:0] in;
  logic signed [15:0] mul_r;

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
