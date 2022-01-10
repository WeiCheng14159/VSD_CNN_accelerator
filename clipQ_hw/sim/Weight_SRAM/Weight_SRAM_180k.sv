`include "SRAM_18b_16384w_36k.sv"

// Combine five 36kB SRAM into 180kB SRAM

module Weight_SRAM_180k (
    input               CK,
    input               CS,
    input               OE,
    input               WEB,
    input        [16:0] A,
    input        [17:0] DI,
    output logic [17:0] DO
);

  logic [16:0] latched_A;
  logic [17:0] _DO[0:4];

  always_ff @(posedge CK) latched_A <= A;

  always_comb begin
    DO = 18'b0;
    case (latched_A[16:14])
      3'h0: DO = _DO[0];
      3'h1: DO = _DO[1];
      3'h2: DO = _DO[2];
      3'h3: DO = _DO[3];
      3'h4: DO = _DO[4];
      3'h5: DO = 18'bz;
      3'h6: DO = 18'bz;
      3'h7: DO = 18'bz;
    endcase
  end

  genvar g;
  generate
    for (g = 0; g < 5; g = g + 1) begin : i_SRAM
      logic       _CS;
      logic       _OE;
      logic       _WEB;

      assign _CS  = A[16:14] == g[2:0] ? CS : 1'b0;
      assign _OE  = latched_A[16:14] == g[2:0] ? OE : 1'b0;
      assign _WEB = A[16:14] == g[2:0] ? WEB : 1'b1;

      SRAMSUMA180_16384X18X1BM4_64k i_SUMA180_16384X18X1BM4 (
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
