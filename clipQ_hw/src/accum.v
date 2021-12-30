`ifndef ACCUM_V
`define ACCUM_V
module accum (
    clk,
    rst,

    result,
    out_en,
    out_state,

    mk_p0_addr,
    mk_p0_data,

    mk_p1_w,
    mk_p1_addr,
    mk_p1_data,

    mb_push,
    mb_in,
    bias,

    first,
    last,

    in_ch_cnt,
    out_ch_cnt,

    out_ch_c,

    Mout_data
);

  input clk, rst;
  input [31:0] result;
  input out_state;
  input out_en;

  output reg [31:0] mk_p0_addr;
  input [31:0] mk_p0_data;

  output reg [3:0] mk_p1_w;
  output reg [31:0] mk_p1_addr;
  output reg [31:0] mk_p1_data;

  input mb_push;
  input [31:0] mb_in;
  output reg [31:0] bias;

  input first;
  input last;

  input [15:0] in_ch_cnt;
  input [15:0] out_ch_cnt;

  input out_ch_c;

  output reg [31:0] Mout_data;

  wire signed [31:0] add_ans;

  reg signed  [31:0] r_reg;
  reg                en_reg;

  reg         [15:0] in_ch_reg;

  assign add_ans = first ? r_reg : (mk_p0_data + r_reg);

  //regs
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      r_reg <= 0;
      en_reg <= 0;
      in_ch_reg <= 0;
    end else begin
      r_reg <= result;
      en_reg <= out_en;
      in_ch_reg <= in_ch_cnt;
    end
  end

  //bias
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      bias <= 0;
    end else begin
      if (mb_push) bias <= mb_in;
    end
  end

  //mk_p0_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mk_p0_addr <= 0;
    end else begin
      if (in_ch_cnt != in_ch_reg) mk_p0_addr <= 0;
      else if (out_en) mk_p0_addr <= mk_p0_addr + 4;

    end
  end

  //mk_p1_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mk_p1_addr <= 0;
    end else begin
      if (out_en) mk_p1_addr <= mk_p0_addr;
    end
  end

  //mk_p1_w
  always @(*) begin
    mk_p1_w <= {4{en_reg}};
  end

  //mk_p1_data
  always @(*) begin
    mk_p1_data <= add_ans;
  end

  //Mout_data
  always @(*) begin
    Mout_data = add_ans + bias;
  end

endmodule

`endif
