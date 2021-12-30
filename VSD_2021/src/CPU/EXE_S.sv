`include "../../include/CPU_def.svh"

module EXE_S (
	input                      clk, rst,
	inf_ID_EX.EX2ID            ex2id_i,
	inf_EX_MEM.EX2MEM          ex2mem_o,
	inf_EX_CSR.EX2CSR          ex2csr,
	input                      cpuwait_i,
	// Forward
	input  [`FORWARD_BITS-1:0] forward_rs1_i, forward_rs2_i,
	input  [`DATA_BITS   -1:0] mem_rd_data_i, wb_rd_data_i,
	output [`REG_BITS    -1:0] rs1_addr_o, rs2_addr_o, 
	// Branch
	output [`BRANCH_BITS -1:0] branch_ctrl_o,
	output                     zero_flag_o,
	output [`ADDR_BITS   -1:0] pc_imm_o, pc_aluout_o,	
	// Hazard
	output [`REG_BITS    -1:0] rd_addr_o,
	output                     dm_rd_o,

	input exemem_en_i
);
	logic        [`DATA_BITS-1:0] aluout;
	logic        [`DATA_BITS-1:0] alu1, alu2, alu2_t;
	logic signed [`DATA_BITS-1:0] signalu1, signalu2;
	logic        [`ADDR_BITS-1:0] pc_add4, pc_reg;
	logic        [4:0] aluctrl;
	logic        [4:0] shamt;
	
	
	assign branch_ctrl_o = ex2id_i.branch_ctrl;
	assign pc_aluout_o   = aluout;  // check branch
	assign pc_imm_o      = ex2id_i.pc + ex2id_i.imm;
    assign pc_add4       = ex2id_i.pc + 32'h4;
	assign pc_reg        = ex2id_i.pc2reg_src ? pc_imm_o : pc_add4;
	// rs1, rs2, rd
	assign rs1_addr_o = ex2id_i.rs1_addr;
	assign rs2_addr_o = ex2id_i.rs2_addr;
	assign rd_addr_o  = ex2id_i.rd_addr;
	//
	assign dm_rd_o = ex2id_i.dm_rd;

// {{{ Aluctrl
	always @(*) begin
		case (ex2id_i.aluop)
			`R_ALUOP   : begin
				case (ex2id_i.func3)
					3'b000  : begin
						case (ex2id_i.func7[5])
							1'b0 : aluctrl = `ADD;
							1'b1 : aluctrl = `SUB;
						endcase
					end
					3'b001  : aluctrl = `SLL;
					3'b010  : aluctrl = `SLT;
					3'b011  : aluctrl = `SLTU;
					3'b100  : aluctrl = `XOR;
					3'b101  : begin
						case (ex2id_i.func7[5])
							1'b0 : aluctrl = `SRL;
							1'b1 : aluctrl = `SRA;
						endcase
					end
					3'b110  : aluctrl = `OR;
					3'b111  : aluctrl = `AND;
					default : aluctrl = `IDLE;
				endcase
			end 
			`ADD_ALUOP : aluctrl = `ADD;
			`I_ALUOP   : begin
				case (ex2id_i.func3)
					3'b000  : aluctrl = `ADD;
					3'b010  : aluctrl = `SLT;
					3'b011  : aluctrl = `SLTU;
					3'b100  : aluctrl = `XOR;
					3'b110  : aluctrl = `OR;
					3'b111  : aluctrl = `AND;
					3'b001  : aluctrl = `SLLI;
					3'b101  : begin
						case (ex2id_i.func7[5]) 
							1'b0 : aluctrl = `SRLI;
							1'b1 : aluctrl = `SRAI;
						endcase
					end
					default : aluctrl = `IDLE;
				endcase
			end
			`BEQ_ALUOP : begin
				case (ex2id_i.func3)
					3'b000  : aluctrl = `BEQ;
					3'b001  : aluctrl = `BNE; 
					3'b100  : aluctrl = `SLT;  // BLT
					3'b101  : aluctrl = `BGE; 
					3'b110  : aluctrl = `SLTU; // BLTU
					3'b111  : aluctrl = `BGEU;
					default : aluctrl = `IDLE;
				endcase
			end
			`LUI_ALUOP : aluctrl = `IMM;
			default    : aluctrl = `IDLE;
		endcase
	end
// }}}

	assign alu2     = ex2id_i.alu_src ? ex2id_i.imm : alu2_t;
	assign signalu1 = alu1;
	assign signalu2 = alu2;
	assign shamt    = ex2id_i.imm[4:0]; 
// {{{ Forward
	always @(*) begin
		case (forward_rs1_i)
			`FORWARD_MEMRD : alu1 = mem_rd_data_i;    // 2'h1
			`FORWARD_WBRD  : alu1 = wb_rd_data_i;     // 2'h2
			default        : alu1 = ex2id_i.rs1_data; // 2'h3
		endcase
		case (forward_rs2_i)
			`FORWARD_MEMRD : alu2_t = mem_rd_data_i;    // 2'h1
			`FORWARD_WBRD  : alu2_t = wb_rd_data_i;     // 2'h2
			default        : alu2_t = ex2id_i.rs2_data; // 2'h3			
		endcase
	end
// }}}
// {{{ Aluout
	assign zero_flag_o = ~|aluout;
	always @(*) begin
		case (aluctrl)
			`ADD    : aluout = alu1 + alu2; 
			`SUB    : aluout = alu1 - alu2;
			`SLL    : aluout = alu1 << alu2[4:0];   
			`SLT    : aluout = {31'h0, (signalu1 < signalu2)};
			`SLTU   : aluout = {31'h0, (alu1 < alu2)};
			`XOR    : aluout = alu1 ^ alu2;
			`SRL    : aluout = alu1 >> alu2[4:0];
			`SRA    : aluout = signalu1 >>> alu2[4:0];
			`OR     : aluout = alu1 | alu2;
			`AND    : aluout = alu1 & alu2;
			`SLLI   : aluout = alu1 << shamt;
			`SRLI   : aluout = alu1 >> shamt;
			`SRAI   : aluout = signalu1 >>> shamt;
			`IMM    : aluout = ex2id_i.imm;
			`BEQ    : aluout = {31'h0, (alu1 == alu2)};  // 1: pc + imm; 0: pc + 4
			`BNE    : aluout = {31'h0, (alu1 != alu2)};  // 1: pc + imm; 0: pc + 4
			`BGE    : aluout = {31'h0, (signalu1 >= signalu2)};
			`BGEU   : aluout = {31'h0, (alu1 >= alu2)};
			default : aluout = `DATA_BITS'h0;
		endcase
	end
// }}}
// {{{ CSR
	assign ex2csr.pc        = ex2id_i.pc;
	assign ex2csr.csr_addr  = ex2id_i.csr_addr;
	assign ex2csr.rs1_rdata = ex2id_i.csr_src ? ex2id_i.imm : alu1;
	assign ex2csr.reg_wr    = ex2id_i.reg_wr;
	assign ex2csr.wr        = ex2id_i.csr_wr;
	assign ex2csr.set       = ex2id_i.csr_set;
	assign ex2csr.clr       = ex2id_i.csr_clr;
	assign ex2csr.mret      = ex2id_i.csr_mret;
	assign ex2csr.wfi       = ex2id_i.csr_wfi;
// }}}
// {{{ EXE

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			ex2mem_o.datatype <= `TYPE_BITS'h0;
			ex2mem_o.aluout   <= `DATA_BITS'h0;
			ex2mem_o.dm_data  <= `DATA_BITS'h0;
			ex2mem_o.pc2reg   <= `DATA_BITS'h0;
			ex2mem_o.rd_addr  <= `REG_BITS'h0;
			ex2mem_o.reg_wr   <=  1'b0;
			ex2mem_o.rd_src   <=  1'b0;
			ex2mem_o.dm2reg   <=  1'b0;
			ex2mem_o.dm_rd    <=  1'b0;
			ex2mem_o.dm_wr    <=  1'b0;
		end 
		else if (~exemem_en_i) begin
			ex2mem_o.datatype <= ex2mem_o.datatype;
			ex2mem_o.aluout   <= ex2mem_o.aluout;
			ex2mem_o.dm_data  <= ex2mem_o.dm_data;
			ex2mem_o.pc2reg   <= ex2mem_o.pc2reg;
			ex2mem_o.rd_addr  <= ex2mem_o.rd_addr;
			ex2mem_o.reg_wr   <= ex2mem_o.reg_wr;
			ex2mem_o.rd_src   <= ex2mem_o.rd_src;
			ex2mem_o.dm2reg   <= ex2mem_o.dm2reg;  
			ex2mem_o.dm_rd    <= ex2mem_o.dm_rd;
			ex2mem_o.dm_wr    <= ex2mem_o.dm_wr;
		end
		//else if (exemem_en_i) begin
		else begin
			ex2mem_o.datatype <= ex2id_i.datatype;
			ex2mem_o.dm_data  <= alu2_t;
			ex2mem_o.aluout   <= ex2id_i.csr ? ex2csr.rd_wdata : aluout;
			ex2mem_o.pc2reg   <= pc_reg;
			ex2mem_o.rd_addr  <= ex2id_i.rd_addr;
			ex2mem_o.reg_wr   <= ex2id_i.reg_wr;
			ex2mem_o.rd_src   <= ex2id_i.rd_src;
			ex2mem_o.dm2reg   <= ex2id_i.dm2reg;
			ex2mem_o.dm_rd    <= ex2id_i.dm_rd;
			ex2mem_o.dm_wr    <= ex2id_i.dm_wr;
		end
		/*
		else begin
			ex2mem_o.datatype <= ex2mem_o.datatype;
			ex2mem_o.aluout   <= ex2mem_o.aluout;
			ex2mem_o.dm_data  <= ex2mem_o.dm_data;
			ex2mem_o.pc2reg   <= ex2mem_o.pc2reg;
			ex2mem_o.rd_addr  <= ex2mem_o.rd_addr;
			ex2mem_o.reg_wr   <= ex2mem_o.reg_wr;
			ex2mem_o.rd_src   <= ex2mem_o.rd_src;
			ex2mem_o.dm2reg   <= ex2mem_o.dm2reg;  
			ex2mem_o.dm_rd    <= ex2mem_o.dm_rd;
			ex2mem_o.dm_wr    <= ex2mem_o.dm_wr;
		end
		*/
	end


// }}}

endmodule
