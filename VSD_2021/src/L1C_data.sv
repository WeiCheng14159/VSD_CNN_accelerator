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
    input                               clk,
    input                               rst,
    // Core to CPU wrapper
    input        [`DATA_BITS      -1:0] core_addr,
    input                               core_req,
    input                               core_write,
    input        [`DATA_BITS      -1:0] core_in,
    input        [`CACHE_TYPE_BITS-1:0] core_type,
    // Mem to CPU wrapper
    input        [      `DATA_BITS-1:0] D_out,
    input                               D_wait,
    // CPU wrapper to core
    output logic [      `DATA_BITS-1:0] core_out,
    output logic                        core_wait,
    // CPU wrapper to Mem
    output logic                        D_req,
    output logic [`DATA_BITS      -1:0] D_addr,
    output logic                        D_write,
    output logic [`DATA_BITS      -1:0] D_in,
    output logic [`CACHE_TYPE_BITS-1:0] D_type,
    // 
    output logic                        sctrl_rd_o
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
			  WHIT  = 3'h2,
			  WMISS = 3'h3,
			  RMISS = 3'h4,
			  NOUSE = 3'h5,
			  FIN   = 3'h6;
  logic [2:0] STATE, NEXT;
  // Sample
  logic [ `ADDR_BITS      -1:0] c_addr;
  logic [ `DATA_BITS      -1:0] c_in;
  logic [ `CACHE_TYPE_BITS-1:0] c_type;
  logic                         c_write;
  logic [`CACHE_DATA_BITS -1:0] da_in;
  logic [`CACHE_WRITE_BITS-1:0] da_write;
  logic [ `DATA_BITS      -1:0] read_data;
  logic [ `CACHE_DATA_BITS-1:0] r_data;
  // Other
  logic [1:0] blk_off, byte_off;
  logic [2:0] cnt;
  logic hit;
  logic flag;
  logic cacheable;  // 0x1000_0000 ~ 0x1000_03ff -> uncacheable

  // {{{ Sample
  //assign c_addr = core_addr;
  // assign cacheable = c_addr[31:16] != 16'h1000;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      c_addr    <= `DATA_BITS'h0;
      c_in      <= `DATA_BITS'h0;
      c_type    <= `CACHE_TYPE_BITS'h0;
      c_write   <= 1'b0;
      cacheable <= 1'b0;
    end else if (STATE == INIT) begin
      c_addr    <= core_addr;
      c_in      <= core_in;
      c_type    <= core_type;
      c_write   <= core_write;
      cacheable <= core_addr[31:16] != 16'h1000;
    end
  end
  // }}}
  // {{{ counter, flag, cacheable

  always_ff @(posedge clk or posedge rst) begin
    if (rst) cnt <= 3'h0;
    else if (flag) cnt <= 3'h0;
    else if (~D_wait) cnt <= cnt + 3'h1;
    else cnt <= cnt;
  end
  always_comb begin
    case (STATE)
      WMISS:   flag = ~D_wait;
      WHIT:    flag = ~D_wait;
      RMISS:   flag = cnt[2];
      NOUSE:   flag = ~D_wait;
      default: flag = 1'b1;
    endcase
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
          core_req, core_write, valid[index]
        })
          3'b0??:  NEXT = INIT;
          3'b110:  NEXT = WMISS;
          3'b100:  NEXT = RMISS;
          default: NEXT = CHK;  // valid
        endcase
      end
      // CHK     : NEXT = c_write & hit ? WHIT : (c_write ? WMISS : (~cacheable ? NOUSE : (hit ? FIN : RMISS)));
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
      WHIT:    NEXT = flag ? FIN : WHIT;
      WMISS:   NEXT = flag ? FIN : WMISS;
      RMISS:   NEXT = flag ? FIN : RMISS;
      NOUSE:   NEXT = flag ? FIN : NOUSE;
      FIN:     NEXT = INIT;
      default: NEXT = INIT;
    endcase
  end
  // }}}
  // {{{ index, offset, hit, valid
  assign blk_off = c_addr[3:2];
  assign byte_off = c_addr[1:0];
  assign index = (STATE == INIT) ? core_addr[9:4] : c_addr[9:4];
  always_ff @(posedge clk or posedge rst) begin
    if (rst) valid <= `CACHE_LINE_BITS'h0;
    else if (STATE == RMISS) valid[index] <= 1'b1;
  end
  always_comb begin
    case (STATE)
      INIT:
      hit = valid[core_addr[`CACHE_ADDR_BITS-1:4]] & (TA_out == core_addr[31:10]);
      CHK: hit = TA_out == c_addr[31:10];
      WHIT: hit = 1'b1;
      default: hit = 1'b0;  // WMISS, RMISS, FIN
    endcase
  end
  // web
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
  always_comb begin
    case (blk_off)
      2'h0: da_write = {12'hfff, web};
      2'h1: da_write = {8'hff, web, 4'hf};
      2'h2: da_write = {4'hf, web, 8'hff};
      2'h3: da_write = {web, 12'hfff};
    endcase
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
  assign DA_read = (STATE == CHK) ? hit & ~c_write : 1'b0;  // read hit
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      DA_write <= `CACHE_WRITE_BITS'hffff;
      DA_in    <= `CACHE_DATA_BITS'h0;
    end else begin
      case (STATE)
        WHIT: begin
          DA_write <= flag ? da_write : `CACHE_WRITE_BITS'hffff;
          DA_in    <= ~|cnt ? {c_in, c_in, c_in, c_in} : DA_in;
        end
        RMISS: begin
          DA_write <= &cnt[1:0] ?  `CACHE_WRITE_BITS'h0 : `CACHE_WRITE_BITS'hffff;
          DA_in[{cnt[1:0], 5'h0}+:32] <= D_out;
        end
        default: begin
          DA_write <= `CACHE_WRITE_BITS'hffff;
          DA_in    <= `CACHE_DATA_BITS'h0;
        end
      endcase
    end
  end
  // read hit, miss
  assign r_data = (STATE == RMISS) & flag ? DA_in : DA_out;
  assign read_data = r_data[{core_addr[3:2], 5'b0}+:32];
  // }}}

  // {{{ CPU
  assign core_wait = (STATE == INIT) ? core_req : (STATE == FIN) ? 1'b0 : 1'b1;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) core_out <= `DATA_BITS'h0;
    else if (STATE == CHK) core_out <= read_data;
    else if (STATE == RMISS) core_out <= flag ? read_data : core_out;
    else if (STATE == NOUSE) core_out <= D_out;
  end
  // }}}
  // {{{ CPU_wrapper
  // assign sctrl_rd_o = (STATE == NOUSE) & ~cacheable;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // D_req      <= 1'b0;
      sctrl_rd_o <= 1'b0;
    end else if (STATE == CHK) begin
      // D_req      <= cacheable & c_write & hit
      sctrl_rd_o <= ~c_write & ~hit & ~cacheable;
    end
  end
  always_comb begin
    case (STATE)
      WMISS: begin
        D_req   = ~|cnt;
        D_write = 1'b1;
        D_addr  = c_addr;
        D_in    = c_in;
        D_type  = c_type;
      end
      WHIT: begin
        D_req   = ~|cnt;
        D_write = 1'b1;
        D_addr  = c_addr;
        D_in    = c_in;
        D_type  = c_type;
      end
      RMISS: begin
        D_req   = ~flag;
        D_write = 1'b0;
        D_addr  = {c_addr[31:4], 4'h0};
        D_in    = `DATA_BITS'h0;
        D_type  = `CACHE_WORD;
      end
      NOUSE: begin
        D_req   = 1'b0;
        D_write = 1'b0;
        D_addr  = c_addr;
        D_in    = `DATA_BITS'h0;
        D_type  = `CACHE_WORD;
      end
      default: begin
        D_req   = 1'b0;
        D_write = 1'b0;
        D_addr  = `ADDR_BITS'h0;
        D_in    = `DATA_BITS'h0;
        D_type  = c_type;
      end
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
    end else begin
      L1CD_rhits <= (STATE == CHK) & hit & ~core_write ? L1CD_rhits + 'h1 : L1CD_rhits;
      L1CD_whits <= (STATE == WHIT) & flag ? L1CD_whits + 'h1 : L1CD_whits;
      L1CD_rmiss <= (STATE == RMISS) & flag ? L1CD_rmiss + 'h1 : L1CD_rmiss;
      L1CD_wmiss <= (STATE == WMISS) & flag ? L1CD_wmiss + 'h1 : L1CD_wmiss;
    end
  end
  // }}}
endmodule

