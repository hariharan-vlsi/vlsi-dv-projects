// Synchronous FIFO Testbench
// Author: Hariharan S
// Description: Self-checking SV testbench for sync_fifo

`timescale 1ns/1ps

module sync_fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter FIFO_DEPTH = 16;

  reg                  clk, rst_n;
  reg                  wr_en, rd_en;
  reg  [DATA_WIDTH-1:0] wr_data;
  wire [DATA_WIDTH-1:0] rd_data;
  wire                  full, empty;

  // Instantiate DUT
  sync_fifo #(DATA_WIDTH, FIFO_DEPTH) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .rd_en(rd_en),
    .wr_data(wr_data), .rd_data(rd_data),
    .full(full), .empty(empty)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reference memory for self-checking
  reg [DATA_WIDTH-1:0] ref_mem [0:FIFO_DEPTH-1];
  integer wr_idx = 0, rd_idx = 0;
  integer pass = 0, fail = 0;

  task write_fifo(input [DATA_WIDTH-1:0] data);
    @(negedge clk);
    wr_en = 1; wr_data = data; rd_en = 0;
    if (!full) ref_mem[wr_idx % FIFO_DEPTH] = data;
    @(negedge clk);
    wr_en = 0;
    wr_idx++;
  endtask

  task read_and_check;
    @(negedge clk);
    rd_en = 1; wr_en = 0;
    @(negedge clk);
    rd_en = 0;
    if (rd_data === ref_mem[rd_idx % FIFO_DEPTH]) begin
      $display("PASS: rd_data = %0h (expected %0h)", rd_data, ref_mem[rd_idx % FIFO_DEPTH]);
      pass++;
    end else begin
      $display("FAIL: rd_data = %0h (expected %0h)", rd_data, ref_mem[rd_idx % FIFO_DEPTH]);
      fail++;
    end
    rd_idx++;
  endtask

  initial begin
    clk = 0; rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 0;
    #20 rst_n = 1;

    $display("---- Test 1: Normal Write/Read ----");
    write_fifo(8'hAA);
    write_fifo(8'hBB);
    write_fifo(8'hCC);
    read_and_check;
    read_and_check;
    read_and_check;

    $display("---- Test 2: Fill FIFO (Full Flag) ----");
    repeat(FIFO_DEPTH) write_fifo($random);
    $display("Full flag: %b (expected 1)", full);

    $display("---- Test 3: Empty FIFO (Empty Flag) ----");
    repeat(FIFO_DEPTH) read_and_check;
    $display("Empty flag: %b (expected 1)", empty);

    $display("---- Test 4: Overflow Protection ----");
    repeat(FIFO_DEPTH + 2) write_fifo($random);
    $display("Full flag after overflow: %b (expected 1)", full);

    $display("==========================");
    $display("TOTAL PASS: %0d | FAIL: %0d", pass, fail);
    $display("==========================");
    #20 $finish;
  end

endmodule
