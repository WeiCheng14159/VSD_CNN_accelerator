module SJMA180_32768X16X1BM8 (A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,
                              B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10,B11,B12,B13,B14,
                              DOA0,DOA1,DOA2,DOA3,DOA4,DOA5,DOA6,DOA7,
                              DOA8,DOA9,DOA10,DOA11,DOA12,DOA13,DOA14,DOA15,
                              DOB0,DOB1,DOB2,DOB3,DOB4,DOB5,DOB6,
                              DOB7,DOB8,DOB9,DOB10,DOB11,DOB12,DOB13,
                              DOB14,DOB15,
                              DIA0,DIA1,DIA2,DIA3,DIA4, DIA5,DIA6,DIA7,DIA8,DIA9,DIA10,DIA11,DIA12,
                              DIA13,DIA14,DIA15,
                              DIB0,DIB1,DIB2,DIB3,DIB4,DIB5,DIB6,DIB7,DIB8,DIB9,DIB10,DIB11,
                              DIB12,DIB13,DIB14,DIB15,
                              WEAN,WEBN,CKA,CKB,CSA,CSB,OEA,OEB);

  // Port A
  output     DOA0,DOA1,DOA2,DOA3,DOA4,DOA5,DOA6,DOA7,
              DOA8,DOA9,DOA10,DOA11,DOA12,DOA13,DOA14,DOA15;
  input      DIA0,DIA1,DIA2,DIA3,DIA4, DIA5,DIA6,DIA7,DIA8,DIA9,DIA10,DIA11,DIA12,
              DIA13,DIA14,DIA15;
  input      A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14;
  input      WEAN;                                  
  input      CKA;                                      
  input      CSA;                                      
  input      OEA;       
  // Port B    
  output    DOB0,DOB1,DOB2,DOB3,DOB4,DOB5,DOB6,
            DOB7,DOB8,DOB9,DOB10,DOB11,DOB12,DOB13,
            DOB14,DOB15;
  input       DIB0,DIB1,DIB2,DIB3,DIB4,DIB5,DIB6,DIB7,DIB8,DIB9,DIB10,DIB11,
              DIB12,DIB13,DIB14,DIB15;
  input      B0,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10,B11,B12,B13,B14;
  input      WEBN;                                  
  input      CKB;                                      
  input      CSB;                                      
  input      OEB;
                                
  parameter  AddressSize          = 15;               
  parameter  Bits                 = 16;                
  parameter  Words                = 32768;            
  parameter  Bytes                = 1;              
  
  logic      [Bits-1:0]           Memory [Words-1:0];     
  // Port A
  logic      [Bytes*Bits-1:0]     DIA;                
  logic      [Bytes*Bits-1:0]     DOA;                
  logic      [Bytes*Bits-1:0]     latched_DOA;                
  logic      [AddressSize-1:0]    AA;
  // Port B
  logic      [Bytes*Bits-1:0]     DIB;                
  logic      [Bytes*Bits-1:0]     DOB;                
  logic      [Bytes*Bits-1:0]     latched_DOB;                
  logic      [AddressSize-1:0]    AB;
                 
  assign     DOA0                  = DOA[0];
  assign     DOA1                  = DOA[1];
  assign     DOA2                  = DOA[2];
  assign     DOA3                  = DOA[3];
  assign     DOA4                  = DOA[4];
  assign     DOA5                  = DOA[5];
  assign     DOA6                  = DOA[6];
  assign     DOA7                  = DOA[7];
  assign     DOA8                  = DOA[8];
  assign     DOA9                  = DOA[9];
  assign     DOA10                 = DOA[10];
  assign     DOA11                 = DOA[11];
  assign     DOA12                 = DOA[12];
  assign     DOA13                 = DOA[13];
  assign     DOA14                 = DOA[14];
  assign     DOA15                 = DOA[15];

  assign     DIA[0]                = DIA0;
  assign     DIA[1]                = DIA1;
  assign     DIA[2]                = DIA2;
  assign     DIA[3]                = DIA3;
  assign     DIA[4]                = DIA4;
  assign     DIA[5]                = DIA5;
  assign     DIA[6]                = DIA6;
  assign     DIA[7]                = DIA7;
  assign     DIA[8]                = DIA8;
  assign     DIA[9]                = DIA9;
  assign     DIA[10]               = DIA10;
  assign     DIA[11]               = DIA11;
  assign     DIA[12]               = DIA12;
  assign     DIA[13]               = DIA13;
  assign     DIA[14]               = DIA14;
  assign     DIA[15]               = DIA15;

  assign     AA[0]                 = A0;
  assign     AA[1]                 = A1;
  assign     AA[2]                 = A2;
  assign     AA[3]                 = A3;
  assign     AA[4]                 = A4;
  assign     AA[5]                 = A5;
  assign     AA[6]                 = A6;
  assign     AA[7]                 = A7;
  assign     AA[8]                 = A8;
  assign     AA[9]                 = A9;
  assign     AA[10]                = A10;
  assign     AA[11]                = A11;
  assign     AA[12]                = A12;
  assign     AA[13]                = A13;
  assign     AA[14]                = A14;

  // Port B
  assign     DOB0                  = DOB[0];
  assign     DOB1                  = DOB[1];
  assign     DOB2                  = DOB[2];
  assign     DOB3                  = DOB[3];
  assign     DOB4                  = DOB[4];
  assign     DOB5                  = DOB[5];
  assign     DOB6                  = DOB[6];
  assign     DOB7                  = DOB[7];
  assign     DOB8                  = DOB[8];
  assign     DOB9                  = DOB[9];
  assign     DOB10                 = DOB[10];
  assign     DOB11                 = DOB[11];
  assign     DOB12                 = DOB[12];
  assign     DOB13                 = DOB[13];
  assign     DOB14                 = DOB[14];
  assign     DOB15                 = DOB[15];

  assign     DIB[0]                = DIB0;
  assign     DIB[1]                = DIB1;
  assign     DIB[2]                = DIB2;
  assign     DIB[3]                = DIB3;
  assign     DIB[4]                = DIB4;
  assign     DIB[5]                = DIB5;
  assign     DIB[6]                = DIB6;
  assign     DIB[7]                = DIB7;
  assign     DIB[8]                = DIB8;
  assign     DIB[9]                = DIB9;
  assign     DIB[10]               = DIB10;
  assign     DIB[11]               = DIB11;
  assign     DIB[12]               = DIB12;
  assign     DIB[13]               = DIB13;
  assign     DIB[14]               = DIB14;
  assign     DIB[15]               = DIB15;

  assign     AB[0]                 = B0;
  assign     AB[1]                 = B1;
  assign     AB[2]                 = B2;
  assign     AB[3]                 = B3;
  assign     AB[4]                 = B4;
  assign     AB[5]                 = B5;
  assign     AB[6]                 = B6;
  assign     AB[7]                 = B7;
  assign     AB[8]                 = B8;
  assign     AB[9]                 = B9;
  assign     AB[10]                = B10;
  assign     AB[11]                = B11;
  assign     AB[12]                = B12;
  assign     AB[13]                = B13;
  assign     AB[14]                = B14;
  
  always_ff @(posedge CKA)
  begin
    if(AA != AB) begin // Port A/B address no conflict
      if (CSA && ~WEAN)
        Memory[AA] <= DIA;
      if(CSB && ~WEBN)
        Memory[AB] <= DIB;
    end else begin // Port A/B address conflict (Only port A writes)
      if (CSA && ~WEAN)
        Memory[AA] <= DIA;
    end
  end

  always_ff @(posedge CKA) begin
    if (CSA) begin
      if(~WEAN) latched_DOA <= DIA;
      else      latched_DOA <= Memory[AA]; 
    end
  end

  always_ff @(posedge CKB) begin
    if (CSB) begin
      if(~WEBN) latched_DOB <= DIB;
      else      latched_DOB <= Memory[AB]; 
    end
  end

  always_comb begin
    DOA = (OEA)? latched_DOA: {(Bytes*Bits){1'bz}};
    DOB = (OEB)? latched_DOB: {(Bytes*Bits){1'bz}};
  end

endmodule
