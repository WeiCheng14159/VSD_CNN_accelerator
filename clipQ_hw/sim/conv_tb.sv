`timescale 1ns / 10ps
`define CYCLE 8.0 // Cycle time
`define MAX 3000000 // Max cycle number

`ifdef SYN
`include "conv_syn.v"
`include "bram_sim.sv"
`include "dual_bram.sv"
`include "SRAM/SRAM.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`elsif PR
`include "conv_pr.v"
`include "bram_sim.sv"
`include "dual_bram.sv"
`include "SRAM/SRAM.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`else
`include "conv.sv"
`include "bram_sim.sv"
`include "dual_bram.sv"
`include "SRAM/SRAM_rtl.sv"
`endif

`include "bram_intf.sv"
`timescale 1ns / 10ps

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

  // Interface
  bram_intf param_intf ();
  bram_intf input_intf ();
  bram_intf output_intf ();
  bram_intf weight_intf ();
  bram_intf bias_intf ();
  bram_intf k0_p0_intf ();
  bram_intf k0_p1_intf ();
  bram_intf k1_p0_intf ();
  bram_intf k1_p1_intf ();
  bram_intf k2_p0_intf ();
  bram_intf k2_p1_intf ();
  bram_intf k3_p0_intf ();
  bram_intf k3_p1_intf ();

  integer gf, i, num;
  integer img;
  wire [31:0] temp;
  integer err;
  always #(`CYCLE / 2) clk = ~clk;

  conv TOP (
      .rst(rst),
      .clk(clk),

      .Mp_en(param_intf.en),
      .Mp_addr(param_intf.addr),
      .Mp_R_data(param_intf.R_data),
      .Mp_W_req(param_intf.W_req),
      .Mp_W_data(param_intf.W_data),

      .Min_en(input_intf.en),
      .Min_addr(input_intf.addr),
      .Min_R_data(input_intf.R_data),
      .Min_W_req(input_intf.W_req),
      .Min_W_data(input_intf.W_data),

      .Mout_en(output_intf.en),
      .Mout_addr(output_intf.addr),
      .Mout_R_data(output_intf.R_data),
      .Mout_W_req(output_intf.W_req),
      .Mout_W_data(output_intf.W_data),

      .Mw_en(weight_intf.en),
      .Mw_addr(weight_intf.addr),
      .Mw_R_data(weight_intf.R_data),
      .Mw_W_req(weight_intf.W_req),
      .Mw_W_data(weight_intf.W_data),

      .Mb_en(bias_intf.en),
      .Mb_addr(bias_intf.addr),
      .Mb_R_data(bias_intf.R_data),
      .Mb_W_req(bias_intf.W_req),
      .Mb_W_data(bias_intf.W_data),

      .Mk0_p0_en(k0_p0_intf.en),
      .Mk0_p0_addr(k0_p0_intf.addr),
      .Mk0_p0_R_data(k0_p0_intf.R_data),
      .Mk0_p0_W_req(k0_p0_intf.W_req),
      .Mk0_p0_W_data(k0_p0_intf.W_data),

      .Mk0_p1_en(k0_p1_intf.en),
      .Mk0_p1_addr(k0_p1_intf.addr),
      .Mk0_p1_R_data(k0_p1_intf.R_data),
      .Mk0_p1_W_req(k0_p1_intf.W_req),
      .Mk0_p1_W_data(k0_p1_intf.W_data),

      .Mk1_p0_en(k1_p0_intf.en),
      .Mk1_p0_addr(k1_p0_intf.addr),
      .Mk1_p0_R_data(k1_p0_intf.R_data),
      .Mk1_p0_W_req(k1_p0_intf.W_req),
      .Mk1_p0_W_data(k1_p0_intf.W_data),

      .Mk1_p1_en(k1_p1_intf.en),
      .Mk1_p1_addr(k1_p1_intf.addr),
      .Mk1_p1_R_data(k1_p1_intf.R_data),
      .Mk1_p1_W_req(k1_p1_intf.W_req),
      .Mk1_p1_W_data(k1_p1_intf.W_data),

      .Mk2_p0_en(k2_p0_intf.en),
      .Mk2_p0_addr(k2_p0_intf.addr),
      .Mk2_p0_R_data(k2_p0_intf.R_data),
      .Mk2_p0_W_req(k2_p0_intf.W_req),
      .Mk2_p0_W_data(k2_p0_intf.W_data),

      .Mk2_p1_en(k2_p1_intf.en),
      .Mk2_p1_addr(k2_p1_intf.addr),
      .Mk2_p1_R_data(k2_p1_intf.R_data),
      .Mk2_p1_W_req(k2_p1_intf.W_req),
      .Mk2_p1_W_data(k2_p1_intf.W_data),

      .Mk3_p0_en(k3_p0_intf.en),
      .Mk3_p0_addr(k3_p0_intf.addr),
      .Mk3_p0_R_data(k3_p0_intf.R_data),
      .Mk3_p0_W_req(k3_p0_intf.W_req),
      .Mk3_p0_W_data(k3_p0_intf.W_data),

      .Mk3_p1_en(k3_p1_intf.en),
      .Mk3_p1_addr(k3_p1_intf.addr),
      .Mk3_p1_R_data(k3_p1_intf.R_data),
      .Mk3_p1_W_req(k3_p1_intf.W_req),
      .Mk3_p1_W_data(k3_p1_intf.W_data),

      .start (start),
      .finish(fin)
  );

  bram_sim b_param (
      .rst (rst),
      .clk (clk),
      .intf(param_intf)
  );


  bram_sim b_in (
      .rst (rst),
      .clk (clk),
      .intf(input_intf)
  );

  bram_sim b_out (
      .rst (rst),
      .clk (clk),
      .intf(output_intf)
  );


  bram_sim b_w (
      .rst (rst),
      .clk (clk),
      .intf(weight_intf)
  );

  bram_sim b_bias (
      .rst (rst),
      .clk (clk),
      .intf(bias_intf)
  );



  dual_bram b_0_4k (
      .rst(rst),
      .clk(clk),
      .p0_intf(k0_p0_intf),
      .p1_intf(k0_p1_intf)
  );


  dual_bram b_1_4k (
      .rst(rst),
      .clk(clk),
      .p0_intf(k1_p0_intf),
      .p1_intf(k1_p1_intf)
  );

  dual_bram b_2_4k (
      .rst(rst),
      .clk(clk),
      .p0_intf(k2_p0_intf),
      .p1_intf(k2_p1_intf)
  );

  dual_bram b_3_4k (
      .rst(rst),
      .clk(clk),
      .p0_intf(k3_p0_intf),
      .p1_intf(k3_p1_intf)
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
      b_param.content[i] = param[i];
    end

    //write input data 
    $readmemh("../data/In8.hex", in_data);
    for (i = 0; i < 1024; i = i + 1) begin
      b_in.content[i] = in_data[i];
    end

    //write weight
    $readmemh("../data/W8.hex", w1);
    b_w.content[0] = w1[0];

    $readmemh("../data/W2.hex", w2);
    for (i = 0; i < 432; i = i + 1) begin
      b_w.content[i+1] = w2[i];
    end

    // write bias
    $readmemh("../data/Bias32.hex", w3);
    for (i = 0; i < 192; i = i + 1) begin
      b_bias.content[i] = w3[i];
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
      if(b_out.content[i] !== GOLDEN[i] && b_out.content[i] !== GOLDEN[i] + 256)begin
        $display("DM[%4d] = %h, expect = %h", i, b_out.content[i], GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DM[%4d] = %h, pass", i, b_out.content[i]);
      end
    end
    result(err, num);
    $finish;
  end

`ifdef SYN
  initial $sdf_annotate("conv_syn.sdf", TOP);
`elsif PR
  initial $sdf_annotate("conv_pr.sdf", TOP);
`endif

  initial begin

`ifdef FSDB
    $fsdbDumpfile(`FSDB_FILE);
    $fsdbDumpvars();
`elsif FSDB_ALL
    $fsdbDumpfile(`FSDB_FILE);
    $fsdbDumpvars("+struct", "+mda", TOP);
`else

`endif
    #(`CYCLE * `MAX)
      for (i = 0; i < 100; i = i + 1) begin
        if (b_out.content[i] !== GOLDEN[i]) begin
          $display("DM[%4d] = %h, expect = %h", i, b_out.content[i], GOLDEN[i]);
          err = err + 1;
        end else begin
          $display("DM[%4d] = %h, pass", i, b_out.content[i]);
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
