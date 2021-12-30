`ifndef CTRL_V
`define CTRL_V
module ctrl (
    clk,
    rst,

    start,
    finish,

    Mp_addr,
    Mp_R_data,

    Min_addr,
    Mout_addr,
    Mout_W_req,
    Mw_addr,
    Mw_R_data,

    mb_en,
    mb_addr,


    k_size,
    u_en,
    w_en,
    z_en,

    pos_w,
    neg_w1,
    neg_w2,

    padding_type,

    first,
    last,
    out_state,
    out_en,

    in_ch_cnt,
    out_ch_cnt,
    out_ch_c
);

  // port

  input clk, rst;

  //cpu signal
  input start;
  output reg finish;

  //mem ctrl
  output  reg [31:0] Mp_addr;
  input [31:0] Mp_R_data;

  output  reg [31:0] Min_addr;
  output  reg [31:0] Mout_addr;
  output  reg [3:0] Mout_W_req;
  output  reg [31:0] Mw_addr;
  input [31:0] Mw_R_data;

  output reg mb_en;
  output reg [31:0] mb_addr;


  //padding
  output  reg [1:0] padding_type;

  //kernal_size & unit_ctrl
  output reg [7:0] k_size;
  output [3:0] u_en;
  output reg w_en;

  output reg z_en;

  //clipq 4 num
  output reg [7:0] pos_w;
  output reg [7:0] neg_w1;
  output reg [7:0] neg_w2;


  //output
  output reg first;
  output reg last;
  output reg out_state;
  output reg out_en;

  //in out channel(s5)
  output reg [15:0] in_ch_cnt;
  output reg [15:0] out_ch_cnt;
  output reg out_ch_c;

  integer            i;
  //state
  reg         [ 2:0] CS;
  reg         [ 2:0] NS;

  //fin signal
  reg                s1_fin;
  reg                s2_fin;
  reg                s3_fin;
  reg                s4_fin;
  reg                s5_fin;
  reg                s6_back;
  reg                s6_fin;
  //all_cnt
  reg         [15:0] all_cnt;

  //read_param(s1)
  reg         [15:0] param_reg    [0:3];
  wire        [15:0] row_col;
  wire        [15:0] in_ch;
  wire        [15:0] out_ch;

  //read_w8(s2)

  wire        [ 7:0] k_row;
  wire        [ 2:0] padding;

  //read_w2(s3)
  reg         [31:0] w_cnt;


  //read_input(s4)
  reg         [ 9:0] addr_cnt;
  reg signed  [ 5:0] ba_r_cnt;
  reg signed  [ 5:0] ba_c_cnt;
  wire signed [ 5:0] ba_r_add;

  reg         [ 5:0] inr_cnt;
  reg         [ 5:0] inc_cnt;
  reg         [ 4:0] r_cnt;
  reg         [ 7:0] posi;
  reg         [15:0] po_ch;
  reg         [ 9:0] in_add_ch;
  reg         [15:0] po_mul;
  reg         [15:0] pro_mul;
  reg         [ 1:0] pad;

  wire        [15:0] mul_ch;
  wire        [15:0] all_mul_ch;
  reg         [ 7:0] out_r;
  reg         [ 7:0] out_c;
  reg         [15:0] out_addr_cnt;
  reg                o_en_reg;
  reg                beg;

  reg         [15:0] out_ccnt;

  //in out channel(s6)
  reg         [15:0] out_d4_ch;
  reg                out_start;
  reg         [ 2:0] out_k_cnt;

  // FSM

  //CS
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      CS <= 3'b0;
    end else begin
      CS <= NS;
    end
  end

  //NS
  always @(*) begin
    NS = CS;
    case (CS)
      3'b000: begin
        if (start) NS = 3'b001;
      end
      3'b001: begin
        if (s1_fin) NS = 3'b010;
      end
      3'b010: begin
        if (s2_fin) NS = 3'b011;
      end
      3'b011: begin
        if (s3_fin) NS = 3'b100;
      end
      3'b100: begin
        if (s4_fin) NS = 3'b101;
      end
      3'b101: begin
        if (s5_fin) NS = 3'b110;
      end
      3'b110: begin
        if (s6_fin) NS = 3'b111;
        else if (s6_back) NS = 3'b011;
      end
    endcase
  end

  // all_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      all_cnt <= 0;
    end else begin
      if (NS != CS) begin
        all_cnt <= 0;
      end else begin
        all_cnt <= all_cnt + 1;
      end
    end
  end

  // read param (s1) 

  //s1_fin
  always @(*) begin
    s1_fin = 0;
    if (CS == 3'b001 && all_cnt == 4) s1_fin = 1;
  end

  //Mp_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mp_addr <= 0;
    end else begin
      if (CS == 3'b001) Mp_addr <= Mp_addr + 4;
      else if (CS == 3'b000) Mp_addr <= 0;
    end
  end

  //param_reg
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      for (i = 0; i < 4; i = i + 1) begin
        param_reg[i] <= 0;
      end
    end else begin
      if (CS == 3'b001) begin
        for (i = 1; i < 4; i = i + 1) begin
          param_reg[i] <= param_reg[i-1];
        end
        param_reg[0] <= Mp_R_data[15:0];
      end
    end
  end

  //parameter
  assign row_col = param_reg[3];
  assign in_ch   = param_reg[2];
  assign out_ch  = param_reg[1];

  //k_size
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      k_size <= 0;
    end else begin
      if (CS == 3'b010) k_size <= param_reg[0] * param_reg[0];
    end
  end

  //u_en
  assign u_en  = 4'b1111;
  assign k_row = param_reg[0][7:0];

  // read_w8(s2)

  //pos & neg
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      pos_w  <= 0;
      neg_w1 <= 0;
      neg_w2 <= 0;
    end else begin
      if (CS == 3'b010) begin
        pos_w  <= Mw_R_data[31:24];
        neg_w1 <= Mw_R_data[23:16];
        neg_w2 <= Mw_R_data[15:8];
      end
    end
  end

  //s2_fin
  always @(*) begin
    s2_fin = 0;
    if (CS == 3'b010 && all_cnt == 1) s2_fin = 1;
  end

  //padding
  assign padding = k_row[3:1];

  //
  //Mw_addr
  //

  //all_mul_ch
  assign all_mul_ch = {8'b0, in_ch[7:0]} * {8'b0, out_ch[7:0]};

  //Mw_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mw_addr <= 0;
    end else begin
      case (CS)
        3'b001: begin
          Mw_addr <= 0;
        end
        3'b010: begin
          if (all_cnt == 1) Mw_addr <= Mw_addr + 4;
        end
        3'b011: begin
          if (all_cnt < k_size) Mw_addr <= Mw_addr + 4;
        end
      endcase
    end
  end

  // read_w2(s3)

  //s3_fin
  always @(*) begin
    s3_fin = 0;
    if (CS == 3'b011) begin
      if (all_cnt >= k_size - 1 && all_cnt > 5) s3_fin = 1;
    end
  end

  //mb_en
  always @(*) begin
    mb_en = 0;
    if (CS == 3'b011 && all_cnt > 0 && all_cnt < 5 && last) mb_en = 1;
  end

  //mb_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mb_addr <= 0;
    end else begin
      if (CS == 3'b011 && all_cnt >= 0 && all_cnt < 4 && last)
        mb_addr <= mb_addr + 4;
      else if (CS == 3'b111) mb_addr <= 0;
    end
  end

  //w_en
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      w_en <= 0;
    end else begin
      if (CS == 3'b011 && all_cnt < k_size) begin
        w_en <= 1;
      end else begin
        w_en <= 0;
      end
    end
  end

  //z_en
  always @(*) begin
    z_en = 0;
    if (CS == 3'b101) z_en = 1;
  end

  // read_input(s4)

  //s4_fin
  always @(*) begin
    s4_fin = 0;
    if(CS == 3'b100 && ba_r_cnt == row_col-1-padding && ba_c_cnt == row_col -1 + padding && r_cnt == k_row-1)begin
      s4_fin = 1;
    end
  end

  //ba_r_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      ba_r_cnt <= -1;
    end else begin

      if (CS == 3'b011 && k_row == 1) begin
        ba_r_cnt <= 0;
      end else if (CS == 3'b100) begin
        if (k_row == 1) begin
          if (ba_c_cnt == row_col - 1) begin
            if (ba_r_cnt == row_col - 1) ba_r_cnt <= 0;
            else ba_r_cnt <= ba_r_cnt + 1;
          end
        end else begin
          if (ba_c_cnt == row_col && r_cnt == k_row - 1) begin
            if (ba_r_cnt == row_col) ba_r_cnt <= -1;
            else ba_r_cnt <= ba_r_cnt + 1;
          end
        end
      end else if (CS == 3'b101) begin
        if (k_row == 1) begin
          ba_r_cnt <= 0;
        end else begin
          ba_r_cnt <= -1;
        end
      end
    end
  end

  //ba_c_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      ba_c_cnt <= -1;
    end else begin
      if (CS == 3'b011 && k_row == 1) begin
        ba_c_cnt <= 0;
      end else if (CS == 3'b100) begin
        if (k_row == 1) begin
          if (ba_c_cnt == row_col - 1) begin
            ba_c_cnt <= 0;
          end else begin
            ba_c_cnt <= ba_c_cnt + 1;
          end
        end else begin
          if (r_cnt == k_row - 1) begin
            if (ba_c_cnt == row_col) begin
              ba_c_cnt <= -1;
            end else begin
              ba_c_cnt <= ba_c_cnt + 1;
            end
          end
        end
      end else if (CS == 3'b101) begin
        if (k_row == 1) begin
          ba_c_cnt <= 0;
        end else begin
          ba_c_cnt <= -1;
        end
      end
    end
  end

  //r_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      r_cnt <= 0;
    end else begin
      if (CS == 3'b100) begin
        if (r_cnt == k_row - 1) r_cnt <= 0;
        else r_cnt <= r_cnt + 1;
      end
    end
  end

  //padding_type
  always @(*) begin
    pad = 2'b11;
    if (k_row != 1) begin
      if (ba_c_cnt == 6'b111111 || ba_c_cnt == row_col) begin
        pad = 2'b00;
      end else if (ba_r_cnt == 6'b111111 && r_cnt == 0) begin
        pad = 2'b01;
      end else if (ba_r_cnt == row_col - 2 && r_cnt == k_row - 1) begin
        pad = 2'b10;
      end
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      padding_type <= 2'b11;
    end else begin
      padding_type <= pad;
    end
  end

  //mul_ch
  assign mul_ch = in_ch_cnt;

  //in_add_ch
  always @(*) begin
    in_add_ch = in_ch[9:2] + 1;
    if (in_ch[1:0] == 2'b00) in_add_ch = in_ch[9:2];
  end

  //posi
  always @(*) begin
    posi = 1;
    if (r_cnt == k_row - 1) posi = row_col - r_cnt;
  end

  //po_ch
  always @(*) begin
    po_ch = po_mul;
    if (r_cnt != k_row - 1) po_ch = in_add_ch;
  end

  //ba_r_add
  assign ba_r_add = ba_r_cnt + 1;

  //po_mul
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      po_mul <= 0;
    end else begin
      po_mul <= (row_col - k_row + 1) * in_add_ch;
    end
  end

  //pro_mul
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      pro_mul <= 0;
    end else begin
      pro_mul <= ba_r_add * in_add_ch;
    end
  end

  //Min_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Min_addr <= 0;
    end else begin
      if (CS == 3'b100 && all_cnt < k_row) Min_addr <= 0 - k_row[1];
      else if (CS == 3'b110) Min_addr <= in_ch_cnt;
      else if (ba_c_cnt == row_col - 1 + padding && r_cnt == k_row - 1)
        Min_addr <= pro_mul;
      else if (ba_c_cnt != -1 && ba_c_cnt != row_col)
        Min_addr <= Min_addr + po_ch;
    end
  end

  //first
  always @(*) begin
    first = 0;
    if (in_ch_cnt == 0) first = 1;
  end

  //last
  always @(*) begin
    last = 0;
    if (in_ch_cnt == in_add_ch - 1) last = 1;
  end


  //out_state
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_state <= 0;
    end else begin
      out_state <= 0;
    end
  end

  //out_start
  reg [31:0] out_k_cnt_r;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_k_cnt_r <= 0;
    end else begin
      if (CS[2:1] == 2'b10 && ba_c_cnt >= k_row - 1 && beg) begin
        if (out_k_cnt_r == k_row - 1) begin
          out_k_cnt_r <= 0;
        end else begin
          out_k_cnt_r <= out_k_cnt_r + 1;
        end
      end else begin
        out_k_cnt_r <= 0;
      end
    end
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_k_cnt <= 0;
    end else begin
      out_k_cnt <= out_k_cnt_r;
    end
  end


  //out_ccnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_ccnt <= 0;
    end else begin
      if (CS == 3'b100 && Mout_W_req) out_ccnt <= out_ccnt + 1;
    end
  end

  //out_en
  always @(*) begin
    out_en = 0;
    if (out_k_cnt == k_row - 1 && CS == 3'b100 && all_cnt > 2) out_en = 1;
    else if (out_k_cnt == k_row - 1 && CS == 3'b101) out_en = 1;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      beg <= 0;
    end else begin
      if (CS == 3'b110) beg <= 0;
      else if (CS == 3'b100 && all_cnt == k_size - 1) beg <= 1;
    end
  end

  //out_r
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_r <= 0;
    end else begin
      if (CS[2:1] == 2'b10 && out_en) begin
        if (out_c == row_col - 1) begin
          if (out_r == row_col - 1) out_r <= 0;
          else out_r <= out_r + 1;
        end
      end else if (CS == 3'b110) begin
        out_r <= 0;
      end
    end
  end

  //out_c
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_c <= 0;
    end else begin
      if (CS[2:1] == 2'b10 && out_en) begin
        if (out_c == row_col - 1) begin
          out_c <= 0;
        end else begin
          out_c <= out_c + 1;
        end
      end else if (CS == 3'b110) begin
        out_c <= 0;
      end
    end
  end

  //Mout_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mout_addr <= 0;
    end else begin
      if (CS == 3'b111) Mout_addr <= 0;
      else if (CS == 3'b011) Mout_addr <= out_ch_cnt;
      else if (Mout_W_req) begin
        if (out_c == 0) Mout_addr <= out_r * out_d4_ch + out_ch_cnt;
        else Mout_addr <= Mout_addr + out_d4_ch * row_col;
      end
    end
  end

  //Mout_W_req
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mout_W_req <= 4'b0;
    end else begin
      if (last && out_en && CS > 3) Mout_W_req <= 4'b1111;
      else Mout_W_req <= 4'b0;
    end
  end

  // s5
  always @(*) begin
    s5_fin = 0;
    if (all_cnt == k_row) s5_fin = 1;
  end

  // input ch(s6)

  //s6_back
  always @(*) begin
    s6_back = 0;
    if (CS == 3'b110 && out_ch_cnt != out_d4_ch - 1) s6_back = 1;
  end

  //s6_fin
  always @(*) begin
    s6_fin = 0;
    if (CS == 3'b110 && out_ch_cnt == out_d4_ch - 1) s6_fin = 1;
  end

  //out_d4_ch
  always @(*) begin
    out_d4_ch = out_ch[15:2] + 1;
    if (out_ch[1:0] == 2'b00) out_d4_ch = out_ch[15:2];
  end

  //in_ch_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      in_ch_cnt <= 0;
    end else begin
      if (CS == 3'b110) begin
        if (in_ch_cnt == in_add_ch - 1) in_ch_cnt <= 0;
        else in_ch_cnt <= in_ch_cnt + 1;
      end
    end
  end

  //out_ch_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_ch_cnt <= 0;
    end else begin
      if (CS == 3'b110 && in_ch_cnt == in_add_ch - 1) begin
        out_ch_cnt <= out_ch_cnt + 1;
      end
    end
  end

  // finish
  always @(*) begin
    finish = 0;
    if (CS == 3'b111) finish = 1;
  end

endmodule

`endif
