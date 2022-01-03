`include "../../include/CPU_def.svh"

module CSR (
    input                         clk, rst,
    inf_EX_CSR.CSR2EX             csr2ex,
    input                         idexe_en_i,
    input                         int_taken_i,
    output logic [`ADDR_BITS-1:0] csr_pc_o, csr_retpc_o,
    output logic                  int_o, mret_o,
    output logic                  csr_stall_o
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

    always_comb begin
        case (csr2ex.csr_addr)
            `MSTATUS   : csr2ex.rd_wdata = mstatus_r;   
            `MIE       : csr2ex.rd_wdata = mie_r;
            `MTVEC     : csr2ex.rd_wdata = mtvec_r; 
            `MEPC      : csr2ex.rd_wdata = mepc_r;
            `MIP       : csr2ex.rd_wdata = mip_r;
            `MCYCLE    : csr2ex.rd_wdata = mcycle_r;
            `MINSTRET  : csr2ex.rd_wdata = minstret_r;
            `MCYCLEH   : csr2ex.rd_wdata = mcycleh_r;
            `MINSTRETH : csr2ex.rd_wdata = minstreth_r;
            default    : csr2ex.rd_wdata = `DATA_BITS'h0;
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
    assign csr_pc_o    = mtvec_r;
    assign csr_retpc_o = mepc_r;

    logic stall;
    logic mie, meip, meie;
    assign stall  = csr2ex.wfi & mie_r[11];
    assign mie    = mstatus_r[3];
    assign meip   = mip_r[11];
    assign meie   = mie_r[11];
    assign int_o  = int_taken_i & mie & meip & meie;
    assign mret_o = csr2ex.mret;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mstatus_r <= `DATA_BITS'h0;
            mie_r     <= `DATA_BITS'h0;
            mtvec_r   <= `DATA_BITS'h1_0000;
            mepc_r    <= `DATA_BITS'h0;
            mip_r     <= `DATA_BITS'h0;
        end
        else if (~idexe_en_i) begin
            mstatus_r <= mstatus_r;
            mie_r     <= mie_r;
            mtvec_r   <= mtvec_r;
            mepc_r    <= mepc_r;
            mip_r     <= mip_r;		
        end
        else if (csr2ex.wfi) begin
            mepc_r    <= csr2ex.pc + `ADDR_BITS'h4;
            mip_r[11] <= mie_r[11] | mip_r[11];
        end
        else if (int_taken_i) begin
            mstatus_r[12:11] <= mip_r[11] ? 2'b11 : mstatus_r[12:11];
            mstatus_r[7]     <= mip_r[11] ? mstatus_r[3] : mstatus_r[7];
            mstatus_r[3]     <= mip_r[11] ? 1'b0 : mstatus_r[3];
            mip_r[11]        <= 1'b0;
        end
        else if (csr2ex.mret) begin
            mstatus_r[3]     <= mstatus_r[7];
            mstatus_r[7]     <= 1'b1;
            mstatus_r[12:11] <= 2'b11;
        end
        else begin
            case (csr2ex.csr_addr)
                `MSTATUS : {mstatus_r[12:11], mstatus_r[7], mstatus_r[3]} <= {csr_data[12:11], csr_data[7], csr_data[3]};
                `MIE     : mie_r[11] <= csr_data[11];
                `MEPC    : mepc_r[31:2] <= csr_data[31:2];
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
        if (rst)             csr_stall_o <= 1'b0;
        else if (int_o)      csr_stall_o <= 1'b0; 
        else if (idexe_en_i) csr_stall_o <= stall | csr_stall_o;
    end

endmodule
