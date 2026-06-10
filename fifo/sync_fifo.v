// Synchronous FIFO
// Author: Hariharan S
// Description: Parameterized Synchronous FIFO with full/empty flags

module sync_fifo #(
  parameter DATA_WIDTH = 8,
  parameter FIFO_DEPTH = 16
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire                  wr_en,
  input  wire                  rd_en,
  input  wire [DATA_WIDTH-1:0] wr_data,
  output reg  [DATA_WIDTH-1:0] rd_data,
  output wire                  full,
  output wire                  empty
);

  reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
  reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr, count;

  // Write logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) wr_ptr <= 0;
    else if (wr_en && !full) begin
      mem[wr_ptr] <= wr_data;
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rd_ptr <= 0;
    else if (rd_en && !empty) begin
      rd_data <= mem[rd_ptr];
      rd_ptr  <= rd_ptr + 1;
    end
  end

  // Count logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) count <= 0;
    else begin
      case ({wr_en & !full, rd_en & !empty})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count;
      endcase
    end
  end

  assign full  = (count == FIFO_DEPTH);
  assign empty = (count == 0);

endmodule
