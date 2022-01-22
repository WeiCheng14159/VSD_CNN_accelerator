`include "Interface/sp_ram_intf.sv"

module InOut_switcher (
    input logic inout_trans_i,
    sp_ram_intf.compute from_in_buff_i,
    sp_ram_intf.compute from_out_buff_i,
    sp_ram_intf.memory to_EPU_in_buff_o,
    sp_ram_intf.memory to_EPU_out_buff_o
);

  always_comb begin
    if (inout_trans_i) begin
      // input buffer <-> EPU output
      to_EPU_in_buff_o.R_data  = from_out_buff_i.R_data;
      from_out_buff_i.cs       = to_EPU_in_buff_o.cs;
      from_out_buff_i.oe       = to_EPU_in_buff_o.oe;
      from_out_buff_i.addr     = to_EPU_in_buff_o.addr;
      from_out_buff_i.W_req    = to_EPU_in_buff_o.W_req;
      from_out_buff_i.W_data   = to_EPU_in_buff_o.W_data;
      // output buffer <-> EPU input
      to_EPU_out_buff_o.R_data = from_in_buff_i.R_data;
      from_in_buff_i.cs        = to_EPU_out_buff_o.cs;
      from_in_buff_i.oe        = to_EPU_out_buff_o.oe;
      from_in_buff_i.addr      = to_EPU_out_buff_o.addr;
      from_in_buff_i.W_req     = to_EPU_out_buff_o.W_req;
      from_in_buff_i.W_data    = to_EPU_out_buff_o.W_data;
    end else begin
      // input buffer <-> EPU input
      to_EPU_in_buff_o.R_data  = from_in_buff_i.R_data;
      from_in_buff_i.cs        = to_EPU_in_buff_o.cs;
      from_in_buff_i.oe        = to_EPU_in_buff_o.oe;
      from_in_buff_i.addr      = to_EPU_in_buff_o.addr;
      from_in_buff_i.W_req     = to_EPU_in_buff_o.W_req;
      from_in_buff_i.W_data    = to_EPU_in_buff_o.W_data;
      // output buffer <-> EPU output
      to_EPU_out_buff_o.R_data = from_out_buff_i.R_data;
      from_out_buff_i.cs       = to_EPU_out_buff_o.cs;
      from_out_buff_i.oe       = to_EPU_out_buff_o.oe;
      from_out_buff_i.addr     = to_EPU_out_buff_o.addr;
      from_out_buff_i.W_req    = to_EPU_out_buff_o.W_req;
      from_out_buff_i.W_data   = to_EPU_out_buff_o.W_data;
    end
  end

endmodule
