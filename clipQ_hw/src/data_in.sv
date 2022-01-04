`ifndef DATA_IN_SV
`define DATA_IN_SV

module data_in (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] Min_R_data,
    input  logic [ 1:0] padding_type,
    output logic [31:0] cal_data_in
);

  //in_reg
  logic [31:0] in_reg;
  logic [7:0] in_reg2;

  //2bit w
  logic [32*9-1:0] chain;
  logic [7:0] weight;

  //pt_reg
  logic [1:0] pt_reg;

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
