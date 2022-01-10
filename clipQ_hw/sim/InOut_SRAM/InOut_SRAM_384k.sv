`include "SRAM_16b_32768w_64k.sv"

// Combine six 64kB SRAM into 384kB SRAM

module InOut_SRAM_384k (
    input logic         CK,
    input logic         CS,
    input logic         OE,
    input logic         WEB,
    input logic  [17:0] A,
    input logic  [15:0] DI,
    output logic [15:0] DO
);

  logic [17:0] latched_A;
  logic [15:0] _DO [0:5];

  always_ff @(posedge CK) latched_A <= A;

  always_comb begin
    DO = 16'b0;
    case (latched_A[17:15])
      3'h0: DO = _DO[0];
      3'h1: DO = _DO[1];
      3'h2: DO = _DO[2];
      3'h3: DO = _DO[3];
      3'h4: DO = _DO[4];
      3'h5: DO = _DO[5];
      3'h6: DO = 16'bz;
      3'h7: DO = 16'bz;
    endcase
  end

  genvar g;
  generate
    for (g = 0; g < 6; g = g + 1) begin : i_SRAM
      logic       _CS;
      logic       _OE;
      logic       _WEB;

      assign _CS  = A[17:15] == g[2:0] ? CS : 1'b0;
      assign _OE  = latched_A[17:15] == g[2:0] ? OE : 1'b0;
      assign _WEB = A[17:15] == g[2:0] ? WEB : 1'b1;

      SRAM_16b_32768w_64k i_SRAM_16b_32768w_64k (
          .CK (CK),
          .CS (_CS),
          .OE (_OE),
          .WEB(_WEB),
          .A  (A[14:0]),
          .DI (DI),
          .DO (_DO[g])
      );
    end : i_SRAM
  endgenerate

endmodule
