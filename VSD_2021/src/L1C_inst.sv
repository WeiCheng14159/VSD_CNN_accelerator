//================================================
// Auther:      CHIEH-SHIH WANG
// Filename:    L1C_inst.sv
// Description: L1 Cache for instruction
// Version:     1.0
//================================================
`include "../include/def.svh"
`include "./tag_array_wrapper.sv"
`include "./data_array_wrapper.sv"

module L1C_inst (
    input                                      clk,
    rst,
    // Core to CPU wrapper
    input        [`DATA_BITS             -1:0] core_addr,
    input                                      core_req,
    input                                      core_write,
    input        [`DATA_BITS             -1:0] core_in,
    input        [`CACHE_TYPE_BITS       -1:0] core_type,
    // Mem to CPU wrapper
    input        [`DATA_BITS             -1:0] I_out,
    input                                      I_wait,
    // CPU wrapper to core
    output logic [       `DATA_BITS      -1:0] core_out,
    output logic                               core_wait,
    // CPU wrapper to Mem
    output logic                               I_rreq,
    I_wreq,
    output logic [       `DATA_BITS      -1:0] I_addr,
    output                                     I_write,
    output logic [       `DATA_BITS      -1:0] I_in,
    output logic [       `CACHE_TYPE_BITS-1:0] I_type
);

  logic [`CACHE_IDX_BITS -1:0] index;
  logic [`CACHE_DATA_BITS-1:0] DA_out;
  logic [`CACHE_DATA_BITS-1:0] DA_in;
  logic [`CACHE_WRITE_BITS-1:0] DA_write;
  logic DA_read;
  logic [`CACHE_TAG_BITS-1:0] TA_out;
  logic [`CACHE_TAG_BITS-1:0] TA_in;
  logic TA_write;
  logic TA_read;
  logic [`CACHE_LINE_BITS-1:0] valid;

  //--------------- complete this part by yourself -----------------//
  parameter INIT = 2'h0, CHK = 2'h1, RMISS = 2'h2, FIN = 2'h3;
  logic [1:0] STATE, NEXT;
  // Sample
  logic [`ADDR_BITS-1:0] c_addr;
  // Read
  logic [`DATA_BITS-1:0] read_data;
  // Other
  logic [2:0] cnt;
  logic hit;
  logic flag;

  // {{{ Sample
  always @(posedge clk or posedge rst) begin
    c_addr <= rst ? `ADDR_BITS'h0 : (STATE == INIT) ? core_addr : c_addr;
  end
  // }}}
  // {{{ counter, flag
  assign flag = cnt[2];
  always_ff @(posedge clk or posedge rst) begin
    if (rst) cnt <= 3'h0;
    else if (STATE == RMISS)
      cnt <= flag ? 3'h0 : (~I_wait ? (cnt + 3'h1) : cnt);
  end
  // }}}
  // {{{ STATE
  always_ff @(posedge clk or posedge rst) begin
    STATE <= rst ? INIT : NEXT;
  end
  always_comb begin
    case (STATE)
      INIT: begin
        case ({
          core_req, valid[index]
        })
          2'b11:   NEXT = CHK;
          2'b10:   NEXT = RMISS;
          default: NEXT = INIT;  // valid
        endcase
      end
      CHK:     NEXT = hit ? FIN : RMISS;
      RMISS:   NEXT = flag ? FIN : RMISS;
      default: NEXT = INIT;  // FIN
    endcase
  end
  // }}}

  // {{{ index, offset, hit, valid
  assign index = (STATE == INIT) ? core_addr[9:4] : c_addr[9:4];
  assign hit   = (STATE == CHK) && (TA_out == c_addr[`DATA_BITS-1:`CACHE_ADDR_BITS]) && valid[index];
  always_ff @(posedge clk or posedge rst) begin
    if (rst) valid <= `CACHE_LINE_BITS'h0;
    else if (STATE == RMISS) valid[index] <= 1'b1;
  end
  // }}}
  // {{{ tag_array_wrapper
  assign TA_in   = (STATE == INIT) ? core_addr[`DATA_BITS-1:`CACHE_ADDR_BITS] : c_addr[`DATA_BITS-1:`CACHE_ADDR_BITS];
  assign TA_read = (STATE == INIT) || (STATE == CHK);
  always_ff @(posedge clk or posedge rst) begin
    TA_write <= rst ? 1'b1 : ~cnt[1];
  end
  // }}}
  // {{{ data_array_wrapper (DA_read, DA_write, DA_in)
  assign DA_read = (STATE == CHK) && hit;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      DA_write <= `CACHE_WRITE_BITS'hffff;
      DA_in    <= `CACHE_DATA_BITS'h0;
    end else if (STATE == RMISS) begin
      DA_write <= &cnt[1:0] ? `CACHE_WRITE_BITS'h0 : `CACHE_WRITE_BITS'hffff;
      DA_in[127:96] <= I_out;
      DA_in[95:64] <= DA_in[127:96];
      DA_in[63:32] <= DA_in[95:64];
      DA_in[31:0] <= DA_in[63:32];
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
  always_comb begin
    case (STATE)
      INIT:    core_wait = core_req;
      FIN:     core_wait = 1'b0;
      default: core_wait = 1'b1;
    endcase
  end
  always_ff @(posedge clk or posedge rst) begin
    if (rst) core_out <= `DATA_BITS'h0;
    else if (STATE == CHK) core_out <= read_data;
    else if (STATE == RMISS) core_out <= flag ? read_data : core_out;
  end
  // }}}
  // {{{ CPU_wrapper
  assign I_rreq  = (STATE == RMISS) && ~flag;
  assign I_wreq  = 1'b0;
  assign I_write = 1'b0;
  assign I_in    = `DATA_BITS'h0;
  assign I_type  = `CACHE_WORD;
  assign I_addr  = {c_addr[`DATA_BITS-1:4], 4'h0};
  // }}}

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

  /*
// {{{
    logic [`DATA_BITS-1:0] L1CI_rhits;
    logic [`DATA_BITS-1:0] L1CI_rmiss;
    logic [`DATA_BITS-1:0] insts;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            L1CI_rhits <= `DATA_BITS'h0;
            L1CI_rmiss <= `DATA_BITS'h0;
            insts      <= `DATA_BITS'h0;
        end
        else begin
            L1CI_rhits <= (STATE == CHK) & hit ? L1CI_rhits + 'h1 : L1CI_rhits;
            L1CI_rmiss <= (STATE == RMISS) & flag ? L1CI_rmiss + 'h1 : L1CI_rmiss;
            insts      <= (STATE == INIT) & core_req ? insts + 'h1 : insts;
        end
    end
// }}}
*/
endmodule

