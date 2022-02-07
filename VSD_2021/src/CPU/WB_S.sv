`include "../../include/CPU_def.svh"
`include "../Interface/inf_MEM_WB.sv"

module WB_S (
          inf_MEM_WB.WB2MEM                  wb2mem_i,
    output                                   reg_wr_o,
    output                  [`REG_BITS -1:0] addr_o,
    output                  [`DATA_BITS-1:0] data_o
);
  assign reg_wr_o = wb2mem_i.reg_wr;
  assign data_o   = wb2mem_i.dm2reg ? wb2mem_i.dm_out : wb2mem_i.rd_data;
  assign addr_o   = wb2mem_i.rd_addr;

endmodule
