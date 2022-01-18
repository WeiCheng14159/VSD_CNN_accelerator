module SRAM_18b_16384w_36k (
    input         CK,
    input         CS,
    input         OE,
    input         WEB,
    input  [13:0] A,
    input  [17:0] DI,
    output [17:0] DO
);

  SUMA180_16384X18X1BM4 i_SUMA180_16384X18X1BM4 (
      .A0  (A[0]),
      .A1  (A[1]),
      .A2  (A[2]),
      .A3  (A[3]),
      .A4  (A[4]),
      .A5  (A[5]),
      .A6  (A[6]),
      .A7  (A[7]),
      .A8  (A[8]),
      .A9  (A[9]),
      .A10 (A[10]),
      .A11 (A[11]),
      .A12 (A[12]),
      .A13 (A[13]),
      .DO0 (DO[0]),
      .DO1 (DO[1]),
      .DO2 (DO[2]),
      .DO3 (DO[3]),
      .DO4 (DO[4]),
      .DO5 (DO[5]),
      .DO6 (DO[6]),
      .DO7 (DO[7]),
      .DO8 (DO[8]),
      .DO9 (DO[9]),
      .DO10(DO[10]),
      .DO11(DO[11]),
      .DO12(DO[12]),
      .DO13(DO[13]),
      .DO14(DO[14]),
      .DO15(DO[15]),
      .DO16(DO[16]),
      .DO17(DO[17]),
      .DI0 (DI[0]),
      .DI1 (DI[1]),
      .DI2 (DI[2]),
      .DI3 (DI[3]),
      .DI4 (DI[4]),
      .DI5 (DI[5]),
      .DI6 (DI[6]),
      .DI7 (DI[7]),
      .DI8 (DI[8]),
      .DI9 (DI[9]),
      .DI10(DI[10]),
      .DI11(DI[11]),
      .DI12(DI[12]),
      .DI13(DI[13]),
      .DI14(DI[14]),
      .DI15(DI[15]),
      .DI16(DI[16]),
      .DI17(DI[17]),
      .CK  (CK),
      .WEB (WEB),
      .OE  (OE),
      .CS  (CS)
  );

endmodule
