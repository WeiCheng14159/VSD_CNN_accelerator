module CG (
    input  CK,
    input  EN,
    output CKEN
);

  logic en_latch;

  always_latch begin
    if (~CK) en_latch <= EN;
  end

  assign CKEN = CK & en_latch;

endmodule
