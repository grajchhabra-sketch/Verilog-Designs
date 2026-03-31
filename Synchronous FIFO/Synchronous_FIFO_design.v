module fifo(
  input clk,
  input reset,
  input write_en,
  input read_en,
  input [7:0] data_in,
  output reg [7:0] data_out,
  output full,
  output empty
);

  parameter DEPTH = 8;
  parameter ADDR_WIDTH = 3;

  reg [7:0] mem [0:DEPTH-1];

  reg [ADDR_WIDTH-1:0] write_ptr;
  reg [ADDR_WIDTH-1:0] read_ptr;

  reg [ADDR_WIDTH:0] count;  // 0 to DEPTH

  assign full  = (count == DEPTH);
  assign empty = (count == 0);

  wire write_valid = write_en && (count < DEPTH);
  wire read_valid  = read_en  && (count > 0);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      write_ptr <= 0;
    end
    else if (write_valid) begin
      mem[write_ptr] <= data_in;
      write_ptr <= (write_ptr == DEPTH-1) ? 0 : write_ptr + 1;
    end
  end

  
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      read_ptr <= 0;
      data_out <= 0;
    end
    else if (read_valid) begin
      data_out <= mem[read_ptr];
      read_ptr <= (read_ptr == DEPTH-1) ? 0 : read_ptr + 1;
    end
  end


  always @(posedge clk or posedge reset) begin
    if (reset) begin
      count <= 0;
    end
    else begin
      case ({write_valid, read_valid})
        2'b10: count <= count + 1; // write only
        2'b01: count <= count - 1; // read only
        2'b11: count <= count;     // both
        2'b00: count <= count;
      endcase
    end
  end

endmodule
