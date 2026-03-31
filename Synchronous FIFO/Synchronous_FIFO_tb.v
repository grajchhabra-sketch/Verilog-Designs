 `timescale 1ns/1ps

module testbench;

reg clk;
reg reset;
reg write_en;
reg read_en;
reg [7:0] data_in;

wire [7:0] data_out;
wire full;
wire empty;


// DUT

fifo uut (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .read_en(read_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);


// clock generation

always #5 clk = ~clk;


// test

initial
begin

    clk = 0;
    reset = 1;
    write_en = 0;
    read_en = 0;
    data_in = 0;

    #10 reset = 0;


    // WRITE DATA

    #10 write_en = 1; data_in = 8'd10;
    #10 data_in = 8'd20;
    #10 data_in = 8'd30;
    #10 data_in = 8'd40;
    #10 data_in = 8'd50;
    #10 data_in = 8'd60;
    #10 data_in = 8'd70;
    #10 data_in = 8'd80;

    #10 write_en = 0;


    // READ DATA

    #10 read_en = 1;
    #80 read_en = 0;


    #20 $finish;

end


// monitor

initial
begin
  
  $dumpfile("dump.vcd");
  $dumpvars(0,testbench);
    $monitor("time=%0t write=%b read=%b data_in=%d data_out=%d full=%b empty=%b",
              $time, write_en, read_en, data_in, data_out, full, empty);
end


endmodule
