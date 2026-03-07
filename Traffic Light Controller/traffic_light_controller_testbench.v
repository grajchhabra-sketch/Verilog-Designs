module tb;

reg clk;
reg reset;

wire NS_G, NS_Y, NS_R;
wire EW_G, EW_Y, EW_R;

traffic_light_controller DUT(
    clk, reset,
    NS_G, NS_Y, NS_R,
    EW_G, EW_Y, EW_R
);

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end


initial
begin

$monitor("time=%0t NS[G Y R]=%b %b %b  EW[G Y R]=%b %b %b",
$time,NS_G,NS_Y,NS_R,EW_G,EW_Y,EW_R);

reset = 1;
#10;

reset = 0;

#100;

$finish;

end

endmodule
