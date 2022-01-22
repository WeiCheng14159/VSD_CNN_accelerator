`include "../../include/CPU_def.svh"

module CSR (
    input                           clk, rst,
    inf_EX_CSR.CSR2EX               csr2ex,
    input                           csr_en_i,
    input                           int_taken_i,
    input        [`INT_ID_BITS-1:0] int_id_i,
    output logic [`ADDR_BITS  -1:0] csr_pc_o, csr_retpc_o,
    output logic                    wfi_o, mret_o, int_o,
    output logic                    stall_o
);

    logic [`DATA_BITS-1:0] mstatus_r;
    logic [`DATA_BITS-1:0] mie_r;
    logic [`DATA_BITS-1:0] mtvec_r;
    logic [`DATA_BITS-1:0] mepc_r;
    logic [`DATA_BITS-1:0] mip_r;
    logic [`DATA_BITS-1:0] mcycle_r;
    logic [`DATA_BITS-1:0] minstret_r;
    logic [`DATA_BITS-1:0] mcycleh_r;
    logic [`DATA_BITS-1:0] minstreth_r;
    logic [`DATA_BITS-1:0] csr_data;
    logic csr_en;

    always_comb begin
        case (csr2ex.csr_addr)
            `MSTATUS_ADDR   : csr2ex.rd_wdata = mstatus_r;   
            `MIE_ADDR       : csr2ex.rd_wdata = mie_r;
            `MTVEC_ADDR     : csr2ex.rd_wdata = mtvec_r; 
            `MEPC_ADDR      : csr2ex.rd_wdata = mepc_r;
            `MIP_ADDR       : csr2ex.rd_wdata = mip_r;
            `MCYCLE_ADDR    : csr2ex.rd_wdata = mcycle_r;
            `MINSTRET_ADDR  : csr2ex.rd_wdata = minstret_r;
            `MCYCLEH_ADDR   : csr2ex.rd_wdata = mcycleh_r;
            `MINSTRETH_ADDR : csr2ex.rd_wdata = minstreth_r;
            default         : csr2ex.rd_wdata = `DATA_BITS'h0;
        endcase
    end
    logic rs1neq0;
    assign rs1neq0 = |csr2ex.rs1_rdata;
    always_comb begin
        case ({csr2ex.wr, csr2ex.set, csr2ex.clr})
            3'b100  : csr_data = csr2ex.rs1_rdata; 
            3'b010  : csr_data = rs1neq0 ? (csr2ex.rs1_rdata | csr2ex.rd_wdata)  : csr2ex.rd_wdata;
            3'b001  : csr_data = rs1neq0 ? (~csr2ex.rs1_rdata & csr2ex.rd_wdata) : csr2ex.rd_wdata;
            default : csr_data = `DATA_BITS'h0;
        endcase
    end


    // pc
    // assign csr_pc_o    = {mtvec_r[`DATA_BITS-1:2], 2'h0};
    always_comb begin
        case (int_id_i)
            `INT_DMA   : csr_pc_o = `ADDR_BITS'h1_000;
            `INT_EPU   : csr_pc_o = `ADDR_BITS'h1_000;
            `INT_SCTRL : csr_pc_o = {mtvec_r[`DATA_BITS-1:2], 2'h0};
            default    : csr_pc_o = `ADDR_BITS'h1_000;
        endcase
    end
    assign csr_retpc_o = mepc_r;


    logic mie, meip, meie;
    assign wfi_o  = csr2ex.wfi & mie_r[`MEIE];
    assign mie    = mstatus_r[`MIE];
    assign meip   = mip_r[`MEIP];
    assign meie   = mie_r[`MEIE];
    assign int_o  = int_taken_i && mie && meip && meie;
    assign mret_o = csr2ex.mret;
    assign csr_en = csr_en_i & ~stall_o;



    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mstatus_r <= `DATA_BITS'h0;
            mie_r     <= `DATA_BITS'h0;
            mtvec_r   <= `DATA_BITS'h1_0000;
            // mtvec_r   <= `DATA_BITS'h1000;
            mepc_r    <= `DATA_BITS'h0;
            mip_r     <= `DATA_BITS'h0;
        end
        // else if (~csr_en_i) begin
        //     mstatus_r <= mstatus_r;
        //     mie_r     <= mie_r;
        //     mtvec_r   <= mtvec_r;
        //     mepc_r    <= mepc_r;
        //     mip_r     <= mip_r;		
        // end
        else if (csr_en && csr2ex.wfi) begin
            mepc_r       <= csr2ex.pc + `ADDR_BITS'h4;
            mip_r[`MEIP] <= mie_r[`MEIE] | mip_r[`MEIP];
        end
        else if (csr_en && int_o) begin
            mstatus_r[`MPP]  <= mip_r[`MEIP] ? 2'b11 : mstatus_r[`MPP];
            mstatus_r[`MPIE] <= mip_r[`MEIP] ? mstatus_r[`MIE] : mstatus_r[`MPIE];
            mstatus_r[`MIE]  <= mip_r[`MEIP] ? 1'b0 : mstatus_r[`MIE];
            mip_r[`MEIP]     <= 1'b0;
        end
        else if (csr_en && csr2ex.mret) begin
            mstatus_r[`MIE]  <= mstatus_r[`MPIE];
            mstatus_r[`MPIE] <= 1'b1;
            mstatus_r[`MPP]  <= 2'b11;
        end
        else if (csr_en) begin
            case (csr2ex.csr_addr)
                `MSTATUS_ADDR : {mstatus_r[`MPP], mstatus_r[`MPIE], mstatus_r[`MIE]} <= {csr_data[`MPP], csr_data[`MPIE], csr_data[`MIE]};
                `MIE_ADDR     : mie_r[`MEIE] <= csr_data[`MEIE];
                `MEPC_ADDR    : mepc_r[31:2] <= csr_data[31:2];
            endcase
        end
            
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            {mcycleh_r, mcycle_r}     <= 64'h0;
            {minstreth_r, minstret_r} <= 64'h0;
        end
        else begin
            {mcycleh_r, mcycle_r}     <= {mcycleh_r, mcycle_r} + 64'h1;
            {minstreth_r, minstret_r} <= {minstreth_r, minstret_r} + 64'h1;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)           stall_o <= 1'b0;
        else if (int_o)    stall_o <= 1'b0; 
        else if (csr_en_i) stall_o <= wfi_o | stall_o;
    end

endmodule
