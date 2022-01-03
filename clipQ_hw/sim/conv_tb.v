`timescale 1ns / 10ps
`define CYCLE 8.0 // Cycle time
`define MAX 3000000 // Max cycle number

`ifdef SYN
`include "../dc/conv_syn.v"
`include "./bram_sim.v"
`include "./dual_bram.v"
`timescale 1ns / 10ps

`else
`include "../src/conv.v"
`include "./bram_sim.v"
`include "./dual_bram.v"
`endif

`timescale 1ns/10ps
`define FSDB_ALL 
module top_tb;

  reg clk;
  reg rst;
  wire fin;
  reg start;
  wire qst;
  reg [31:0] GOLDEN[200000:0];
  reg [31:0] param[3:0];
  reg [31:0] in_data[4096:0];
  reg [31:0] w1[1024:0];
  reg [31:0] w2[1024:0];
  reg [31:0] w3[1024:0];

  wire Mp_en;
  wire [31:0] Mp_addr;
  wire [31:0] Mp_R_data;
  wire [3:0] Mp_W_req;
  wire [31:0] Mp_W_data;

  wire Min_en;
  wire [31:0] Min_addr;
  wire [31:0] Min_R_data;
  wire [3:0] Min_W_req;
  wire [31:0] Min_W_data;

  wire Mout_en;
  wire [31:0] Mout_addr;
  wire [31:0] Mout_R_data;
  wire [3:0] Mout_W_req;
  wire [31:0] Mout_W_data;

  wire Mw_en;
  wire [31:0] Mw_addr;
  wire [31:0] Mw_R_data;
  wire [3:0] Mw_W_req;
  wire [31:0] Mw_W_data;

  wire Mb_en;
  wire [31:0] Mb_addr;
  wire [31:0] Mb_R_data;
  wire [3:0] Mb_W_req;
  wire [31:0] Mb_W_data;

  wire Mk0_p0_en;
  wire [31:0] Mk0_p0_addr;
  wire [31:0] Mk0_p0_R_data;
  wire [3:0] Mk0_p0_W_req;
  wire [31:0] Mk0_p0_W_data;

  wire Mk0_p1_en;
  wire [31:0] Mk0_p1_addr;
  wire [31:0] Mk0_p1_R_data;
  wire [3:0] Mk0_p1_W_req;
  wire [31:0] Mk0_p1_W_data;

  wire Mk1_p0_en;
  wire [31:0] Mk1_p0_addr;
  wire [31:0] Mk1_p0_R_data;
  wire [3:0] Mk1_p0_W_req;
  wire [31:0] Mk1_p0_W_data;

  wire Mk1_p1_en;
  wire [31:0] Mk1_p1_addr;
  wire [31:0] Mk1_p1_R_data;
  wire [3:0] Mk1_p1_W_req;
  wire [31:0] Mk1_p1_W_data;

  wire Mk2_p0_en;
  wire [31:0] Mk2_p0_addr;
  wire [31:0] Mk2_p0_R_data;
  wire [3:0] Mk2_p0_W_req;
  wire [31:0] Mk2_p0_W_data;

  wire Mk2_p1_en;
  wire [31:0] Mk2_p1_addr;
  wire [31:0] Mk2_p1_R_data;
  wire [3:0] Mk2_p1_W_req;
  wire [31:0] Mk2_p1_W_data;

  wire Mk3_p0_en;
  wire [31:0] Mk3_p0_addr;
  wire [31:0] Mk3_p0_R_data;
  wire [3:0] Mk3_p0_W_req;
  wire [31:0] Mk3_p0_W_data;

  wire Mk3_p1_en;
  wire [31:0] Mk3_p1_addr;
  wire [31:0] Mk3_p1_R_data;
  wire [3:0] Mk3_p1_W_req;
  wire [31:0] Mk3_p1_W_data;

  integer gf, i, num;
  integer img;
  wire [31:0] temp;
  integer err;
  always #(`CYCLE / 2) clk = ~clk;

  conv TOP (
      .rst(rst),
      .clk(clk),

      .Mp_en(Mp_en),
      .Mp_addr(Mp_addr),
      .Mp_R_data(Mp_R_data),
      .Mp_W_req(Mp_W_req),
      .Mp_W_data(Mp_W_data),

      .Min_en(Min_en),
      .Min_addr(Min_addr),
      .Min_R_data(Min_R_data),
      .Min_W_req(Min_W_req),
      .Min_W_data(Min_W_data),

      .Mout_en(Mout_en),
      .Mout_addr(Mout_addr),
      .Mout_R_data(Mout_R_data),
      .Mout_W_req(Mout_W_req),
      .Mout_W_data(Mout_W_data),

      .Mw_en(Mw_en),
      .Mw_addr(Mw_addr),
      .Mw_R_data(Mw_R_data),
      .Mw_W_req(Mw_W_req),
      .Mw_W_data(Mw_W_data),

      .Mb_en(Mb_en),
      .Mb_addr(Mb_addr),
      .Mb_R_data(Mb_R_data),
      .Mb_W_req(Mb_W_req),
      .Mb_W_data(Mb_W_data),

      .Mk0_p0_en(Mk0_p0_en),
      .Mk0_p0_addr(Mk0_p0_addr),
      .Mk0_p0_R_data(Mk0_p0_R_data),
      .Mk0_p0_W_req(Mk0_p0_W_req),
      .Mk0_p0_W_data(Mk0_p0_W_data),

      .Mk0_p1_en(Mk0_p1_en),
      .Mk0_p1_addr(Mk0_p1_addr),
      .Mk0_p1_R_data(Mk0_p1_R_data),
      .Mk0_p1_W_req(Mk0_p1_W_req),
      .Mk0_p1_W_data(Mk0_p1_W_data),

      .Mk1_p0_en(Mk1_p0_en),
      .Mk1_p0_addr(Mk1_p0_addr),
      .Mk1_p0_R_data(Mk1_p0_R_data),
      .Mk1_p0_W_req(Mk1_p0_W_req),
      .Mk1_p0_W_data(Mk1_p0_W_data),

      .Mk1_p1_en(Mk1_p1_en),
      .Mk1_p1_addr(Mk1_p1_addr),
      .Mk1_p1_R_data(Mk1_p1_R_data),
      .Mk1_p1_W_req(Mk1_p1_W_req),
      .Mk1_p1_W_data(Mk1_p1_W_data),

      .Mk2_p0_en(Mk2_p0_en),
      .Mk2_p0_addr(Mk2_p0_addr),
      .Mk2_p0_R_data(Mk2_p0_R_data),
      .Mk2_p0_W_req(Mk2_p0_W_req),
      .Mk2_p0_W_data(Mk2_p0_W_data),

      .Mk2_p1_en(Mk2_p1_en),
      .Mk2_p1_addr(Mk2_p1_addr),
      .Mk2_p1_R_data(Mk2_p1_R_data),
      .Mk2_p1_W_req(Mk2_p1_W_req),
      .Mk2_p1_W_data(Mk2_p1_W_data),

      .Mk3_p0_en(Mk3_p0_en),
      .Mk3_p0_addr(Mk3_p0_addr),
      .Mk3_p0_R_data(Mk3_p0_R_data),
      .Mk3_p0_W_req(Mk3_p0_W_req),
      .Mk3_p0_W_data(Mk3_p0_W_data),

      .Mk3_p1_en(Mk3_p1_en),
      .Mk3_p1_addr(Mk3_p1_addr),
      .Mk3_p1_R_data(Mk3_p1_R_data),
      .Mk3_p1_W_req(Mk3_p1_W_req),
      .Mk3_p1_W_data(Mk3_p1_W_data),

      .start (start),
      .finish(fin)
  );

  bram_sim b_param (
      .rst(rst),
      .clk(clk),

      .en(Mp_en),
      .addr(Mp_addr),
      .R_data(Mp_R_data),
      .W_req(Mp_W_req),
      .W_data(Mp_W_data)
  );

  bram_sim b_in (
      .rst(rst),
      .clk(clk),

      .en(Min_en),
      .addr(Min_addr),
      .R_data(Min_R_data),
      .W_req(Min_W_req),
      .W_data(Min_W_data)
  );

  bram_sim b_out (
      .rst(rst),
      .clk(clk),

      .en(Mout_en),
      .addr(Mout_addr),
      .R_data(Mout_R_data),
      .W_req(Mout_W_req),
      .W_data(Mout_W_data)
  );


  bram_sim b_w (
      .rst(rst),
      .clk(clk),

      .en(Mw_en),
      .addr(Mw_addr),
      .R_data(Mw_R_data),
      .W_req(Mw_W_req),
      .W_data(Mw_W_data)
  );

  bram_sim b_bias (
      .rst(rst),
      .clk(clk),

      .en(Mb_en),
      .addr(Mb_addr),
      .R_data(Mb_R_data),
      .W_req(Mb_W_req),
      .W_data(Mb_W_data)
  );

  dual_bram b_0_4k (
      .rst(rst),
      .clk(clk),

      .p0_en(Mk0_p0_en),
      .p0_addr(Mk0_p0_addr),
      .p0_R_data(Mk0_p0_R_data),
      .p0_W_req(Mk0_p0_W_req),
      .p0_W_data(Mk0_p0_W_data),

      .p1_en(Mk0_p1_en),
      .p1_addr(Mk0_p1_addr),
      .p1_R_data(Mk0_p1_R_data),
      .p1_W_req(Mk0_p1_W_req),
      .p1_W_data(Mk0_p1_W_data)
  );


  dual_bram b_1_4k (
      .rst(rst),
      .clk(clk),

      .p0_en(Mk1_p0_en),
      .p0_addr(Mk1_p0_addr),
      .p0_R_data(Mk1_p0_R_data),
      .p0_W_req(Mk1_p0_W_req),
      .p0_W_data(Mk1_p0_W_data),

      .p1_en(Mk1_p1_en),
      .p1_addr(Mk1_p1_addr),
      .p1_R_data(Mk1_p1_R_data),
      .p1_W_req(Mk1_p1_W_req),
      .p1_W_data(Mk1_p1_W_data)
  );

  dual_bram b_2_4k (
      .rst(rst),
      .clk(clk),

      .p0_en(Mk2_p0_en),
      .p0_addr(Mk2_p0_addr),
      .p0_R_data(Mk2_p0_R_data),
      .p0_W_req(Mk2_p0_W_req),
      .p0_W_data(Mk2_p0_W_data),

      .p1_en(Mk2_p1_en),
      .p1_addr(Mk2_p1_addr),
      .p1_R_data(Mk2_p1_R_data),
      .p1_W_req(Mk2_p1_W_req),
      .p1_W_data(Mk2_p1_W_data)
  );

  dual_bram b_3_4k (
      .rst(rst),
      .clk(clk),

      .p0_en(Mk3_p0_en),
      .p0_addr(Mk3_p0_addr),
      .p0_R_data(Mk3_p0_R_data),
      .p0_W_req(Mk3_p0_W_req),
      .p0_W_data(Mk3_p0_W_data),

      .p1_en(Mk3_p1_en),
      .p1_addr(Mk3_p1_addr),
      .p1_R_data(Mk3_p1_R_data),
      .p1_W_req(Mk3_p1_W_req),
      .p1_W_data(Mk3_p1_W_data)
  );

  initial begin
    clk   = 0;
    rst   = 1;
    start = 0;
    #1 rst = 0;
    #(`CYCLE) rst = 1;

    //write parameter
    $readmemh("../data/param.hex", param);
    for (i = 0; i < 4; i = i + 1) begin
      b_param.bram[i] = param[i];
    end

    //write in data 
    $readmemh("../data/In8.hex", in_data);
    for (i = 0; i < 1024; i = i + 1) begin
      b_in.bram[i] = in_data[i];
    end

    //write weight and bias
    $readmemh("../data/W8.hex", w1);
    b_w.bram[0] = w1[0];

    $readmemh("../data/W2.hex", w2);
    for (i = 0; i < 432; i = i + 1) begin
      b_w.bram[i+1] = w2[i];
    end

    $readmemh("../data/Bias32.hex", w3);
    for (i = 0; i < 192; i = i + 1) begin
      b_bias.bram[i] = w3[i];
    end

    num = 0;
    gf  = $fopen("../data/Out8.hex", "r");
    while (!$feof(
        gf
    )) begin
      $fscanf(gf, "%h \n", GOLDEN[num]);
      num = num + 1;
    end
    $fclose(gf);
    #20 start = 1;
    #(`CYCLE) start = 0;
    wait (fin);
    #(`CYCLE * 2) #20 $display("\nDone\n");
    err = 0;
    num = 2000;
    for (i = 0; i < num; i = i + 1) begin
      if(b_out.bram[i] !== GOLDEN[i] && b_out.bram[i] !== GOLDEN[i] + 256)begin
        $display("DM[%4d] = %h, expect = %h", i, b_out.bram[i], GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DM[%4d] = %h, pass", i, b_out.bram[i]);
      end
    end
    result(err, num);
    $finish;
  end

`ifdef SYN
  initial $sdf_annotate("../dc/conv_syn.sdf", TOP);
`elsif PR
  initial $sdf_annotate("top_pr.sdf", TOP);
`endif

  initial begin

`ifdef FSDB
`ifdef SYN
    $fsdbDumpfile("top_syn1.fsdb");
`else
    $fsdbDumpfile("top1.fsdb");
`endif
    $fsdbDumpvars(0, TOP);
`elsif FSDB_ALL
`ifdef SYN
    $fsdbDumpfile("top_syn1.fsdb");
`else
    $fsdbDumpfile("top1.fsdb");
`endif
    $fsdbDumpvars("+struct", "+mda", TOP);
`endif
    #(`CYCLE * `MAX)
      for (i = 0; i < 100; i = i + 1) begin
        if (b_out.bram[i] !== GOLDEN[i]) begin
          $display("DM[%4d] = %h, expect = %h", i, b_out.bram[i], GOLDEN[i]);
          err = err + 1;
        end else begin
          $display("DM[%4d] = %h, pass", i, b_out.bram[i]);
        end
      end
    $display("SIM_END no finish!!!");
    result(num, num);
    $finish;
  end

  task result;
    input integer err;
    input integer num;
    integer rf;
    begin
`ifdef SYN
      rf = $fopen({"./result_syn.txt"}, "w");
`elsif PR
      rf = $fopen({"./result_pr.txt"}, "w");
`else
      rf = $fopen({"./result_rtl.txt"}, "w");
`endif
      $fdisplay(rf, "%d,%d", num - err, num);
      if (err === 0) begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  Congratulations !!    **      / O.O  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
      end else begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  OOPS!!                **      / X,X  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("         Totally has %d errors                     ", err);
        $display("\n");
      end
    end
  endtask

endmodule


