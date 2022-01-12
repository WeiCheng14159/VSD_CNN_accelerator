`timescale 1ns / 1ns
`define CYCLE 8.0 // Cycle time
`define MAX 300000000 // Max cycle number

`ifdef SYN
`include "conv_syn.v"
`include "InOut_SRAM/SUMA180_32768X16X1BM8.v"
`include "Weight_SRAM/SUMA180_16384X18X1BM4.v"
`include "Bias_SRAM/SUMA180_384X32X1BM4.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`elsif PR
`include "conv_pr.v"
`include "InOut_SRAM/SUMA180_32768X16X1BM8.v"
`include "Weight_SRAM/SUMA180_16384X18X1BM4.v"
`include "Bias_SRAM/SUMA180_384X32X1BM4.v"
`timescale 1ns / 10ps
`include "/usr/cad/CBDK/CBDK018_UMC_Faraday_v1.0/orig_lib/fsa0m_a/2009Q2v2.0/GENERIC_CORE/FrontEnd/verilog/fsa0m_a_generic_core_21.lib"
`else
`include "conv.sv"
`include "InOut_SRAM/SUMA180_32768X16X1BM8_rtl.sv"
`include "Weight_SRAM/SUMA180_16384X18X1BM4_rtl.sv"
`include "Bias_SRAM/SUMA180_384X32X1BM4_rtl.sv"
`endif

`include "InOut_SRAM/InOut_SRAM_384k.sv"  // Input SRAM or Output SRAM (384 KB)
`define INOUT_BLOCK_WORD_SIZE 32768
`include "Weight_SRAM/Weight_SRAM_180k.sv"  // Weight SRAM (180 KB)
`define WEIGHT_BLOCK_WORD_SIZE 16384
`include "Bias_SRAM/Bias_SRAM_2k.sv"  // Bias SRAM (2KB)
`include "Param_SRAM/Param_SRAM_16B.sv"  // Param SRAM (16B)
import conv_acc_pkg::*;

`timescale 1ns / 10ps

module top_tb;

  logic clk;
  logic rst;
  logic fin;
  logic start;
  conv_acc_mode_t conv_acc_mode;

  logic signed [7:0] GOLDEN[200000:0];
  logic [31:0] param[3:0];
  logic [31:0] in_data[200000:0];
  logic [31:0] w8[0:1];
  logic [31:0] w2[200000:0];
  logic [31:0] bias[200000:0];

  // GOLDEN
  logic signed [7:0] out;

  // Interface
  sp_ram_intf param_intf ();
  sp_ram_intf input_intf ();
  sp_ram_intf weight_intf ();
  sp_ram_intf output_intf ();
  sp_ram_intf bias_intf ();

  integer gf, i, num, slice;
  integer err, ret;
  string prog_path, layer, layer_num;
  always #(`CYCLE / 2) clk = ~clk;

  conv TOP (
      .rst(rst),
      .clk(clk),
      .w8(w8[0]),
      .start(start),
      .finish(fin),
      .mode(conv_acc_mode),
      .param_intf(param_intf),
      .bias_intf(bias_intf),
      .weight_intf(weight_intf),
      .input_intf(input_intf),
      .output_intf(output_intf)
  );

  Param_SRAM_16B param_mem (
      .clk(clk),
      .mem(param_intf)
  );

  InOut_SRAM_384k i_Input_SRAM_384k (
      .clk(clk),
      .mem(input_intf)
  );

  InOut_SRAM_384k i_Output_SRAM_384k (
      .clk(clk),
      .mem(output_intf)
  );

  Weight_SRAM_180k i_Weight_SRAM_180k (
      .clk(clk),
      .mem(weight_intf)
  );

  Bias_SRAM_2k i_Bias_SRAM_2k (
      .clk(clk),
      .mem(bias_intf)
  );

  initial begin
    clk   = 0;
    rst   = 1;
    start = 0;
    #1 rst = 0;
    #(`CYCLE) rst = 1;
    ret = $value$plusargs("prog_path=%s", prog_path);

    layer = prog_path.substr(prog_path.len()-5, prog_path.len()-2);
    layer_num = prog_path[prog_path.len()-1];
    if(layer == "conv") begin
      if (layer_num == "0" | layer_num == "3" | layer_num == "6") 
        conv_acc_mode = CONV_3x3_MODE;
      else
        conv_acc_mode = CONV_1x1_MODE;
    end else if(layer == "pool") begin
      if(layer_num == "0" | layer_num == "1" | layer_num == "2") 
        conv_acc_mode = MAX_POOL_MODE;
      else
        conv_acc_mode = IDLE_MODE;
    end else begin
      conv_acc_mode = IDLE_MODE; // Noting 
    end    

    // Parameter
    $readmemh({prog_path, "/param.hex"}, param);
    for (i = 0; i < 4; i = i + 1) begin
      param_mem.Memory[i] = param[i];
    end

    // Input data
    num = 0;
    slice = 0;
    gf = $fopen({prog_path, "/In8.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      if (num < `INOUT_BLOCK_WORD_SIZE) begin
        if (slice == 0)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[0].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );
        else if (slice == 1)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[1].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );
        else if (slice == 2)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[2].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );
        else if (slice == 3)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[3].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );
        else if (slice == 4)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[4].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );
        else if (slice == 5)
          ret = $fscanf(
              gf,
              "%h\n",
              i_Input_SRAM_384k.SRAM_blk[5].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[num]
          );

        num = num + 1;
      end else begin  // num == 32768
        slice = slice + 1;
        num   = 0;
      end
    end
    $fclose(gf);

    if(conv_acc_mode == CONV_1x1_MODE | conv_acc_mode == CONV_3x3_MODE) begin
      // Weight (8 bit)
      $readmemh({prog_path, "/W8.hex"}, w8);

      // Weight (2 bit)
      num = 0;
      slice = 0;
      gf = $fopen({prog_path, "/W2.hex"}, "r");
      while (!$feof(
          gf
      )) begin
        if (num < `WEIGHT_BLOCK_WORD_SIZE) begin
          if (slice == 0)
            ret = $fscanf(
                gf,
                "%h\n",
                i_Weight_SRAM_180k.SRAM_blk[0].i_SRAM_18b_16384w_36k.i_SUMA180_16384X18X1BM4.Memory[num]
            );
          else if (slice == 1)
            ret = $fscanf(
                gf,
                "%h\n",
                i_Weight_SRAM_180k.SRAM_blk[1].i_SRAM_18b_16384w_36k.i_SUMA180_16384X18X1BM4.Memory[num]
            );
          else if (slice == 2)
            ret = $fscanf(
                gf,
                "%h\n",
                i_Weight_SRAM_180k.SRAM_blk[2].i_SRAM_18b_16384w_36k.i_SUMA180_16384X18X1BM4.Memory[num]
            );
          else if (slice == 3)
            ret = $fscanf(
                gf,
                "%h\n",
                i_Weight_SRAM_180k.SRAM_blk[3].i_SRAM_18b_16384w_36k.i_SUMA180_16384X18X1BM4.Memory[num]
            );
          else if (slice == 4)
            ret = $fscanf(
                gf,
                "%h\n",
                i_Weight_SRAM_180k.SRAM_blk[4].i_SRAM_18b_16384w_36k.i_SUMA180_16384X18X1BM4.Memory[num]
            );

          num = num + 1;
        end else begin  // num == 32768
          slice = slice + 1;
          num   = 0;
        end
      end
      $fclose(gf);

      // Bias (32 bit)
      num = 0;
      gf  = $fopen({prog_path, "/Bias32.hex"}, "r");
      while (!$feof(
          gf
      )) begin
        ret = $fscanf(
            gf,
            "%h\n",
            i_Bias_SRAM_2k.i_SRAM_32b_384w_2k.i_SUMA180_384X32X1BM4.Memory[num]
        );
        num = num + 1;
      end
      $fclose(gf);
    end

    // Output (8 bit)
    num = 0;
    gf  = $fopen({prog_path, "/Out8.hex"}, "r");
    while (!$feof(
        gf
    )) begin
      ret = $fscanf(gf, "%h\n", GOLDEN[num]);
      num = num + 1;
    end
    $fclose(gf);
  end 

  initial begin
    #20 start = 1;
    #(`CYCLE) start = 0;
    wait (fin);
    #(`CYCLE * 2) #20 $display("\nDone\n");
    err = 0;
    num = 2000;  // Check first 2000 data by default
    check(0, num, err);
    result(err, num);
    $finish;
  end

  initial begin
    #(`CYCLE * `MAX)
    check(0, num, err);
    result(err, num);
    $display("SIM_END not finish!!!");
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
    $fsdbDumpvars(1, top_tb.param_intf);
    $fsdbDumpvars(1, top_tb.input_intf);
    $fsdbDumpvars(1, top_tb.weight_intf);
    $fsdbDumpvars(1, top_tb.output_intf);
    $fsdbDumpvars(1, top_tb.bias_intf);
