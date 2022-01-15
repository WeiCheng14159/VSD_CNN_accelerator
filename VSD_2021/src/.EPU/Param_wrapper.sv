`include "../../include/CPU_def.svh"
`include "../../include/AXI_define.svh"
`include "../Interface/inf_Slave.sv"
`include "Param_SRAM/Param_SRAM_16B.sv"  // Param SRAM (16B)
`include "ConvAcc.svh"

module Param_wrapper (
    input  logic                               clk,
    input  logic                               rst,
    input  logic                               enb_i,
    // Connection to EPU wrapper (to AXI)
           inf_EPUIN.EPUin                     epuin_i,
    output logic                               rvalid_o,
    output logic              [`DATA_BITS-1:0] rdata_o,
    // Connection to EPU
           sp_ram_intf.memory                  bus2EPU
);

  typedef enum logic [2:0] {
    IDLE      = 3'h0,
    EPU_RW    = 3'h1,
    // WRAPPER_R = 3'h2,
    WRAPPER_W = 3'h3
  } param_wrapper_state_t;

  param_wrapper_state_t curr_state, next_state;
  sp_ram_intf param_buff_bus ();

  Param_SRAM_16B i_Param_SRAM_16B (
      .clk(clk),
      .mem(param_buff_bus)
  );

  always_ff @(posedge clk, posedge rst) begin
    if (rst) curr_state <= IDLE;
    else curr_state <= next_state;
  end  // State (S)

  always_comb begin
    next_state = curr_state;
    case (curr_state)
      IDLE: begin
        if (epuin_i.awhns & enb_i) next_state = WRAPPER_W;
        else next_state = IDLE;
      end
      WRAPPER_W: if (epuin_i.rdfin & enb_i) next_state = EPU_RW;
      EPU_RW: begin
        if (epuin_i.awhns & enb_i) next_state = WRAPPER_W;
        else next_state = EPU_RW;
      end
    endcase
  end  // Next state (C)

  always_comb begin
    bus2EPU.R_data = 0;
    rdata_o = 0;
    if (curr_state == EPU_RW) begin
      bus2EPU.R_data     = param_buff_bus.R_data;
      param_buff_bus.cs     = bus2EPU.cs;
      param_buff_bus.oe     = bus2EPU.oe;
      param_buff_bus.addr   = bus2EPU.addr;
      param_buff_bus.W_req  = bus2EPU.W_req;
      param_buff_bus.W_data = bus2EPU.W_data;
    // end else if (curr_state == WRAPPER_R) begin
    //   rdata_o            = param_buff_bus.R_data;
    //   param_buff_bus.cs     = epuin_i.CS;
    //   param_buff_bus.oe     = epuin_i.OE;
    //   param_buff_bus.addr   = epuin_i.addr;
    //   param_buff_bus.W_req  = `WRITE_DIS;
    //   param_buff_bus.W_data = 0;
    end else if (curr_state == WRAPPER_W) begin
      rdata_o            = 0;
      param_buff_bus.cs     = epuin_i.CS;
      param_buff_bus.oe     = epuin_i.OE;
      param_buff_bus.addr   = epuin_i.addr;
      param_buff_bus.W_req  = `WRITE_ENB;
      param_buff_bus.W_data = epuin_i.wdata;
    end else begin  // IDLE
      param_buff_bus.cs     = 1'b0;
      param_buff_bus.oe     = 1'b0;
      param_buff_bus.addr   = 0;
      param_buff_bus.W_req  = `WRITE_DIS;
      param_buff_bus.W_data = 0;
    end
  end

endmodule
