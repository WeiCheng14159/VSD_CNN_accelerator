`ifndef ACCUM_SV
`define ACCUM_SV

module accum (
    input  logic                       clk,
    input  logic                       rst,
    input  logic [`DATA_BUS_WIDTH-1:0] result,
    input  logic                       out_en,
    input  logic                       out_state,
    output logic [`ADDR_BUS_WIDTH-1:0] mk_p0_addr,
    input  logic [`DATA_BUS_WIDTH-1:0] mk_p0_data,
    output logic [                3:0] mk_p1_w,
    output logic [`ADDR_BUS_WIDTH-1:0] mk_p1_addr,
    output logic [`DATA_BUS_WIDTH-1:0] mk_p1_data,
    input  logic                       mb_push,
    input  logic [`DATA_BUS_WIDTH-1:0] mb_in,
    output logic [`DATA_BUS_WIDTH-1:0] bias,
    input  logic                       first,
    input  logic                       last,
    input  logic [   `PARAM_WIDTH-1:0] in_ch_cnt,
    input  logic [   `PARAM_WIDTH-1:0] out_ch_cnt,
    input  logic                       out_ch_c,
    output logic [`DATA_BUS_WIDTH-1:0] Mout_data
);

  logic signed [`ADDR_BUS_WIDTH-1:0] add_ans;
  logic signed [`DATA_BUS_WIDTH-1:0] r_reg;
  logic                              en_reg;
  logic        [   `PARAM_WIDTH-1:0] in_ch_reg;

  assign add_ans = first ? r_reg : (mk_p0_data + r_reg);

  //regs
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      r_reg <= `EMPTY_DATA;
      en_reg <= 1'b0;
      in_ch_reg <= {`PARAM_WIDTH{1'b0}};
    end else begin
      r_reg <= result;
      en_reg <= out_en;
      in_ch_reg <= in_ch_cnt;
    end
  end

  //bias
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      bias <= `EMPTY_DATA;
    end else begin
      if (mb_push) bias <= mb_in;
    end
  end

  //mk_p0_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mk_p0_addr <= `EMPTY_ADDR;
    end else begin
      if (in_ch_cnt != in_ch_reg) mk_p0_addr <= `EMPTY_ADDR;
      else if (out_en) mk_p0_addr <= mk_p0_addr + `ADDR_BUS_WIDTH'h4;

    end
  end

  //mk_p1_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mk_p1_addr <= `EMPTY_ADDR;
    end else begin
      if (out_en) mk_p1_addr <= mk_p0_addr;
    end
  end

  //mk_p1_w
  always @(*) begin
    mk_p1_w <= {`W_REQ_WIDTH{en_reg}};
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
