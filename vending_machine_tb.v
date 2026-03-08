module testbench;

reg clk;
reg reset;
reg coin5;
reg coin10;

wire dispense;
wire change5;

vending_machine DUT(
    clk,
    reset,
    coin5,
    coin10,
    dispense,
    change5
);

initial
  begin
    clk=0;
    forever #5 clk=~clk;
  end

initial
begin
  $dumpfile("dump.vcd");
    $dumpvars(0,testbench);

  $monitor("time=%0t reset=%b coin5=%b coin10=%b dispense=%b change5=%b",$time, reset, coin5, coin10, dispense, change5);

    clk = 0;
    reset = 1;
    coin5 = 0;
    coin10 = 0;

    #10 reset = 0;

    #10 coin5 = 1;
    #10 coin5 = 0;

    #10 coin10 = 1;
    #10 coin10 = 0;

    #50 $finish;
end

endmodule
