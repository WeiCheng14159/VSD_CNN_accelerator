`timescale 1ns / 10ps
`define CYCLE 8.0 // Cycle time
`define MAX 3000000 // Max cycle number

`ifdef SYN
`include "conv_syn.v"
`include "sp_ram_sim.sv"
`include "dp_ram_sim.sv"
`include "SRAM/SRAM.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`elsif PR
`include "conv_pr.v"
`include "sp_ram_sim.sv"
`include "dp_ram_sim.sv"
`include "SRAM/SRAM.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`else
`include "conv.sv"
`include "sp_ram_sim.sv"
`include "dp_ram_sim.sv"
`include "SRAM/SRAM_rtl.sv"
`endif

`timescale 1ns / 10ps

module top_tb;

  logic clk;
  logic rst;
  logic fin;
  logic start;

  logic [7:0] GOLDEN[200000:0];
  logic [31:0] param[3:0];
  logic [31:0] in_data[200000:0];
  logic [31:0] w8[0:1];
  logic [31:0] w2[200000:0];
  logic [31:0] bias[200000:0];

  // GOLDEN
  logic [7:0] out;

  // Interface
  sp_ram_intf param_intf ();
  sp_ram_intf input_intf ();
  sp_ram_intf output_intf ();
  sp_ram_intf weight_intf ();
  sp_ram_intf bias_intf ();

  integer gf, i, num;
  integer err;
  string  prog_path;
  always #(`CYCLE / 2) clk = ~clk;

  conv TOP (
      .rst(rst),
      .clk(clk),

      .param_en(param_intf.en),
      .param_addr(param_intf.addr),
      .param_rdata(param_intf.R_data),
      .param_write(param_intf.W_req),
      .param_wdata(param_intf.W_data),

      .bias_en(bias_intf.en),
      .bias_addr(bias_intf.addr),
      .bias_rdata(bias_intf.R_data),
      .bias_write(bias_intf.W_req),
      .bias_wdata(bias_intf.W_data),

      .weight_en(weight_intf.en),
      .weight_addr(weight_intf.addr),
      .weight_rdata(weight_intf.R_data[17:0]),
      .weight_write(weight_intf.W_req),
      .weight_wdata(weight_intf.W_data[17:0]),

      .input_en(input_intf.en),
      .input_addr(input_intf.addr),
      .input_rdata(input_intf.R_data[15:0]),
      .input_write(input_intf.W_req),
      .input_wdata(input_intf.W_data[15:0]),

      .output_en(output_intf.en),
      .output_addr(output_intf.addr),
      .output_rdata(output_intf.R_data[15:0]),
      .output_write(output_intf.W_req),
      .output_wdata(output_intf.W_data[15:0]),

      .w8(w8[0]),

      .start (start),
      .finish(fin)
  );

  sp_ram_sim param_mem (
      .rst (rst),
      .clk (clk),
      .intf(param_intf)
  );

  sp_ram_sim input_mem (
      .rst (rst),
      .clk (clk),
      .intf(input_intf)
  );

  sp_ram_sim output_mem (
      .rst (rst),
      .clk (clk),
      .intf(output_intf)
  );

  sp_ram_sim weight_mem (
      .rst (rst),
      .clk (clk),
      .intf(weight_intf)
  );

  sp_ram_sim bias_mem (
      .rst (rst),
      .clk (clk),
      .intf(bias_intf)
  );

  initial begin
    clk   = 0;
    rst   = 1;
    start = 0;
    #1 rst = 0;
    #(`CYCLE) rst = 1;
    $value$plusargs("prog_path=%s", prog_path);

    // Parameter
    $readmemh({prog_path, "/param.hex"}, param);
    for (i = 0; i < 4; i = i + 1) begin
      param_mem.content[i] = param[i];
    end

    // Input data
    num = 0;
    gf  = $fopen({prog_path, "/In8.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      $fscanf(gf, "%h\n", input_mem.content[num]);
      num = num + 1;
    end
    $fclose(gf);

    // Weight (8 bit)
    $readmemh({prog_path, "/W8.hex"}, w8);

    // Weight (2 bit)
    num = 0;
    gf  = $fopen({prog_path, "/W2.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      $fscanf(gf, "%h\n", weight_mem.content[num]);
      num = num + 1;
    end
    $fclose(gf);

    // Bias (32 bit)
    num = 0;
    gf  = $fopen({prog_path, "/Bias32.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      $fscanf(gf, "%h\n", bias_mem.content[num]);
      num = num + 1;
    end
    $fclose(gf);

    // Output (8 bit)
    num = 0;
    gf  = $fopen({prog_path, "/Out8.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      $fscanf(gf, "%h\n", GOLDEN[num]);
      num = num + 1;
    end
    $fclose(gf);

    #20 start = 1;
    #(`CYCLE) start = 0;
    wait (fin);
    #(`CYCLE * 2) #20 $display("\nDone\n");
    err = 0;
    num = 2000;  // Check first 2000 data by default
    for (i = 0; i < num; i = i + 1) begin
      out = output_mem.content[i][7:0];
      if (out !== GOLDEN[i]) begin
        $display("DM[%4d] = %h, expect = %h", i, out, GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DM[%4d] = %h, pass", i, out);
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
`endif
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
