`ifndef ACCUM_SV
`define ACCUM_SV

module accum (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] result,
    input  logic        out_en,
    input  logic        out_state,
    output logic [31:0] mk_p0_addr,
    input  logic [31:0] mk_p0_data,
    output logic [ 3:0] mk_p1_w,
    output logic [31:0] mk_p1_addr,
    output logic [31:0] mk_p1_data,
    input  logic        mb_push,
    input  logic [31:0] mb_in,
    output logic [31:0] bias,
    input  logic        first,
    input  logic        last,
    input  logic [15:0] in_ch_cnt,
    input  logic [15:0] out_ch_cnt,
    input  logic        out_ch_c,
    output logic [31:0] Mout_data
);

  logic signed [31:0] add_ans;
  logic signed [31:0] r_reg;
  logic               en_reg;
  logic        [15:0] in_ch_reg;

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
