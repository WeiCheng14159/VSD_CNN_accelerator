`include "../include/CPU_def.svh"
`include "./Interface/inf_IF_ID.sv"
`include "./Interface/inf_ID_EX.sv"
`include "./Interface/inf_EX_CSR.sv"
`include "./Interface/inf_EX_MEM.sv"
`include "./Interface/inf_MEM_WB.sv"
`include "./CPU/RegFile.sv"
`include "./CPU/Forward.sv"
`include "./CPU/Hazard.sv"
`include "./CPU/IF_S.sv"
`include "./CPU/ID_S.sv"
`include "./CPU/EXE_S.sv"
`include "./CPU/CSR.sv"
`include "./CPU/MEM_S.sv"
`include "./CPU/WB_S.sv"

module CPU (
    input clk, rst,
    input        [`DATA_BITS-1:0] inst_i,
    input        [`DATA_BITS-1:0] dm_data_i,
    output       [`ADDR_BITS-1:0] inst_pc_o,
    output       [`WEB_BITS -1:0] web_o,
    output       [`ADDR_BITS-1:0] dm_addr_o,
    output       [`DATA_BITS-1:0] dm_data_o,
    output logic [`TYPE_BITS-1:0] cputype_o,
    input                         wait1_i,
    output logic                  req1_o,
    output logic                  read1_o, //write1_o,
    input                         wait2_i,
    output logic                  req2_o,
    output logic                  read2_o, write2_o,
    // 2021.11.23
    // Interrupt
    input int_taken_i
);

    inf_IF_ID  inf_IF_ID();
    inf_ID_EX  inf_ID_EX();
    inf_EX_CSR inf_EX_CSR();
    inf_EX_MEM inf_EX_MEM();
    inf_MEM_WB inf_MEM_WB();

    logic [`BRANCH_BITS -1:0] exe_branch_ctrl;
    logic [`DATA_BITS   -1:0] id_rs1_data, id_rs2_data, exe_rd_data, mem_rd_data, wb_rd_data;
    logic [`REG_BITS    -1:0] id_rs1_addr, id_rs2_addr, exe_rs1_addr, exe_rs2_addr;
    logic [`REG_BITS    -1:0] exe_rd_addr, mem_rd_addr, wb_rd_addr;
    logic [`FORWARD_BITS-1:0] forward_rs1, forward_rs2;
    logic [`ADDR_BITS   -1:0] exe_pc_imm, exe_pc_add4, exe_pc_aluout;
    logic ifid_en, idexe_en, exemem_en, memwb_en, csr_en;  // enable
    logic stall, flush;
    logic exe_zero_flag; 
    logic mem_reg_wr, wb_reg_wr;
    logic exe_dm_rd;
    // cpu wait
    logic cpuwait;
    logic dm_clear;
    // Interrupt, CSR
    logic [`ADDR_BITS-1:0] csr_pc, csr_retpc;
    logic csr_stall;
    logic csr_wfi, csr_mret, csr_int;

    assign cpuwait = wait1_i | wait2_i;

    // assign write1_o = 1'b0;
    assign read1_o = 1'b1;
    always_ff @(posedge clk or posedge rst) begin
        req1_o   <= rst ? 1'b1 : (cpuwait ? 1'b0 : 1'b1);
        dm_clear <= rst ? 1'b0 : (wait1_i & ~wait2_i ? 1'b1 : 1'b0);
    end

    assign req2_o = dm_clear ? 1'b0 : (read2_o | write2_o);



    assign ifid_en   = ~cpuwait & ~csr_stall;
    assign idexe_en  = ~cpuwait & ~csr_stall;
    assign exemem_en = ~cpuwait & ~csr_stall;
    assign memwb_en  = ~cpuwait & ~csr_stall;
    assign csr_en    = ~cpuwait;
    
// /*
// {{{ Debug
    logic [31:0] d_idpc, d_exepc, d_mempc, d_wbpc;
    logic [31:0] d_idinst, d_exeinst, d_meminst, d_wbinst;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            d_mempc   <= 32'h0;
            d_wbpc    <= 32'h0;
            d_meminst <= 32'h0;
            d_wbinst  <= 32'h0;
        end
        else if (cpuwait) begin
            d_mempc   <= d_mempc;
            d_wbpc    <= d_wbpc;
            d_meminst <= d_meminst;
            d_wbinst  <= d_wbinst;
        end
        else begin
            d_mempc   <= d_exepc;
            d_wbpc    <= d_mempc;
            d_meminst <= d_exeinst;
            d_wbinst  <= d_meminst;
        end
    end
// }}}
// */
    IF_S i_if (
        /* Debug */
        .debug_pc   (d_idpc   ),
        .debug_inst (d_idinst ),

        .clk               (clk            ),
        .rst               (rst            ),
        .if2id_o           (inf_IF_ID.IF2ID),
        .ifid_en_i         (ifid_en        ),
        .stall_i           (stall          ),
        .flush_i           (flush          ),
        .inst_i            (inst_i         ),
        .inst_pc_o         (inst_pc_o      ),
        .exe_branch_ctrl_i (exe_branch_ctrl),
        .exe_pc_imm_i      (exe_pc_imm     ), 
        .exe_pc_aluout_i   (exe_pc_aluout  ),
        .exe_zero_flag_i   (exe_zero_flag  ),
        // CSR
        .csr_int_i   (csr_int  ),
        .csr_mret_i  (csr_mret ),
        .csr_pc_i    (csr_pc   ),
        .csr_retpc_i (csr_retpc)

    );
    ID_S i_id (
        /* Debug */
        .debug_pc   (d_exepc  ),
        .debug_inst (d_exeinst),

        .clk        (clk            ),
        .rst        (rst            ),
        .idexe_en_i (idexe_en       ),
        .id2if_i    (inf_IF_ID.ID2IF),
        .id2ex_o    (inf_ID_EX.ID2EX),
        .stall_i    (stall          ),
        .flush_i    (flush          ),
        .rs1_data_i (id_rs1_data    ),
        .rs2_data_i (id_rs2_data    ),
        .rs1_addr_o (id_rs1_addr    ),
        .rs2_addr_o (id_rs2_addr    )
    );
    EXE_S i_exe (
        .clk           (clk              ),
        .rst           (rst              ),
        .ex2id_i       (inf_ID_EX.EX2ID  ),
        .ex2mem_o      (inf_EX_MEM.EX2MEM),
        .exemem_en_i   (exemem_en        ),
        .ex2csr        (inf_EX_CSR.EX2CSR),
        .forward_rs1_i (forward_rs1      ),
        .forward_rs2_i (forward_rs2      ),
        .mem_rd_data_i (mem_rd_data      ),
        .wb_rd_data_i  (wb_rd_data       ),
        .rs1_addr_o    (exe_rs1_addr     ),
        .rs2_addr_o    (exe_rs2_addr     ),
        .branch_ctrl_o (exe_branch_ctrl  ),
        .zero_flag_o   (exe_zero_flag    ),
        .pc_imm_o      (exe_pc_imm       ),
        .pc_aluout_o   (exe_pc_aluout    ),
        .rd_addr_o     (exe_rd_addr      ),
        .dm_rd_o       (exe_dm_rd        )
    );

    CSR i_csr (
        .clk         (clk              ),
        .rst         (rst              ),
        .csr2ex      (inf_EX_CSR.CSR2EX),
        .csr_en_i    (csr_en           ),
        .int_taken_i (int_taken_i      ),
        .csr_pc_o    (csr_pc           ),
        .csr_retpc_o (csr_retpc        ),
        .wfi_o       (csr_wfi          ),
        .mret_o      (csr_mret         ),
        .int_o       (csr_int          ),
        
        
        .stall_o (csr_stall        )
    );

    MEM_S i_mem (
        .clk        (clk              ),
        .rst        (rst              ),
        .mem2ex_i   (inf_EX_MEM.MEM2EX),
        .mem2wb_o   (inf_MEM_WB.MEM2WB),
        .memwb_en_i (memwb_en         ),
        // Forward
        .rd_data_o  (mem_rd_data      ),
        .rd_addr_o  (mem_rd_addr      ),
        .reg_wr_o   (mem_reg_wr       ),
        //
        .data_i     (dm_data_i        ),
        .dm_addr_o  (dm_addr_o        ),
        .dm_sw_o    (dm_data_o        ),
        .dm_web_o   (web_o            ),
        .dm_rd_o    (read2_o          ),
        .dm_wr_o    (write2_o         ),
        .cputype_o  (cputype_o        )
    );
    WB_S i_wb (
        .wb2mem_i (inf_MEM_WB.WB2MEM),
        .reg_wr_o (wb_reg_wr        ),
        .addr_o   (wb_rd_addr       ),
        .data_o   (wb_rd_data       )
    );
    RegFile i_regfile (
        .clk         (clk        ),
        .rst         (rst        ),
        .wb_reg_wr_i (wb_reg_wr  ),
        .rs1_addr_i  (id_rs1_addr),
        .rs2_addr_i  (id_rs2_addr),
        .rd_addr_i   (wb_rd_addr ),
        .rs1_data_o  (id_rs1_data),
        .rs2_data_o  (id_rs2_data),
        .rd_data_i   (wb_rd_data )
    );	
    Forward i_forward (
        .exe_rs1_addr_i (exe_rs1_addr),
        .exe_rs2_addr_i (exe_rs2_addr),
        .mem_reg_wr_i   (mem_reg_wr  ),
        .mem_rd_addr_i  (mem_rd_addr ),
        .wb_reg_wr_i    (wb_reg_wr   ),
        .wb_rd_addr_i   (wb_rd_addr  ),
        .forward_rs1_o  (forward_rs1 ),
        .forward_rs2_o  (forward_rs2 )
    );
    Hazard i_hazard (
        .id_rs1_addr_i     (id_rs1_addr    ),
        .id_rs2_addr_i     (id_rs2_addr    ),
        .exe_branch_ctrl_i (exe_branch_ctrl),
        .exe_zero_flag_i   (exe_zero_flag  ),
        .exe_dm_rd_i       (exe_dm_rd      ),
        .exe_rd_addr_i     (exe_rd_addr    ),
        .stall_o           (stall          ),
        .flush_o           (flush          ),
        .csr_wfi_i       (csr_wfi      ),
        .csr_mret_i        (csr_mret       ),
        .csr_int_i         (csr_int        )
        
    );

endmodule
