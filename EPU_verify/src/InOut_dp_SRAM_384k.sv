`include "SRAM_dp_16b_32768w_64k.sv"
`include "sp_ram_intf.sv"

// Combine six 64kB dual port SRAM into 384kB SRAM

module InOut_dp_SRAM_384k (
    input logic              clk,
          sp_ram_intf.memory mem0,
          sp_ram_intf.memory mem1
);

  // Port A
  logic        CKA;
  logic        CSA;
  logic        OEA;
  logic        WEAN;
  logic [17:0] AA;
  logic [15:0] DIA;
  logic [15:0] DOA;
  logic [17:0] latched_AA;
  logic [15:0] _DOA       [0:5];
  // Port B
  logic        CKB;
  logic        CSB;
  logic        OEB;
  logic        WEBN;
  logic [17:0] AB;
  logic [15:0] DIB;
  logic [15:0] DOB;
  logic [17:0] latched_AB;
  logic [15:0] _DOB       [0:5];

  // Port A
  assign CKA = clk;
  assign CSA = mem0.cs;
  assign OEA = mem0.oe;
  assign AA = mem0.addr[17:0];
  assign DIA = mem0.W_data[15:0];
  assign WEAN = mem0.W_req;
  assign mem0.R_data = {{16{DOA[15]}}, DOA};
  always_ff @(posedge CKA) latched_AA <= AA;

  // Port B
  assign CKB = clk;
  assign CSB = mem1.cs;
  assign OEB = mem1.oe;
  assign AB = mem1.addr[17:0];
  assign DIB = mem1.W_data[15:0];
  assign WEBN = mem1.W_req;
  assign mem1.R_data = {{16{DOB[15]}}, DOB};
  always_ff @(posedge CKB) latched_AB <= AB;

  always_comb begin
    DOA = 16'b0;
    case (latched_AA[17:15])
      3'h0: DOA = _DOA[0];
      3'h1: DOA = _DOA[1];
      3'h2: DOA = _DOA[2];
      3'h3: DOA = _DOA[3];
      3'h4: DOA = _DOA[4];
      3'h5: DOA = _DOA[5];
      3'h6: DOA = 16'bz;
      3'h7: DOA = 16'bz;
    endcase
  end

  always_comb begin
    DOB = 16'b0;
    case (latched_AB[17:15])
      3'h0: DOB = _DOB[0];
      3'h1: DOB = _DOB[1];
      3'h2: DOB = _DOB[2];
      3'h3: DOB = _DOB[3];
      3'h4: DOB = _DOB[4];
      3'h5: DOB = _DOB[5];
      3'h6: DOB = 16'bz;
      3'h7: DOB = 16'bz;
    endcase
  end

  genvar g;
  generate
    for (g = 0; g < 6; g = g + 1) begin : SRAM_blk
      logic _CSA;
      logic _OEA;
      logic _WEAN;
      logic _CSB;
      logic _OEB;
      logic _WEBN;

      assign _CSA  = AA[17:15] == g[2:0] ? CSA : 1'b0;
      assign _OEA  = latched_AA[17:15] == g[2:0] ? OEA : 1'b0;
      assign _WEAN = AA[17:15] == g[2:0] ? WEAN : 1'b1;
      assign _CSB  = AB[17:15] == g[2:0] ? CSB : 1'b0;
      assign _OEB  = latched_AB[17:15] == g[2:0] ? OEB : 1'b0;
      assign _WEBN = AB[17:15] == g[2:0] ? WEBN : 1'b1;

      SRAM_dp_16b_32768w_64k i_SRAM_16b_32768w_64k (
          .CKA (CKA),
          .CSA (_CSA),
          .OEA (_OEA),
          .WEAN(_WEAN),
          .AA  (AA[14:0]),
          .DIA (DIA),
          .DOA (_DOA[g]),
          .CKB (CKB),
          .CSB (_CSB),
          .OEB (_OEB),
          .WEBN(_WEBN),
          .AB  (AB[14:0]),
          .DIB (DIB),
          .DOB (_DOB[g])
      );
    end : SRAM_blk
  endgenerate

endmodule
