module SRAM_dp_16b_32768w_64k (
    // Port A
    input         CKA,
    input         CSA,
    input         OEA,
    input         WEAN,
    input  [14:0] AA,
    input  [15:0] DIA,
    output [15:0] DOA,
    // Port B
    input         CKB,
    input         CSB,
    input         OEB,
    input         WEBN,
    input  [14:0] AB,
    input  [15:0] DIB,
    output [15:0] DOB
);

  SJMA180_32768X16X1BM8 i_SJMA180_32768X16X1BM8 (
      // Port A
      .A0  (AA[0]),
      .A1  (AA[1]),
      .A2  (AA[2]),
      .A3  (AA[3]),
      .A4  (AA[4]),
      .A5  (AA[5]),
      .A6  (AA[6]),
      .A7  (AA[7]),
      .A8  (AA[8]),
      .A9  (AA[9]),
      .A10 (AA[10]),
      .A11 (AA[11]),
      .A12 (AA[12]),
      .A13 (AA[13]),
      .A14 (AA[14]),
      .DOA0 (DOA[0]),
      .DOA1 (DOA[1]),
      .DOA2 (DOA[2]),
      .DOA3 (DOA[3]),
      .DOA4 (DOA[4]),
      .DOA5 (DOA[5]),
      .DOA6 (DOA[6]),
      .DOA7 (DOA[7]),
      .DOA8 (DOA[8]),
      .DOA9 (DOA[9]),
      .DOA10(DOA[10]),
      .DOA11(DOA[11]),
      .DOA12(DOA[12]),
      .DOA13(DOA[13]),
      .DOA14(DOA[14]),
      .DOA15(DOA[15]),
      .DIA0 (DIA[0]),
      .DIA1 (DIA[1]),
      .DIA2 (DIA[2]),
      .DIA3 (DIA[3]),
      .DIA4 (DIA[4]),
      .DIA5 (DIA[5]),
      .DIA6 (DIA[6]),
      .DIA7 (DIA[7]),
      .DIA8 (DIA[8]),
      .DIA9 (DIA[9]),
      .DIA10(DIA[10]),
      .DIA11(DIA[11]),
      .DIA12(DIA[12]),
      .DIA13(DIA[13]),
      .DIA14(DIA[14]),
      .DIA15(DIA[15]),
      .CKA  (CKA),
      .WEAN (WEAN),
      .OEA  (OEA),
      .CSA  (CSA),
      // Port B
      .B0   (AB[0]),
      .B1   (AB[1]),
      .B2   (AB[2]),
      .B3   (AB[3]),
      .B4   (AB[4]),
      .B5   (AB[5]),
      .B6   (AB[6]),
      .B7   (AB[7]),
      .B8   (AB[8]),
      .B9   (AB[9]),
      .B10  (AB[10]),
      .B11  (AB[11]),
      .B12  (AB[12]),
      .B13  (AB[13]),
      .B14  (AB[14]),
      .DOB0 (DOB[0]),
      .DOB1 (DOB[1]),
      .DOB2 (DOB[2]),
      .DOB3 (DOB[3]),
      .DOB4 (DOB[4]),
      .DOB5 (DOB[5]),
      .DOB6 (DOB[6]),
      .DOB7 (DOB[7]),
      .DOB8 (DOB[8]),
      .DOB9 (DOB[9]),
      .DOB10(DOB[10]),
      .DOB11(DOB[11]),
      .DOB12(DOB[12]),
      .DOB13(DOB[13]),
      .DOB14(DOB[14]),
      .DOB15(DOB[15]),
      .DIB0 (DIB[0]),
      .DIB1 (DIB[1]),
      .DIB2 (DIB[2]),
      .DIB3 (DIB[3]),
      .DIB4 (DIB[4]),
      .DIB5 (DIB[5]),
      .DIB6 (DIB[6]),
      .DIB7 (DIB[7]),
      .DIB8 (DIB[8]),
      .DIB9 (DIB[9]),
      .DIB10(DIB[10]),
      .DIB11(DIB[11]),
      .DIB12(DIB[12]),
      .DIB13(DIB[13]),
      .DIB14(DIB[14]),
      .DIB15(DIB[15]),
      .CKB  (CKB),
      .WEBN (WEBN),
      .OEB  (OEB),
      .CSB  (CSB)
  );

endmodule