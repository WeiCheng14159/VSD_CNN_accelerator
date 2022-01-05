`ifndef CTRL_SV
`define CTRL_SV

`include "conv_acc.svh"

module ctrl (
    input  logic                           clk,
    input  logic                           rst,
    // Control signal
    input  logic                           start,
    output logic                           finish,
    // Mem ctrl
    output logic [    `ADDR_BUS_WIDTH-1:0] Mp_addr,
    input  logic [    `DATA_BUS_WIDTH-1:0] Mp_R_data,
    output logic [    `ADDR_BUS_WIDTH-1:0] Min_addr,
    output logic [    `ADDR_BUS_WIDTH-1:0] Mout_addr,
    output logic [       `W_REQ_WIDTH-1:0] Mout_W_req,
    output logic [    `ADDR_BUS_WIDTH-1:0] Mw_addr,
    input  logic [    `DATA_BUS_WIDTH-1:0] Mw_R_data,
    output logic                           mb_en,
    output logic [    `ADDR_BUS_WIDTH-1:0] mb_addr,
    // kernal_size & unit_ctrl
    output logic [                    7:0] k_size,
    output logic [                    3:0] u_en,
    output logic                           w_en,
    output logic                           z_en,
    //clipq 4 num
    output logic [                    7:0] pos_w,
    output logic [                    7:0] neg_w1,
    output logic [                    7:0] neg_w2,
    // padding
    output logic [`PADDING_TYPE_WIDTH-1:0] padding_type,
    output logic                           first,
    output logic                           last,
    output logic                           out_state,
    output logic                           out_en,
    // in out channel(s5)
    output logic [       `PARAM_WIDTH-1:0] in_ch_cnt,
    output logic [       `PARAM_WIDTH-1:0] out_ch_cnt,
    output logic                           out_ch_c
);

  localparam S_IDLE_BIT = 0, S_READ_PARAM_BIT = 1, S_READ_W8_BIT = 2, S_READ_W2_BIT = 3, 
  S_READ_INPUT_BIT = 4, S5_BIT = 5, S_IN_OUT_CH_BIT = 6, S_FINISH_BIT = 7;

  typedef enum logic [S_FINISH_BIT:0] {
    S_IDLE = 1 << S_IDLE_BIT,
    S_READ_PARAM = 1 << S_READ_PARAM_BIT,
    S_READ_W8 = 1 << S_READ_W8_BIT,
    S_READ_W2 = 1 << S_READ_W2_BIT,
    S_READ_INPUT = 1 << S_READ_INPUT_BIT,
    S5 = 1 << S5_BIT,
    S_IN_OUT_CH = 1 << S_IN_OUT_CH_BIT,
    S_FINISH = 1 << S_FINISH_BIT
  } fsm_state_t;

  integer i;
  fsm_state_t curr_state, next_state;

  // done signal
  logic                           read_param_done;
  logic                           read_w8_done;
  logic                           read_w2_done;
  logic                           read_input_done;
  logic                           s5_fin;
  logic                           in_out_ch_back;
  logic                           in_out_ch_done;
  // all_cnt
  logic        [            15:0] all_cnt;

  // read_param(s1)
  logic        [`PARAM_WIDTH-1:0] param_r         [0:3];
  logic        [`PARAM_WIDTH-1:0] row_col;
  logic        [`PARAM_WIDTH-1:0] in_ch;
  logic        [`PARAM_WIDTH-1:0] out_ch;

  // read_w8(s2)

  logic        [             7:0] k_row;
  logic        [             2:0] padding;

  // read_w2(s3)
  logic        [            31:0] w_cnt;

  // read_input(s4)
  logic        [             9:0] addr_cnt;
  logic signed [             5:0] ba_r_cnt;
  logic signed [             5:0] ba_c_cnt;
  logic signed [             5:0] ba_r_add;

  logic        [             5:0] inr_cnt;
  logic        [             5:0] inc_cnt;
  logic        [             4:0] r_cnt;
  logic        [             7:0] posi;
  logic        [            15:0] po_ch;
  logic        [             9:0] in_add_ch;
  logic        [            15:0] po_mul;
  logic        [            15:0] pro_mul;
  logic        [             1:0] pad;

  logic        [            15:0] mul_ch;
  logic        [            15:0] all_mul_ch;
  logic        [             7:0] out_r;
  logic        [             7:0] out_c;
  logic        [            15:0] out_addr_cnt;
  logic                           o_en_reg;
  logic                           beg;

  logic        [            15:0] out_ccnt;

  // in out channel(s6)
  logic        [            15:0] out_d4_ch;
  logic                           out_start;
  logic        [             2:0] out_k_cnt;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      curr_state <= S_IDLE;
    end else begin
      curr_state <= next_state;
    end
  end  // State (S)

  always @(*) begin
    next_state = curr_state;
    case (curr_state)
      S_IDLE: begin
        if (start) next_state = S_READ_PARAM;
      end
      S_READ_PARAM: begin
        if (read_param_done) next_state = S_READ_W8;
      end
      S_READ_W8: begin
        if (read_w8_done) next_state = S_READ_W2;
      end
      S_READ_W2: begin
        if (read_w2_done) next_state = S_READ_INPUT;
      end
      S_READ_INPUT: begin
        if (read_input_done) next_state = S5;
      end
      S5: begin
        if (s5_fin) next_state = S_IN_OUT_CH;
      end
      S_IN_OUT_CH: begin
        if (in_out_ch_done) next_state = S_FINISH;
        else if (in_out_ch_back) next_state = S_READ_W2;
      end
      S_FINISH: begin
        next_state = S_FINISH;
      end
      default: ;
    endcase
  end  // Next state (C)

  // all_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      all_cnt <= 0;
    end else begin
      if (next_state != curr_state) begin
        all_cnt <= 0;
      end else begin
        all_cnt <= all_cnt + 1;
      end
    end
  end

  /* Read param (S1) */

  // read_param_done
  always @(*) begin
    read_param_done = 0;
    if (curr_state == S_READ_PARAM && all_cnt == 4) read_param_done = 1;
  end

  // Mp_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mp_addr <= 0;
    end else begin
      if (curr_state == S_READ_PARAM) Mp_addr <= Mp_addr + 4;
      else if (curr_state == S_IDLE) Mp_addr <= 0;
    end
  end

  // param_r
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      for (i = 0; i < 4; i = i + 1) begin
        param_r[i] <= {`PARAM_WIDTH{1'b0}};
      end
    end else begin
      if (curr_state == S_READ_PARAM) begin
        for (i = 1; i < 4; i = i + 1) begin
          param_r[i] <= param_r[i-1];
        end
        param_r[0] <= Mp_R_data[`PARAM_WIDTH-1:0];
      end
    end
  end

  // parameter
  assign row_col = param_r[3];
  assign in_ch   = param_r[2];
  assign out_ch  = param_r[1];

  // k_size
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      k_size <= 0;
    end else begin
      if (curr_state == S_READ_W8) k_size <= param_r[0] * param_r[0];
    end
  end

  // u_en
  assign u_en  = 4'b1111;
  assign k_row = param_r[0][7:0];

  /* Read W8 (S2) */

  // pos & neg
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      pos_w  <= 0;
      neg_w1 <= 0;
      neg_w2 <= 0;
    end else begin
      if (curr_state == S_READ_W8) begin
        pos_w  <= Mw_R_data[31:24];
        neg_w1 <= Mw_R_data[23:16];
        neg_w2 <= Mw_R_data[15:8];
      end
    end
  end

  // read_w8_done
  always @(*) begin
    read_w8_done = 0;
    if (curr_state == S_READ_W8 && all_cnt == 1) read_w8_done = 1;
  end

  // padding
  assign padding = k_row[3:1];

  //
  // Mw_addr
  //

  // all_mul_ch
  assign all_mul_ch = {8'b0, in_ch[7:0]} * {8'b0, out_ch[7:0]};

  // Mw_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mw_addr <= `EMPTY_ADDR;
    end else begin
      case (curr_state)
        S_READ_PARAM: begin
          Mw_addr <= `EMPTY_ADDR;
        end
        S_READ_W8: begin
          if (all_cnt == 1) Mw_addr <= Mw_addr + `ADDR_BUS_WIDTH'h4;
        end
        S_READ_W2: begin
          if (all_cnt < k_size) Mw_addr <= Mw_addr + `ADDR_BUS_WIDTH'h4;
        end
      endcase
    end
  end

  /* Read W2 (S3) */

  // read_w2_done
  always @(*) begin
    read_w2_done = 0;
    if (curr_state == S_READ_W2) begin
      if (all_cnt >= k_size - 1 && all_cnt > 5) read_w2_done = 1;
    end
  end

  // mb_en
  always @(*) begin
    mb_en = 0;
    if (curr_state == S_READ_W2 && all_cnt > 0 && all_cnt < 5 && last)
      mb_en = 1;
  end

  // mb_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      mb_addr <= `EMPTY_ADDR;
    end else begin
      if (curr_state == S_READ_W2 && all_cnt >= 0 && all_cnt < 4 && last)
        mb_addr <= mb_addr + `ADDR_BUS_WIDTH'h4;
      else if (curr_state == S_FINISH) mb_addr <= `EMPTY_ADDR;
    end
  end

  // w_en
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      w_en <= 0;
    end else begin
      if (curr_state == S_READ_W2 && all_cnt < k_size) begin
        w_en <= 1;
      end else begin
        w_en <= 0;
      end
    end
  end

  // z_en
  always @(*) begin
    z_en = 0;
    if (curr_state == S5) z_en = 1;
  end

  /* Read Input (S4) */

  // read_input_done
  always @(*) begin
    read_input_done = 0;
    if(curr_state == S_READ_INPUT && ba_r_cnt == row_col-1-padding && ba_c_cnt == row_col -1 + padding && r_cnt == k_row-1)begin
      read_input_done = 1;
    end
  end

  // ba_r_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      ba_r_cnt <= -1;
    end else begin

      if (curr_state == S_READ_W2 && k_row == 1) begin
        ba_r_cnt <= 0;
      end else if (curr_state == S_READ_INPUT) begin
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
      end else if (curr_state == S5) begin
        if (k_row == 1) begin
          ba_r_cnt <= 0;
        end else begin
          ba_r_cnt <= -1;
        end
      end
    end
  end

  // ba_c_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      ba_c_cnt <= -1;
    end else begin
      if (curr_state == S_READ_W2 && k_row == 1) begin
        ba_c_cnt <= 0;
      end else if (curr_state == S_READ_INPUT) begin
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
      end else if (curr_state == S5) begin
        if (k_row == 1) begin
          ba_c_cnt <= 0;
        end else begin
          ba_c_cnt <= -1;
        end
      end
    end
  end

  // r_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      r_cnt <= 0;
    end else begin
      if (curr_state == S_READ_INPUT) begin
        if (r_cnt == k_row - 1) r_cnt <= 0;
        else r_cnt <= r_cnt + 1;
      end
    end
  end

  // padding_type
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

  // mul_ch
  assign mul_ch = in_ch_cnt;

  // in_add_ch
  always @(*) begin
    in_add_ch = in_ch[9:2] + 1;
    if (in_ch[1:0] == 2'b00) in_add_ch = in_ch[9:2];
  end

  // posi
  always @(*) begin
    posi = 1;
    if (r_cnt == k_row - 1) posi = row_col - r_cnt;
  end

  // po_ch
  always @(*) begin
    po_ch = po_mul;
    if (r_cnt != k_row - 1) po_ch = in_add_ch;
  end

  // ba_r_add
  assign ba_r_add = ba_r_cnt + 1;

  // po_mul
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      po_mul <= 0;
    end else begin
      po_mul <= (row_col - k_row + 1) * in_add_ch;
    end
  end

  // pro_mul
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      pro_mul <= 0;
    end else begin
      pro_mul <= ba_r_add * in_add_ch;
    end
  end

  // Min_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Min_addr <= 0;
    end else begin
      if (curr_state == S_READ_INPUT && all_cnt < k_row)
        Min_addr <= 0 - k_row[1];
      else if (curr_state == S_IN_OUT_CH) Min_addr <= in_ch_cnt;
      else if (ba_c_cnt == row_col - 1 + padding && r_cnt == k_row - 1)
        Min_addr <= pro_mul;
      else if (ba_c_cnt != -1 && ba_c_cnt != row_col)
        Min_addr <= Min_addr + po_ch;
    end
  end

  // first
  always @(*) begin
    first = 0;
    if (in_ch_cnt == 0) first = 1;
  end

  // last
  always @(*) begin
    last = 0;
    if (in_ch_cnt == in_add_ch - 1) last = 1;
  end


  // out_state
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_state <= 0;
    end else begin
      out_state <= 0;
    end
  end

  // out_start
  logic [31:0] out_k_cnt_r;
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_k_cnt_r <= 0;
    end else begin
      if ( (curr_state == S_READ_INPUT | curr_state == S5) && ba_c_cnt >= k_row - 1 && beg) begin
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


  // out_ccnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_ccnt <= 0;
    end else begin
      if (curr_state == S_READ_INPUT && Mout_W_req) out_ccnt <= out_ccnt + 1;
    end
  end

  // out_en
  always @(*) begin
    out_en = 0;
    if (out_k_cnt == k_row - 1 && curr_state == S_READ_INPUT && all_cnt > 2)
      out_en = 1;
    else if (out_k_cnt == k_row - 1 && curr_state == S5) out_en = 1;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      beg <= 0;
    end else begin
      if (curr_state == S_IN_OUT_CH) beg <= 0;
      else if (curr_state == S_READ_INPUT && all_cnt == k_size - 1) beg <= 1;
    end
  end

  // out_r
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_r <= 0;
    end else begin
      if ((curr_state == S_READ_INPUT | curr_state == S5) && out_en) begin
        if (out_c == row_col - 1) begin
          if (out_r == row_col - 1) out_r <= 0;
          else out_r <= out_r + 1;
        end
      end else if (curr_state == S_IN_OUT_CH) begin
        out_r <= 0;
      end
    end
  end

  // out_c
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_c <= 0;
    end else begin
      if ((curr_state == S_READ_INPUT | curr_state == S5) && out_en) begin
        if (out_c == row_col - 1) begin
          out_c <= 0;
        end else begin
          out_c <= out_c + 1;
        end
      end else if (curr_state == S_IN_OUT_CH) begin
        out_c <= 0;
      end
    end
  end

  // Mout_addr
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mout_addr <= `EMPTY_ADDR;
    end else begin
      if (curr_state == S_FINISH) Mout_addr <= `EMPTY_ADDR;
      else if (curr_state == S_READ_W2) Mout_addr <= out_ch_cnt;
      else if (Mout_W_req) begin
        if (out_c == 0) Mout_addr <= out_r * out_d4_ch + out_ch_cnt;
        else Mout_addr <= Mout_addr + out_d4_ch * row_col;
      end
    end
  end

  // Mout_W_req
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      Mout_W_req <= {`W_REQ_WIDTH{`WRITE_DIS}};
    end else begin
      if (last && out_en && curr_state > S_READ_W2)
        Mout_W_req <= {`W_REQ_WIDTH{`WRITE_ENB}};
      else Mout_W_req <= {`W_REQ_WIDTH{`WRITE_DIS}};
    end
  end

  // s5
  always @(*) begin
    s5_fin = 0;
    if (all_cnt == k_row) s5_fin = 1;
  end

  /* In out channel (S6) */

  // in_out_ch_back
  always @(*) begin
    in_out_ch_back = 0;
    if (curr_state == S_IN_OUT_CH && out_ch_cnt != out_d4_ch - 1)
      in_out_ch_back = 1;
  end

  // in_out_ch_done
  always @(*) begin
    in_out_ch_done = 0;
    if (curr_state == S_IN_OUT_CH && out_ch_cnt == out_d4_ch - 1)
      in_out_ch_done = 1;
  end

  // out_d4_ch
  always @(*) begin
    out_d4_ch = out_ch[15:2] + 1;
    if (out_ch[1:0] == 2'b00) out_d4_ch = out_ch[15:2];
  end

  // in_ch_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      in_ch_cnt <= 0;
    end else begin
      if (curr_state == S_IN_OUT_CH) begin
        if (in_ch_cnt == in_add_ch - 1) in_ch_cnt <= 0;
        else in_ch_cnt <= in_ch_cnt + 1;
      end
    end
  end

  // out_ch_cnt
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      out_ch_cnt <= 0;
    end else begin
      if (curr_state == S_IN_OUT_CH && in_ch_cnt == in_add_ch - 1) begin
        out_ch_cnt <= out_ch_cnt + 1;
      end
    end
  end

  /* Finish (S7) */
  // finish
  always @(*) begin
    finish = 0;
    if (curr_state == S_FINISH) finish = 1;
  end

endmodule

`endif
