`include "../../include/CPU_def.svh"
`include "../Interface/inf_IF_ID.sv"
`include "../Interface/inf_ID_EX.sv"

module ID_S (
    /* Debug */
    output logic [31:0] debug_pc, debug_inst,

    input                   clk, rst,
    inf_IF_ID.ID2IF         id2if_i, 
    inf_ID_EX.ID2EX         id2ex_o,
    input                   idexe_en_i,
    input                   stall_i, flush_i,     
    input  [`DATA_BITS-1:0] rs1_data_i, rs2_data_i,   
    output [`REG_BITS -1:0] rs1_addr_o, rs2_addr_o
);
    logic [`DATA_BITS  -1:0] inst;
    logic [`OPCODE_BITS-1:0] op;
    logic [`FUNC7_BITS -1:0] func7;
    logic [`FUNC3_BITS -1:0] func3;
    logic [`REG_BITS   -1:0] rs1, rs2, rd;
    // CSR
    logic [`UIMM_BITS  -1:0] uimm;

    assign inst  = id2if_i.inst;
    assign func7 = inst[31:25];
    assign rs2   = inst[24:20];
    assign rs1   = inst[19:15]; 
    assign uimm  = inst[19:15];  // CSR
    assign func3 = inst[14:12];
    assign rd    = inst[11: 7];
    assign op    = inst[ 6: 0];
    assign rs1_addr_o = rs1;
    assign rs2_addr_o = rs2;


    logic [`IMM_BITS   -1:0] imm;
    logic [`ALUOP_BITS -1:0] aluop;
    logic [`BRANCH_BITS-1:0] branch_ctrl;
    logic [`TYPE_BITS  -1:0] datatype;
    logic [`REG_BITS   -1:0] rs1_addr, rs2_addr, rd_addr;
    logic [`DATA_BITS  -1:0] rs1_data, rs2_data;
    logic pc2reg_src, rd_src, alu_src, reg_wr, dm_rd, dm_wr, dm2reg;
    // CSR
    logic [`CSRADDR_BITS-1:0] csr_addr;
    logic csr;
    logic csr_src, csr_reg_wr;
    logic csr_wr, csr_set, csr_clr, csr_mret, csr_wfi;

