`timescale 1ns/1ps

module uart_tb;


reg clk;
reg reset;
reg start;
reg [7:0] data_in;

wire tx;
wire busy;



uart_top DUT (
    .clk(clk),
    .reset(reset),
    .start(start),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
);



always #5 clk = ~clk;


initial
begin
   
    clk = 0;
    reset = 1;
    start = 0;
    data_in = 8'b00000000;

   
    $monitor("time=%0t reset=%b start=%b data=%b tx=%b busy=%b",
              $time, reset, start, data_in, tx, busy);


    #20 reset = 0;


    #20 data_in = 8'b10110011;
        start = 1;

    #10 start = 0;

    #2000;

    data_in = 8'b11001100;
    start = 1;

    #10 start = 0;

    #2000;
    $finish;

end

endmodule