`elsif FSDB_ALL
    $fsdbDumpfile(`FSDB_FILE);
    $fsdbDumpvars("+struct", "+mda", TOP);
    $fsdbDumpvars(1, top_tb.param_intf);
    $fsdbDumpvars(1, top_tb.input_intf);
    $fsdbDumpvars(1, top_tb.weight_intf);
    $fsdbDumpvars(1, top_tb.output_intf);
    $fsdbDumpvars(1, top_tb.bias_intf);
    // $fsdbDumpvars("+struct", "+mda", param_mem);
    // $fsdbDumpvars("+struct", "+mda", i_Input_SRAM_384k);
    // $fsdbDumpvars("+struct", "+mda", i_Output_SRAM_384k);
    // $fsdbDumpvars("+struct", "+mda", i_Weight_SRAM_180k);
    // $fsdbDumpvars("+struct", "+mda", i_Bias_SRAM_2k);
`endif
  end 

  task check (input integer word_begin, input integer word_end, output integer err_cnt);
    begin
      err_cnt = 0;
      for (i = word_begin; i < word_end; i = i + 1) begin
        slice = i / `INOUT_BLOCK_WORD_SIZE;
        if (slice == 0)
          out = i_Output_SRAM_384k.SRAM_blk[0].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];
        else if (slice == 1)
          out = i_Output_SRAM_384k.SRAM_blk[1].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];
        else if (slice == 2)
          out = i_Output_SRAM_384k.SRAM_blk[2].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];
        else if (slice == 3)
          out = i_Output_SRAM_384k.SRAM_blk[3].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];
        else if (slice == 4)
          out = i_Output_SRAM_384k.SRAM_blk[4].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];
        else if (slice == 5)
          out = i_Output_SRAM_384k.SRAM_blk[5].i_SRAM_16b_32768w_64k.i_SUMA180_32768X16X1BM8.Memory[i % `INOUT_BLOCK_WORD_SIZE][7:0];

        if (out === GOLDEN[i] | (out+1) === GOLDEN[i] | (out-1) === GOLDEN[i]) begin
          $display("DM[%4d] = %h, pass", i, out);
        end else begin
          $display("DM[%4d] = %h, expect = %h", i, out, GOLDEN[i]);
          err_cnt = err_cnt + 1;
        end
      end
    end
  endtask


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