// {{{ Imm
    always_comb begin
        case(op)
            `ROP       : imm = `IMM_BITS'h0;	
            `IOP_LOAD  : imm = {{20{inst[31]}}, inst[31:20]};
            `IOP_ALU   : imm = {{20{inst[31]}}, inst[31:20]};
            `IOP_JALR  : imm = {{20{inst[31]}}, inst[31:20]};
            `SOP       : imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            `BOP       : imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            `UOP_AUPIC : imm = {inst[31:12], 12'b0};
            `UOP_LUI   : imm = {inst[31:12], 12'b0};
            `JOP_JAL   : imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            `CSROP     : imm = {27'h0, uimm};
            default    : imm = `IMM_BITS'h0;
        endcase
    end
// }}}
// {{{ Aluop
    always_comb begin
        case(op)
            `ROP       : aluop = `R_ALUOP;	
            `IOP_LOAD  : aluop = `ADD_ALUOP;
            `IOP_ALU   : aluop = `I_ALUOP;
            `IOP_JALR  : aluop = `ADD_ALUOP;
            `SOP       : aluop = `ADD_ALUOP;
            `BOP       : aluop = `BEQ_ALUOP;
            `UOP_AUPIC : aluop = `AUIPC_ALUOP;
            `UOP_LUI   : aluop = `LUI_ALUOP;
            `JOP_JAL   : aluop = `NO_ALUOP;
            `CSROP     : aluop = `NO_ALUOP;
            default    : aluop = `NO_ALUOP;
        endcase
    end
// }}}
// {{{ Branch ctrl
    always_comb begin
        case(op)
            `ROP       : branch_ctrl = `BRANCH_NEXT;	
            `IOP_LOAD  : branch_ctrl = `BRANCH_NEXT;
            `IOP_ALU   : branch_ctrl = `BRANCH_NEXT;
            `IOP_JALR  : branch_ctrl = `BRANCH_JALR;
            `SOP       : branch_ctrl = `BRANCH_NEXT;
            `BOP       : branch_ctrl = `BRANCH_BEQ;
            `UOP_AUPIC : branch_ctrl = `BRANCH_NEXT;
            `UOP_LUI   : branch_ctrl = `BRANCH_NEXT;
            `JOP_JAL   : branch_ctrl = `BRANCH_JAL;
            `CSROP     : branch_ctrl = `BRANCH_NEXT;
            default    : branch_ctrl = `BRANCH_NEXT;
        endcase
    end
// }}}
// {{{ Data type
    always @(*) begin
        if (op == `CSROP) 
            datatype = `CPU_WORD;
        else begin
            case (func3)
                3'b000  : datatype = `CPU_BYTE;
                3'b001  : datatype = `CPU_HWORD;
                3'b100  : datatype = `CPU_BYTE_U;
                3'b101  : datatype = `CPU_HWORD_U;
                default : datatype = `CPU_WORD;
            endcase
        end
    end
// }}}
// {{{ Register
    always_comb begin
        case(op)
            `ROP       : {rs1_addr, rs2_addr, rd_addr} = {         rs1,          rs2,           rd};	
            `IOP_LOAD  : {rs1_addr, rs2_addr, rd_addr} = {         rs1, `REG_BITS'h0,           rd};
            `IOP_ALU   : {rs1_addr, rs2_addr, rd_addr} = {         rs1, `REG_BITS'h0,           rd};
            `IOP_JALR  : {rs1_addr, rs2_addr, rd_addr} = {         rs1, `REG_BITS'h0,           rd};
            `SOP       : {rs1_addr, rs2_addr, rd_addr} = {         rs1,          rs2, `REG_BITS'h0};
            `BOP       : {rs1_addr, rs2_addr, rd_addr} = {         rs1,          rs2, `REG_BITS'h0};
            `UOP_AUPIC : {rs1_addr, rs2_addr, rd_addr} = {`REG_BITS'h0, `REG_BITS'h0,           rd};
            `UOP_LUI   : {rs1_addr, rs2_addr, rd_addr} = {`REG_BITS'h0, `REG_BITS'h0,           rd};
            `JOP_JAL   : {rs1_addr, rs2_addr, rd_addr} = {`REG_BITS'h0, `REG_BITS'h0,           rd};
            `CSROP     : {rs1_addr, rs2_addr, rd_addr} = {         rs1, `REG_BITS'h0,           rd};
            default    : {rs1_addr, rs2_addr, rd_addr} = {`REG_BITS'h0, `REG_BITS'h0, `REG_BITS'h0};
        endcase
    end
    always_comb begin
        case(op)
            `ROP       : {rs1_data, rs2_data} = {   rs1_data_i,    rs2_data_i};	
            `IOP_LOAD  : {rs1_data, rs2_data} = {   rs1_data_i, `DATA_BITS'h0};
            `IOP_ALU   : {rs1_data, rs2_data} = {   rs1_data_i, `DATA_BITS'h0};
            `IOP_JALR  : {rs1_data, rs2_data} = {   rs1_data_i, `DATA_BITS'h0};
            `SOP       : {rs1_data, rs2_data} = {   rs1_data_i,    rs2_data_i};
            `BOP       : {rs1_data, rs2_data} = {   rs1_data_i,    rs2_data_i};
            `UOP_AUPIC : {rs1_data, rs2_data} = {`DATA_BITS'h0, `DATA_BITS'h0};
            `UOP_LUI   : {rs1_data, rs2_data} = {`DATA_BITS'h0, `DATA_BITS'h0};
            `JOP_JAL   : {rs1_data, rs2_data} = {`DATA_BITS'h0, `DATA_BITS'h0};
            `CSROP     : {rs1_data, rs2_data} = {   rs1_data_i, `DATA_BITS'h0};
            default    : {rs1_data, rs2_data} = {`DATA_BITS'h0, `DATA_BITS'h0};
        endcase
    end
// }}}
// {{{ Control signal
    logic [6:0] ctrl;
    assign {pc2reg_src, rd_src, alu_src, reg_wr, dm_rd, dm_wr, dm2reg} = ctrl;
    always_comb begin
        case(op)
            `ROP       : ctrl = 7'b0001000;
            `IOP_LOAD  : ctrl = 7'b0011101;
            `IOP_ALU   : ctrl = 7'b0011000;
            `IOP_JALR  : ctrl = {3'b011, |rd, 3'b000};
            `SOP       : ctrl = 7'b0010010;
            `BOP       : ctrl = 7'b0000000;
            `UOP_AUPIC : ctrl = 7'b1101000;
            `UOP_LUI   : ctrl = 7'b0001000;
            `JOP_JAL   : ctrl = {3'b011, |rd, 3'b000};
            `CSROP     : ctrl = {3'b000, csr_reg_wr, 3'b000};
            default    : ctrl = 7'b0000000;
        endcase
    end
// }}}
// {{{ CSR 
    assign csr_addr = inst[31:20];
    assign csr = (op == `CSROP) | 1'b0;
    logic[6:0] csr_ctrl;
    assign {csr_src, csr_reg_wr, csr_wr, csr_set, csr_clr, csr_mret, csr_wfi} = csr_ctrl;
    always_comb begin
        case ({csr, func3})
            {1'b1, `CSRRW}   : csr_ctrl = 7'b0110000; 
            {1'b1, `CSRRS}   : csr_ctrl = 7'b0101000;
            {1'b1, `CSRRC}   : csr_ctrl = 7'b0100100;
            {1'b1, `CSRRWI}  : csr_ctrl = 7'b1110000;
            {1'b1, `CSRRSI}  : csr_ctrl = 7'b1101000;
            {1'b1, `CSRRCI}  : csr_ctrl = 7'b1100100;
            {1'b1, `TRAPINT} : begin
                csr_ctrl[6:2] = 5'b0;
                csr_ctrl[1] =  func7[4];  // func7 == 7'b0011000, MRET
                csr_ctrl[0] = ~func7[4];  // func7 == 7'b0001000, WFI
            end
            default  : csr_ctrl = 7'b0;
        endcase
    end
// }}}

// {{{ ID
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id2ex_o.pc          <= `ADDR_BITS'h0;
            id2ex_o.func3       <= `FUNC3_BITS'h0;
            id2ex_o.func7       <= 2'b0;
            id2ex_o.imm         <= `IMM_BITS'h0;
            id2ex_o.aluop       <= `ALUOP_BITS'h0;
            id2ex_o.branch_ctrl <= `BRANCH_BITS'h0;
            id2ex_o.datatype    <= `TYPE_BITS'h0;
            id2ex_o.rs1_addr    <= `REG_BITS'h0;
            id2ex_o.rs2_addr    <= `REG_BITS'h0;
            id2ex_o.rd_addr     <= `REG_BITS'h0;
            id2ex_o.rs1_data    <= `DATA_BITS'h0;
            id2ex_o.rs2_data    <= `DATA_BITS'h0; 
            id2ex_o.pc2reg_src  <= 1'b0;
            id2ex_o.rd_src      <= 1'b0;
            id2ex_o.alu_src     <= 1'b0;
            id2ex_o.reg_wr      <= 1'b0;
            id2ex_o.dm_rd       <= 1'b0;
            id2ex_o.dm_wr       <= 1'b0;
            id2ex_o.dm2reg      <= 1'b0;
            // CSR
            id2ex_o.csr_addr <= `CSRADDR_BITS'h0;
            id2ex_o.csr      <= 1'b0;
            id2ex_o.csr_src  <= 1'b0;
            id2ex_o.csr_wr   <= 1'b0;
            id2ex_o.csr_set  <= 1'b0;
            id2ex_o.csr_clr  <= 1'b0;
            id2ex_o.csr_mret <= 1'b0;
            id2ex_o.csr_wfi  <= 1'b0;
        end 
        else if (~idexe_en_i) begin
            id2ex_o.pc          <= id2ex_o.pc;
            id2ex_o.func3       <= id2ex_o.func3;
            id2ex_o.func7       <= id2ex_o.func7;
            id2ex_o.imm         <= id2ex_o.imm;
            id2ex_o.aluop       <= id2ex_o.aluop;
            id2ex_o.branch_ctrl <= id2ex_o.branch_ctrl;
            id2ex_o.datatype    <= id2ex_o.datatype;
            id2ex_o.rs1_addr    <= id2ex_o.rs1_addr;
            id2ex_o.rs2_addr    <= id2ex_o.rs2_addr;
            id2ex_o.rd_addr     <= id2ex_o.rd_addr;
            id2ex_o.rs1_data    <= id2ex_o.rs1_data;
            id2ex_o.rs2_data    <= id2ex_o.rs2_data;
            id2ex_o.pc2reg_src  <= id2ex_o.pc2reg_src;
            id2ex_o.rd_src      <= id2ex_o.rd_src;
            id2ex_o.alu_src     <= id2ex_o.alu_src;
            id2ex_o.reg_wr      <= id2ex_o.reg_wr;
            id2ex_o.dm_rd       <= id2ex_o.dm_rd;
            id2ex_o.dm_wr       <= id2ex_o.dm_wr;
            id2ex_o.dm2reg      <= id2ex_o.dm2reg;
            // CSR
            id2ex_o.csr_addr <= id2ex_o.csr_addr;
            id2ex_o.csr      <= id2ex_o.csr;
            id2ex_o.csr_src  <= id2ex_o.csr_src;
            id2ex_o.csr_wr   <= id2ex_o.csr_wr;
            id2ex_o.csr_set  <= id2ex_o.csr_set;
            id2ex_o.csr_clr  <= id2ex_o.csr_clr;
            id2ex_o.csr_mret <= id2ex_o.csr_mret;
            id2ex_o.csr_wfi  <= id2ex_o.csr_wfi;
        end
        else if (stall_i | flush_i) begin
            id2ex_o.pc          <= id2ex_o.pc;
            id2ex_o.func3       <= `FUNC3_BITS'h0;
            id2ex_o.func7       <=  2'h0;
            id2ex_o.imm         <= `IMM_BITS'h0;
            id2ex_o.aluop       <= `ALUOP_BITS'h0;
            id2ex_o.branch_ctrl <= `BRANCH_BITS'h0;
            id2ex_o.datatype    <= `TYPE_BITS'h0;
            id2ex_o.rs1_addr    <= `REG_BITS'h0;
            id2ex_o.rs2_addr    <= `REG_BITS'h0;
            id2ex_o.rd_addr     <= `REG_BITS'h0;
            id2ex_o.rs1_data    <= `DATA_BITS'h0;
            id2ex_o.rs2_data    <= `DATA_BITS'h0; 
            id2ex_o.pc2reg_src  <=  1'b0;
            id2ex_o.rd_src      <=  1'b0;
            id2ex_o.alu_src     <=  1'b0;
            id2ex_o.reg_wr      <=  1'b0;
            id2ex_o.dm_rd       <=  1'b0;
            id2ex_o.dm_wr       <=  1'b0;
            id2ex_o.dm2reg      <=  1'b0;
            // CSR
            id2ex_o.csr_addr <= `CSRADDR_BITS'h0;
            id2ex_o.csr      <= 1'b0;
            id2ex_o.csr_src  <= 1'b0;
            id2ex_o.csr_wr   <= 1'b0;
            id2ex_o.csr_set  <= 1'b0;
            id2ex_o.csr_clr  <= 1'b0;
            id2ex_o.csr_mret <= 1'b0;
            id2ex_o.csr_wfi  <= 1'b0;
        end
        else begin
            id2ex_o.pc          <= id2if_i.pc;
            id2ex_o.func7       <= func7;
            id2ex_o.func3       <= func3;
            id2ex_o.imm         <= imm;
            id2ex_o.aluop       <= aluop;
            id2ex_o.branch_ctrl <= branch_ctrl;
            id2ex_o.datatype    <= datatype;
            id2ex_o.rs1_addr    <= rs1_addr;
            id2ex_o.rs2_addr    <= rs2_addr;
            id2ex_o.rd_addr     <= rd_addr;
            id2ex_o.rs1_data    <= rs1_data;
            id2ex_o.rs2_data    <= rs2_data;
            id2ex_o.pc2reg_src  <= pc2reg_src;
            id2ex_o.rd_src      <= rd_src;
            id2ex_o.alu_src     <= alu_src;
            id2ex_o.reg_wr      <= reg_wr;		
            id2ex_o.dm_rd       <= dm_rd;
            id2ex_o.dm_wr       <= dm_wr;
            id2ex_o.dm2reg      <= dm2reg;
            // CSR
            id2ex_o.csr_addr <= csr_addr;
            id2ex_o.csr      <= csr;
            id2ex_o.csr_src  <= csr_src;
            id2ex_o.csr_wr   <= csr_wr;
            id2ex_o.csr_set  <= csr_set;
            id2ex_o.csr_clr  <= csr_clr;
            id2ex_o.csr_mret <= csr_mret;
            id2ex_o.csr_wfi  <= csr_wfi;
        end 
    end
// }}}

// /*
// {{{ Debug (exe)
assign debug_pc = id2ex_o.pc;
always @(posedge clk or posedge rst) begin
    if (rst)              debug_inst <= 32'h0;
    else if (~idexe_en_i) debug_inst <= debug_inst;
    else if (flush_i)     debug_inst <= 32'h0;
    else                  debug_inst <= id2if_i.inst;
end
// }}}
// */
endmodule
