//================================================
// Auther:      CHIEH-SHIH WANG
// Filename:    L1C_inst.sv
// Description: L1 Cache for instruction
// Version:     1.0
//================================================
`include "../include/def.svh"
`include "./tag_array_wrapper.sv"
`include "./data_array_wrapper.sv"

module L1C_inst(
    input clk,
    input rst,
    // Core to CPU wrapper
    input [`DATA_BITS-1:0] core_addr,
    input core_req,
    input core_write,
    input [`DATA_BITS-1:0] core_in,
    input [`CACHE_TYPE_BITS-1:0] core_type,
    // Mem to CPU wrapper
    input [`DATA_BITS-1:0] I_out,
    input I_wait,
    // CPU wrapper to core
    output logic [`DATA_BITS-1:0] core_out,
    output core_wait,
    // CPU wrapper to Mem
    output logic I_req,
    output logic [`DATA_BITS-1:0] I_addr,
    output I_write,
    output [`DATA_BITS-1:0] I_in,
    output [`CACHE_TYPE_BITS-1:0] I_type
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
  
    // STATE
    parameter INIT  = 3'h0,
                CHK   = 3'h1,
                RMISS = 3'h4,
                FIN   = 3'h5;
    logic [2:0] STATE, NEXT;
    // Sample
    logic [`DATA_BITS      -1:0] c_addr, c_in;
    logic [`CACHE_TYPE_BITS-1:0] c_type;
    logic [`CACHE_DATA_BITS-1:0] da_in;
    logic [`DATA_BITS      -1:0] read_data;
    logic [`CACHE_DATA_BITS-1:0] r_data;
    // Other
    logic [2:0] cnt;
    logic hit;
    logic flag;

// {{{ Sample
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_addr  <= `DATA_BITS'h0;
            c_in    <= `DATA_BITS'h0;
            c_type  <= `CACHE_TYPE_BITS'h0;
        end
        else if (STATE == INIT) begin
            c_addr  <= core_addr;
            c_in    <= core_in;
            c_type  <= core_type;
        end
    end
// }}}
// {{{ counter, flag
    assign flag = cnt[2];
    always_ff @(posedge clk or posedge rst) begin
        if (rst)                 cnt <= 3'h0;
        else if (STATE == RMISS) cnt <= flag ? 3'h0 : (~I_wait ? (cnt + 3'h1) : cnt);
        else                     cnt <= 3'h0;
    end

// }}}
// {{{ STATE
    always_ff @(posedge clk or posedge rst) begin
        STATE <= rst ? INIT : NEXT;
    end
    always_comb begin
        case (STATE)
            INIT    : begin
                casez ({core_req, core_write, valid[index]})
                    3'b0??  : NEXT = INIT;
                    3'b100  : NEXT = RMISS;
                    default : NEXT = CHK;   // valid
                endcase
            end
            CHK     : NEXT = hit ? FIN : RMISS;
            RMISS   : NEXT = flag ? FIN : RMISS;
            FIN     : NEXT = INIT;
            default : NEXT = INIT;
        endcase
    end
// }}}

// {{{ index, offset, hit, valid
    assign index = (STATE == INIT) ? core_addr[9:4] : c_addr[9:4];
    always_ff @(posedge clk or posedge rst) begin
        if (rst)                 valid <= `CACHE_LINE_BITS'h0;
        else if (STATE == RMISS) valid[index] <= 1'b1;
    end
    always_comb begin
        case (STATE)
            INIT    : hit = valid[core_addr[`CACHE_ADDR_BITS-1:4]] & (TA_out == core_addr[31:10]);
            CHK     : hit = TA_out == c_addr[31:10];
            default : hit = 1'b0; // WMISS, RMISS, FIN
        endcase
    end
// }}}
// {{{ tag_array_wrapper
    assign TA_in = STATE == INIT ? core_addr[`DATA_BITS-1:`CACHE_ADDR_BITS] : c_addr[`DATA_BITS-1:`CACHE_ADDR_BITS];
    always_comb begin
        case (STATE)
            INIT    : {TA_write, TA_read} = 2'b11;
            CHK     : {TA_write, TA_read} = 2'b11;
            RMISS   : {TA_write, TA_read} = {|cnt, 1'b0}; 
            default : {TA_write, TA_read} = 2'b10;  // WHIT, WMISS, FIN
        endcase
    end
// }}}
// {{{ data_array_wrapper (DA_read, DA_write, DA_in)
    assign DA_read = (STATE == CHK) & hit;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            DA_write <= `CACHE_WRITE_BITS'hffff;
            DA_in    <= `CACHE_DATA_BITS'h0;
        end
        else if (STATE == RMISS) begin
            DA_write <= &cnt[1:0] ? `CACHE_WRITE_BITS'h0 : `CACHE_WRITE_BITS'hffff;
            DA_in[{cnt[1:0], 5'h0}+:32] <= I_out;
        end
        else begin
            DA_write <= `CACHE_WRITE_BITS'hffff;
            DA_in    <= `CACHE_DATA_BITS'h0;
        end
    end
    // read hit, miss
    assign r_data = (STATE == RMISS) & flag ? DA_in : DA_out;
    assign read_data = r_data[{core_addr[3:2], 5'b0}+:32];
// }}}

// {{{ CPU
    assign core_wait = (STATE == INIT) ? core_req : (STATE == FIN) ? 1'b0 : 1'b1;
    always_ff @(posedge clk or posedge rst) begin
        if (rst)                 core_out <= `DATA_BITS'h0;
        else if (STATE == CHK)   core_out <= read_data;
        else if (STATE == RMISS) core_out <= flag ? read_data : core_out;
    end
// }}}
// {{{ CPU_wrapper
    assign I_req   = (STATE == RMISS) & ~flag;
    assign I_write = 1'b0;
    assign I_in    = `DATA_BITS'h0;
    assign I_type  = `CACHE_WORD;
    assign I_addr  = {c_addr[`DATA_BITS-1:4], 4'h0};
// }}}

    data_array_wrapper DA(
        .A(index),
        .DO(DA_out),
        .DI(DA_in),
        .CK(clk),
        .WEB(DA_write),
        .OE(DA_read),
        .CS(1'b1)
    );

    tag_array_wrapper  TA(
        .A(index),
        .DO(TA_out),
        .DI(TA_in),
        .CK(clk),
        .WEB(TA_write),
        .OE(TA_read),
        .CS(1'b1)
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

