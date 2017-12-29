
`timescale 1ns / 1ps

module pipeline_tb;
  reg clk;

  wire [31:0] inst_data_in;
  wire [31:0] inst_data_out;
  wire [31:0] inst_rd_addr;
  wire        inst_rd_en;
  wire [31:0] inst_wr_addr;
  wire        inst_wr_en;

  wire [31:0] data_data_in;
  wire [31:0] data_data_out;
  wire [31:0] data_rd_addr;
  wire        data_rd_en;
  wire [31:0] data_wr_addr;
  wire        data_wr_en;

  wire [31:0] debug1;
  wire [31:0] debug2;
  wire [31:0] debug3;
  wire [31:0] debug4;
  wire [31:0] debug5;
  wire [31:0] debug6;

  pipeline DUT_PIPELINE (
    .clock(clk),
    .inst_data(inst_data_in),
    .inst_rdaddress(inst_rd_addr),
    .inst_rden(inst_rd_en),
    .inst_wraddress(inst_wr_addr),
    .inst_wren(inst_wr_en),
    .inst_q(inst_data_out),
    .data_data(data_data_in),
    .data_rdaddress(data_rd_addr),
    .data_rden(data_rd_en),
    .data_wraddress(data_wr_addr),
    .data_wren(data_wr_en),
    .data_q(data_data_out),
    .debug1(debug1),
    .debug2(debug2),
    .debug3(debug3),
    .debug4(debug4),
    .debug5(debug5),
    .debug6(debug6)
  );

  defparam DUT_PIPELINE.WIDTH = 32;

  mem INST_MEM (
    .clock(clk),
    .data(inst_data_in),
    .rdaddress(inst_rd_addr),
    .rden(inst_rd_en),
    .wraddress(inst_wr_addr),
    .wren(inst_wr_en),
    .q(inst_data_out)
  );

  defparam INST_MEM.WIDTH = 32;
  defparam INST_MEM.DEPTH = 128;
  defparam INST_MEM.INIT = 1;

  mem DATA_MEM (
    .clock(clk),
    .data(data_data_in),
    .rdaddress(data_rd_addr),
    .rden(data_rd_en),
    .wraddress(data_wr_addr),
    .wren(data_wr_en),
    .q(data_data_out)
  );

  defparam DATA_MEM.WIDTH = 32;
  defparam DATA_MEM.DEPTH = 128;
  defparam DATA_MEM.INIT = 1;


  integer i;

  always
    begin

      #350;

      //for (i = 0; i < INST_MEM.DEPTH; i = i + 1)
      //begin
      //  $display("%b", INST_MEM.mem[i]);
      //end

      //for (i = 0; i < DATA_MEM.DEPTH; i = i + 1)
      //begin
      //  $display("%b", DATA_MEM.mem[i]);
      //end

      $finish;
    end

  initial
  begin
    DATA_MEM.mem[1] = 32'b00111111111111111111111111111111;
    DATA_MEM.mem[2] = 32'b00000000000000000000000000000001;
    DATA_MEM.mem[3] = 32'b00000000000000000000000000000010;

    INST_MEM.mem[0]  = 32'b00000000001100000010001000000011; // lw r4 3(r0)
    INST_MEM.mem[1]  = 32'b00000000000000000100011011100011; // blt r0 r0 [PC+2060]
    INST_MEM.mem[2]  = 32'b00000000000100001100011011100011; // blt r1 r1 [PC+2060]
    INST_MEM.mem[3]  = 32'b00000000001000000010000110000011; // lw r3 2(r0)
    INST_MEM.mem[4]  = 32'b00000000000100000010000010000011; // lw r1 1(r0)
    INST_MEM.mem[5]  = 32'b00000000000100011000000100110011; // add r2 r3 r1
    INST_MEM.mem[6]  = 32'b00000000100000011001001010010011; // slti r5 r3 8
    INST_MEM.mem[7]  = 32'b00000000001100100010001010110011; // slt r5 r4 r3
    INST_MEM.mem[8]  = 32'b00000000010000000000001100110011; // add r6 r0 r4
    INST_MEM.mem[9]  = 32'b00000000000100110000000010010011; // addi r1 r6 1
    INST_MEM.mem[10] = 32'b00000000000100000010000010100011; // sw r1 1(r0)
    INST_MEM.mem[11] = 32'b01000000001100100000001100110011; // sub r6 r4 r3
    INST_MEM.mem[12] = 32'b00000000001000000010000100100011; // sw r2 2(r0)
    INST_MEM.mem[13] = 32'b00000000010100000010000110100011; // sw r5 3(r0)
    INST_MEM.mem[14] = 32'b11111110001100110000100111100011; // beq r6 r3 [PC-14]
    INST_MEM.mem[15] = 32'b00000000001000001000000100010011; // addi r2 r1 2
  end


  initial
  begin
    $monitor("time=%3d\npc=%4d\n\nME_buf=%b\nEX_buf=%b\nID_buf=%b\nIF_buf=%b\ninst_q=%b\n\nin_prog=%b\nb_stall=%1b\nd_stall=%1b\nIF_en=%1b\nME_en=%1b\n\nregs[6]=%b\nregs[5]=%b\nregs[4]=%b\nregs[3]=%b\nregs[2]=%b\nregs[1]=%b\n\nmem[3]=%b\nmem[2]=%b\nmem[1]=%b\n\n==============================\n", $time,DUT_PIPELINE.pc,DUT_PIPELINE.MEM_buf,DUT_PIPELINE.EX_buf,DUT_PIPELINE.ID_buf,DUT_PIPELINE.IF_buf,DUT_PIPELINE.inst_q,DUT_PIPELINE.in_progress,DUT_PIPELINE.branch_stall,DUT_PIPELINE.data_stall,DUT_PIPELINE.IF_buf_en,DUT_PIPELINE.inst_rden,debug1,debug2,debug3,debug4,debug5,debug6,DATA_MEM.mem[3],DATA_MEM.mem[2],DATA_MEM.mem[1]);
    //$monitor("time = %2d, debug1=%1b, debug2=%1b, debug3=%1b, debug4=%1b, debug5=%1b, debug6=%1b", $time,debug1,debug2,debug3,debug4,debug5,debug6);
  end
 
  always
    begin
      clk = 1'b1;
      #5;
      clk = 1'b0;
      #5;
    end
   
endmodule
