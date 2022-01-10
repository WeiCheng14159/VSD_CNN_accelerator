`ifndef OUT_COMB_SV
`define OUT_COMB_SV

module out_comb (
    input  logic [`ADDR_BUS_WIDTH-1:0] out0,
    input  logic [`ADDR_BUS_WIDTH-1:0] out1,
    input  logic [`ADDR_BUS_WIDTH-1:0] out2,
    input  logic [`ADDR_BUS_WIDTH-1:0] out3,
    output logic [`ADDR_BUS_WIDTH-1:0] out
);

  logic [`QDATA_BUS_WIDTH-1:0] out_tmp[0:3];
  logic [`QDATA_BUS_WIDTH-1:0] out_sig[0:3];

  assign out_tmp[0] = out0[31] ? out0[12:5] + 1 : out0[12:5];
  assign out_tmp[1] = out1[31] ? out1[12:5] + 1 : out1[12:5];
  assign out_tmp[2] = out2[31] ? out2[12:5] + 1 : out2[12:5];
  assign out_tmp[3] = out3[31] ? out3[12:5] + 1 : out3[12:5];

  assign out_sig[0] = ((~&out0[31:12]) && out0[31])? 8'b10000000 :
                    (|out0[31:12] && (~out0[31]))? 8'b01111111 : out_tmp[0];

  assign out_sig[1] = ((~&out1[31:12]) && out1[31])? 8'b10000000 :
                    (|out1[31:12] && (~out1[31]))? 8'b01111111 : out_tmp[1];

  assign out_sig[2] = ((~&out2[31:12]) && out2[31])? 8'b10000000 :
                    (|out2[31:12] && (~out2[31]))? 8'b01111111 : out_tmp[2];

  assign out_sig[3] = ((~&out3[31:12]) && out3[31])? 8'b10000000 :
                    (|out3[31:12] && (~out3[31]))? 8'b01111111 : out_tmp[3];

  assign out = {out_sig[0], out_sig[1], out_sig[2], out_sig[3]};

endmodule
`endif
