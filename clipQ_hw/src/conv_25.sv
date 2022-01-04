`ifndef CONV_25_SV
`define CONV_25_SV
`include "c_unit.sv"

module conv_25 (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] d_in,
    input  logic [ 7:0] w_in,
    input  logic        w_en,
    input  logic        z_en,
    output logic [31:0] ans_out
);

  logic signed [31:0] d_out[0:24];
  logic signed [ 7:0] w_out[0:24];
  logic signed [24:0] en;

  genvar i;

  assign ans_out = d_out[24];

  c_unit first_U (
      .clk(clk),
      .rst(rst),
      .en_pu(w_en),
      .en_in(en[23]),
      .en(en[24]),
      .zero_en(z_en),
      .w_en(w_en),
      .w_out(w_out[24]),
      .w_in(w_out[23]),
      .l_in(32'b0),
      .d_in(d_in),
      .d_out(d_out[0])

  );

  c_unit last_U (
      .clk(clk),
      .rst(rst),
      .en_pu(w_en),
      .en_in(1'b1),
      .en(en[0]),
      .zero_en(z_en),
      .w_en(w_en),
      .w_in(w_in),
      .w_out(w_out[0]),
      .l_in(d_out[23]),
      .d_in(d_in),
      .d_out(d_out[24])
  );

  generate
    for (i = 1; i < 24; i = i + 1) begin : conv_unit
      c_unit U (
          .clk(clk),
          .rst(rst),
          .en_pu(w_en),
          .en_in(en[23-i]),
          .en(en[24-i]),
          .zero_en(z_en),
          .l_in(d_out[i-1]),
          .d_in(d_in),
          .w_en(w_en),
          .w_in(w_out[23-i]),
          .d_out(d_out[i]),
          .w_out(w_out[24-i])

      );
    end
  endgenerate

endmodule
`endif
