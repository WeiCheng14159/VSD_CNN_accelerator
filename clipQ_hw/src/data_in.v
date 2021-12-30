`ifndef DATA_IN_V
`define DATA_IN_V
module data_in (
    clk,
    rst,
    Min_R_data,
    padding_type,
    cal_data_in
);

  input clk, rst;

  input [31:0] Min_R_data;

  input [1:0] padding_type;

  output reg [31:0] cal_data_in;

  //in_reg
  reg [31:0] in_reg;
  reg [7:0] in_reg2;

  //2bit w
  reg [32*9-1:0] chain;
  reg [7:0] weight;

  //pt_reg
  reg [1:0] pt_reg;

  //cal_data_in
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      cal_data_in <= 0;
    end else begin
      if (padding_type != 2'b11) begin
        cal_data_in <= 0;
      end else begin
        cal_data_in <= Min_R_data;
      end
    end
  end

endmodule

`endif
