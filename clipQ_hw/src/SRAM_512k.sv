// =================================================== //
// Auther:      Yu-Tong Shen                           //
// Filename:    SRAM_512k.sv                           //
// Description: SRAM with 512kB                        //
// Version:     1.0                                    //
// =================================================== //

`include "SRAM_64k.sv"

module SRAM_512k (
    input               CK,
    input               CS,
    input               OE,
    input        [ 3:0] WEB,
    input        [16:0] A,
    input        [31:0] DI,
    output logic [31:0] DO
);

  logic [16:0] latched_A;
  logic [31:0] _DO[0:7];

  always_ff @(posedge CK) latched_A <= A;

  always_comb begin
    DO = 32'b0;
    case (latched_A[16:14])
      3'h0: DO = _DO[0];
      3'h1: DO = _DO[1];
      3'h2: DO = _DO[2];
      3'h3: DO = _DO[3];
      3'h4: DO = _DO[4];
      3'h5: DO = _DO[5];
      3'h6: DO = _DO[6];
      3'h7: DO = _DO[7];
    endcase
  end

  genvar g;
  generate
    for (g = 0; g < 8; g = g + 1) begin : i_SRAM
      logic       _CS;
      logic       _OE;
      logic [3:0] _WEB;

      assign _CS  = A[16:14] == g[2:0] ? CS : 1'b0;
      assign _OE  = latched_A[16:14] == g[2:0] ? OE : 1'b0;
      assign _WEB = A[16:14] == g[2:0] ? WEB : 4'hF;

      SRAM_64k i_SRAM_64k (
          .CK (CK),
          .CS (_CS),
          .OE (_OE),
          .WEB(_WEB),
          .A  (A[13:0]),
          .DI (DI),
          .DO (_DO[g])
      );
    end : i_SRAM
  endgenerate

endmodule
