`include "../../include/CPU_def.svh"
`include "../../include/AXI_define.svh"
`include "../Interface/inf_Slave.sv"
`include "../Interface/sp_ram_intf.sv"
`include "EPU/InOut_SRAM_384k.sv"  // Input SRAM or Output SRAM (384 KB)
`include "ConvAcc.svh"

module Output_wrapper (
    input  logic                               clk,
    input  logic                               rst,
    input  logic                               enb_i,
    // Connection to EPU wrapper (to AXI)
           inf_EPUIN.EPUin                     epuin_i,
    output logic                               rvalid_o,
    output logic              [`DATA_BITS-1:0] rdata_o,
    // Connection to EPU
    input  logic                               start_i,
    input  logic                               finish_i,
           sp_ram_intf.memory                  bus2EPU
);
  localparam FIFO_DEPTH = 1;
  typedef enum logic [2:0] {
    IDLE   = 3'h0,
    EPU_RW = 3'h1,
    WP_AR  = 3'h2,
    WP_AW  = 3'h3,
    WP_R   = 3'h4,
    WP_W   = 3'h5
  } out_wrapper_state_t;

  out_wrapper_state_t curr_state, next_state;
  sp_ram_intf out_buff_bus ();
  logic [31:0] epu_addr_shift;

  InOut_SRAM_384k i_Output_SRAM_384k (
      .clk(clk),
      .rst(rst),
      .mem(out_buff_bus)
  );

  always_ff @(posedge clk, posedge rst) begin
    if (rst) curr_state <= IDLE;
    else curr_state <= next_state;
  end  // State (S)

  always_comb begin
    next_state = curr_state;
    case (curr_state)
      IDLE: begin
        if (start_i) next_state = EPU_RW;
        else if (epuin_i.arhns) next_state = WP_AR;
        else if (epuin_i.awhns) next_state = WP_AW;
      end
      WP_AR:  next_state = enb_i ? WP_R : IDLE;
      WP_AW:  next_state = enb_i ? WP_W : IDLE;
      WP_R: begin
        if (epuin_i.rdfin & enb_i) next_state = IDLE;
        else if (epuin_i.rhns) next_state = WP_AR;
      end
      WP_W:   if (epuin_i.wrfin & enb_i) next_state = IDLE;
      EPU_RW: if (finish_i & start_i) next_state = IDLE;
    endcase
  end  // Next state (C)

  assign epu_addr_shift = epuin_i.addr[19:2];

  always_comb begin
    bus2EPU.R_data = 0;
    rdata_o = 0;
    rvalid_o = 1'b0;
    case (curr_state)
      EPU_RW: begin
        bus2EPU.R_data      = out_buff_bus.R_data;
        out_buff_bus.cs     = bus2EPU.cs;
        out_buff_bus.oe     = bus2EPU.oe;
        out_buff_bus.addr   = bus2EPU.addr;
        out_buff_bus.W_req  = bus2EPU.W_req;
        out_buff_bus.W_data = bus2EPU.W_data;
      end
      WP_AR: begin
        rvalid_o            = 1'b0;
        out_buff_bus.cs     = epuin_i.CS;
        out_buff_bus.oe     = epuin_i.OE;
        out_buff_bus.addr   = epu_addr_shift;
        out_buff_bus.W_req  = `WRITE_DIS;
        out_buff_bus.W_data = 0;
      end
      WP_R: begin
        rvalid_o            = 1'b1;
        rdata_o             = out_buff_bus.R_data;
        out_buff_bus.cs     = epuin_i.CS;
        out_buff_bus.oe     = epuin_i.OE;
        out_buff_bus.addr   = epu_addr_shift;
        out_buff_bus.W_req  = `WRITE_DIS;
        out_buff_bus.W_data = 0;
      end
      WP_AW: begin
        out_buff_bus.cs = epuin_i.CS;
        out_buff_bus.oe = epuin_i.OE;
        out_buff_bus.addr = 0;
        out_buff_bus.W_req = `WRITE_DIS;
        out_buff_bus.W_data = 0;
      end
      WP_W: begin
        out_buff_bus.cs = epuin_i.CS;
        out_buff_bus.oe = epuin_i.OE;
        out_buff_bus.addr = epu_addr_shift;
        out_buff_bus.W_req = epuin_i.whns ? `WRITE_ENB : `WRITE_DIS;
        out_buff_bus.W_data = epuin_i.wdata;
      end
      default: begin  // IDLE
        out_buff_bus.cs = 1'b0;
        out_buff_bus.oe = 1'b0;
        out_buff_bus.addr = 0;
        out_buff_bus.W_req = `WRITE_DIS;
        out_buff_bus.W_data = 0;
      end
    endcase
  end

endmodule
