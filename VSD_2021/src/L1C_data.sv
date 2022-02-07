//================================================
// Auther:      CHIEH-SHIH WANG
// Filename:    L1C_data.sv
// Description: L1 Cache for data
// Version:     1.0
//================================================
`include "../include/def.svh"
`include "./tag_array_wrapper.sv"
`include "./data_array_wrapper.sv"

module L1C_data (
    input                                      clk,
    rst,
    // Core to CPU wrapper
    input        [`DATA_BITS             -1:0] core_addr,
    input                                      core_req,
    input                                      core_write,
    input        [`DATA_BITS             -1:0] core_in,
    input        [`CACHE_TYPE_BITS       -1:0] core_type,
    // Mem to CPU wrapper
    input        [`DATA_BITS             -1:0] D_out,
    input                                      D_wait,
    // CPU wrapper to core
    output logic [       `DATA_BITS      -1:0] core_out,
    output logic                               core_wait,
    // CPU wrapper to Mem
    output logic                               D_wreq,
    D_rreq,
    output logic [       `DATA_BITS      -1:0] D_addr,
    output logic                               D_write,
    output logic [       `DATA_BITS      -1:0] D_in,
    output logic [       `CACHE_TYPE_BITS-1:0] D_type,
    // 
    output logic                               arlenone_o
);

  logic [`CACHE_IDX_BITS  -1:0] index;
  logic [`CACHE_DATA_BITS -1:0] DA_out;
  logic [`CACHE_DATA_BITS -1:0] DA_in;
  logic [`CACHE_WRITE_BITS-1:0] DA_write;
  logic DA_read;
  logic [`CACHE_TAG_BITS-1:0] TA_out;
  logic [`CACHE_TAG_BITS-1:0] TA_in;
  logic TA_write;
  logic TA_read;
  logic [`CACHE_LINE_BITS-1:0] valid;

  //--------------- complete this part by yourself -----------------//
  // STATE
  parameter INIT  = 3'h0,
              CHK   = 3'h1,
              WHIT  = 3'h2, WMISS = 3'h3,
              RMISS = 3'h4,
              NOUSE = 3'h5, FIN   = 3'h6;
  logic [2:0] STATE, NEXT;
  // Sample
  logic [ `ADDR_BITS      -1:0] c_addr;
  logic [ `DATA_BITS      -1:0] c_in;
  logic [ `CACHE_TYPE_BITS-1:0] c_type;
  logic                         c_write;
  logic [`CACHE_WRITE_BITS-1:0] da_write;
  logic [`DATA_BITS       -1:0] read_data;
  // Other
  logic [1:0] blk_off, byte_off;
  logic [2:0] cnt;
  logic hit;
  logic rvalid;

  logic cacheable;  // 0x1000_0000 ~ 0x1000_03ff and 0x4000_0000 ~ 0x4000_ffff -> uncacheable

  // {{{ Sample
  assign cacheable = (core_addr[31:16] > 16'h0fff) && (core_addr[31:16] > 16'h3fff);
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      c_addr  <= `DATA_BITS'h0;
      c_in    <= `DATA_BITS'h0;
      c_type  <= `CACHE_TYPE_BITS'h0;
      c_write <= 1'b0;
    end else if (STATE == INIT) begin
      c_addr  <= core_addr;
      c_in    <= core_in;
      c_type  <= core_type;
      c_write <= core_write;
    end
  end
  // }}}
  // {{{ counter
  logic rmiss_flag;
  assign rmiss_flag = cnt[2];
  always_ff @(posedge clk or posedge rst) begin
    if (rst) rvalid <= 1'b0;
    else if (STATE == RMISS) rvalid <= ~D_wait;
    else rvalid <= 1'b0;
  end
  always_ff @(posedge clk or posedge rst) begin
    if (rst) cnt <= 3'h0;
    else begin
      case (STATE)
        // RMISS   : cnt <= rmiss_flag  ? 3'h0 : cnt + {2'h0, ~D_wait};
        RMISS:   cnt <= rmiss_flag ? 3'h0 : cnt + {2'h0, rvalid};
        default: cnt <= ~D_wait ? 3'h0 : cnt + {2'h0, ~D_wait};
      endcase
    end
  end

  // }}}
  // {{{ STATE
  always_ff @(posedge clk or posedge rst) begin
    STATE <= rst ? INIT : NEXT;
  end
  always_comb begin
    case (STATE)
      INIT: begin
        casez ({
          core_req, core_write, valid[index], ~cacheable
        })
          4'b110?: NEXT = WMISS;
          4'b1000: NEXT = RMISS;
          4'b0???: NEXT = INIT;
          default: NEXT = CHK;  // valid
        endcase
      end
      CHK: begin
        casez ({
          c_write, hit, ~cacheable
        })
          3'b11?:  NEXT = WHIT;
          3'b10?:  NEXT = WMISS;
          3'b001:  NEXT = NOUSE;
          3'b010:  NEXT = FIN;
          default: NEXT = RMISS;
        endcase
      end
      WHIT:    NEXT = ~D_wait ? FIN : WHIT;
      WMISS:   NEXT = ~D_wait ? FIN : WMISS;
      RMISS:   NEXT = rmiss_flag ? FIN : RMISS;
      NOUSE:   NEXT = ~D_wait ? FIN : NOUSE;
      FIN:     NEXT = INIT;
      default: NEXT = INIT;
    endcase
  end
  // }}}
  // {{{ index, offset, hit, valid
  assign blk_off = c_addr[3:2];
  assign byte_off = c_addr[1:0];
  assign index = (STATE == INIT) ? core_addr[9:4] : c_addr[9:4];
  assign hit   = (STATE == CHK) && (TA_out == c_addr[`DATA_BITS-1:`CACHE_ADDR_BITS]) && valid[index];
  always_ff @(posedge clk or posedge rst) begin
    if (rst) valid <= `CACHE_LINE_BITS'h0;
    else if (STATE == RMISS) valid[index] <= 1'b1;
  end
  // }}}
  // {{{ web
  logic [3:0] web, bweb, hweb;
  always_comb begin
    case (byte_off)
      2'h0: {bweb, hweb} = {4'b1110, 4'b1100};
      2'h1: {bweb, hweb} = {4'b1101, 4'b1100};
      2'h2: {bweb, hweb} = {4'b1011, 4'b0011};
      2'h3: {bweb, hweb} = {4'b0111, 4'b0011};
    endcase
  end
  always_comb begin
    case (c_type[1:0])
      `BYTE:   web = bweb;
      `HWORD:  web = hweb;
      default: web = 4'h0;
    endcase
  end
  // always_comb begin
  //     case (blk_off)
  //         2'h0 : da_write = {12'hfff, web};
  //         2'h1 : da_write = {8'hff, web, 4'hf};
  //         2'h2 : da_write = {4'hf, web, 8'hff};
  //         2'h3 : da_write = {web, 12'hfff};
  //     endcase
  // end
  always_ff @(posedge clk or posedge rst) begin
    if (rst) da_write <= `CACHE_WRITE_BITS'hffff;
    else begin
      case (blk_off)
        2'h0: da_write <= {12'hfff, web};
        2'h1: da_write <= {8'hff, web, 4'hf};
        2'h2: da_write <= {4'hf, web, 8'hff};
        2'h3: da_write <= {web, 12'hfff};
      endcase
    end
  end
  // }}}
  // {{{ tag_array_wrapper
  assign TA_in = (STATE == INIT) ? core_addr[`DATA_BITS-1:`CACHE_ADDR_BITS] : c_addr[`DATA_BITS-1:`CACHE_ADDR_BITS];
  always_comb begin
    case (STATE)
      INIT:    {TA_write, TA_read} = 2'b11;
      CHK:     {TA_write, TA_read} = 2'b11;
      WHIT:    {TA_write, TA_read} = {~|cnt, 1'b0};
      RMISS:   {TA_write, TA_read} = {|cnt, 1'b0};
      default: {TA_write, TA_read} = 2'b10;  // WHIT, WMISS, FIN
    endcase
  end
  // }}}
  // {{{ data_array_wrapper
  // DA_read, DA_write, DA_in
  logic [`DATA_BITS-1:0] d_out_r;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) d_out_r <= `DATA_BITS'h0;
    else if (~D_wait) d_out_r <= D_out;
  end

  assign DA_read = (STATE == CHK) ? hit & ~c_write : 1'b0;  // read hit
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      DA_write <= `CACHE_WRITE_BITS'hffff;
      DA_in    <= `CACHE_DATA_BITS'h0;
    end else begin
      case (STATE)
        WHIT: begin
          DA_write <= ~D_wait ? da_write : `CACHE_WRITE_BITS'hffff;
          DA_in    <= ~|cnt ? {c_in, c_in, c_in, c_in} : DA_in;
        end
        RMISS: begin

          DA_write <= &cnt[1:0] ? `CACHE_WRITE_BITS'h0 : `CACHE_WRITE_BITS'hffff;
          // DA_in[{cnt[1:0], 5'h0}+:32] <= D_out;
          case (cnt[1:0])
            2'h3: DA_in[127:96] <= d_out_r;
            2'h2: DA_in[95:64] <= d_out_r;
            2'h1: DA_in[63:32] <= d_out_r;
            2'h0: DA_in[31:0] <= d_out_r;
          endcase
        end
        default: begin
          DA_write <= `CACHE_WRITE_BITS'hffff;
          DA_in    <= `CACHE_DATA_BITS'h0;
        end
      endcase
    end
  end
  // read hit, miss
  always_comb begin
    case (STATE)
      CHK:     read_data = DA_out[{c_addr[3:2], 5'b0}+:32];
      RMISS:   read_data = DA_in[{c_addr[3:2], 5'b0}+:32];
      default: read_data = `DATA_BITS'h0;
    endcase
  end
  // }}}

  // {{{ CPU
  assign core_wait = (STATE == INIT) ? core_req : (STATE == FIN) ? 1'b0 : 1'b1;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) core_out <= `DATA_BITS'h0;
    else begin
      case (STATE)
        CHK:   core_out <= read_data;  // RHIT
        RMISS: core_out <= rmiss_flag ? read_data : core_out;
        NOUSE: core_out <= D_out;
      endcase
    end
  end
  // }}}
  // {{{ CPU_wrapper
  assign arlenone_o = ~cacheable;
  assign D_addr = (STATE == RMISS) ? {c_addr[`DATA_BITS-1:4], 4'h0} : c_addr;
  assign D_type = c_write ? c_type : `CACHE_WORD;
  assign D_in = c_in;  //c_write ? c_in   : `DATA_BITS'h0;
  assign D_write = c_write;

  always_comb begin
    {D_wreq, D_rreq} = 2'b0;
    case (STATE)
      CHK:   D_rreq = ~c_write && ~hit && ~cacheable;
      WMISS: D_wreq = ~|cnt;
      WHIT:  D_wreq = ~|cnt;
      RMISS: D_rreq = cnt < 3'h3;
    endcase
  end
  // }}}

  // {{{
  data_array_wrapper DA (
      .A  (index),
      .DO (DA_out),
      .DI (DA_in),
      .CK (clk),
      .WEB(DA_write),
      .OE (DA_read),
      .CS (1'b1)
  );

  tag_array_wrapper TA (
      .A  (index),
      .DO (TA_out),
      .DI (TA_in),
      .CK (clk),
      .WEB(TA_write),
      .OE (TA_read),
      .CS (1'b1)
  );
  // }}}

  /*
// {{{ PA
    logic [`DATA_BITS-1:0] L1CD_rhits, L1CD_whits;
    logic [`DATA_BITS-1:0] L1CD_rmiss, L1CD_wmiss;
    logic [`DATA_BITS-1:0] L1CD_hits, L1CD_miss;
    assign L1CD_hits = L1CD_rhits + L1CD_whits;
    assign L1CD_miss = L1CD_rmiss + L1CD_wmiss;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            L1CD_rhits <= `DATA_BITS'h0;
            L1CD_whits <= `DATA_BITS'h0;
            L1CD_rmiss <= `DATA_BITS'h0;
            L1CD_wmiss <= `DATA_BITS'h0;
        end
        else begin
            L1CD_rhits <= (STATE == CHK) & hit & ~core_write ? L1CD_rhits + 'h1 : L1CD_rhits;
            L1CD_whits <= (STATE == WHIT)  & ~D_wait ? L1CD_whits + 'h1 : L1CD_whits;
            L1CD_rmiss <= (STATE == RMISS) & rmiss_flag ? L1CD_rmiss + 'h1 : L1CD_rmiss;
            L1CD_wmiss <= (STATE == WMISS) & ~D_wait ? L1CD_wmiss + 'h1 : L1CD_wmiss;
        end
    end
// }}}
*/
endmodule

