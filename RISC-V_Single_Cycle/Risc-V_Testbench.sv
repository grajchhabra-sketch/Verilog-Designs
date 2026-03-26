`timescale 1ns / 1ps
module testbench;

logic clk;
logic reset;

logic [31:0] pc;
logic [31:0] instruction;
logic [31:0] alu_result;
logic [31:0] mem_data;


// DUT
riscv_top DUT(
.clk(clk),
.reset(reset),
.pc(pc),
.instruction(instruction),
.alu_result(alu_result),
.mem_data(mem_data)
);


// clock generation
always #5 clk = ~clk;


// reset and run
initial begin

clk = 0;
reset = 1;

#10;
reset = 0;

#200;

$finish;

end


// monitor
initial begin

$monitor(
"time=%0t clk=%b reset=%b pc=%0d instr=%h alu=%0d mem=%0d",
$time,
clk,
reset,
pc,
instruction,
alu_result,
mem_data
);

end

endmodule

