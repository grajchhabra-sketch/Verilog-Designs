`timescale 1ns / 1ps
// PC MODULE

module pc(input clk, input reset, input [31:0]pc_next, output reg [31:0]pc);
  always@(posedge clk or posedge reset)
    begin
      if(reset)
        pc <=0;
      else
        pc <=pc_next;
    end
endmodule

// PC ADDER

module pc_adder(input [31:0]pc ,output [31:0]pc_next);
  assign pc_next=pc+4;
endmodule

// INSTRUCTION MEMORY
module instruction_memory(
input [31:0] adder,
output [31:0] instruction
);

reg [31:0] mem [0:255];

integer i;

initial begin

// clear memory
for(i=0;i<256;i=i+1)
    mem[i] = 32'h00000013; // NOP

// program
mem[0] = 32'h00000033;
mem[1] = 32'h00100093;
mem[2] = 32'h00200113;
mem[3] = 32'h003081b3;

end

assign instruction = mem[adder[9:2]];

endmodule









module register_file(input clk, input we, input [4:0]rs1, input[4:0]rs2, input[4:0]rd, input [31:0]wd , output[31:0] rd1, output[31:0] rd2);
  
  reg[31:0] regfile[0:31];
  integer i;
  initial begin
    for(i=0;i<32;i=i+1)
        regfile[i] = 0;
end
  
  assign rd1= regfile[rs1];
  assign rd2= regfile[rs2];
  
  always@ (posedge clk)
    begin
      if(we && rd !=0)
        regfile[rd]<=wd;
    end
endmodule








module alu(
    input [31:0] a,
    input [31:0] b,
    input [2:0] alu_ctrl,
    output reg [31:0] result,
    output zero
);

always @(*)
begin
    case(alu_ctrl)

        3'b000: result = a + b;
        3'b001: result = a - b;
        3'b010: result = a & b;
        3'b011: result = a | b;
        3'b100: result = a ^ b;

        default: result = 0;

    endcase
end

assign zero = (result == 0);

endmodule






module imm_gen(
    input [31:0] instr,
    input [1:0] imm_src,
    output reg [31:0] imm_out
);

always @(*)
begin
    case(imm_src)

        // I type
        2'b00:
            imm_out = {{20{instr[31]}}, instr[31:20]};

        // S type
        2'b01:
            imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        // B type
        2'b10:
            imm_out = {{19{instr[31]}},
                       instr[31],
                       instr[7],
                       instr[30:25],
                       instr[11:8],
                       1'b0};

        // J type
        2'b11:
            imm_out = {{11{instr[31]}},
                       instr[31],
                       instr[19:12],
                       instr[20],
                       instr[30:21],
                       1'b0};

        default:
            imm_out = 0;

    endcase
end

endmodule






module control_unit(

input [6:0] opcode,

output reg RegWrite,
output reg MemWrite,
output reg MemRead,
output reg ALUSrc,
output reg ResultSrc,
output reg Branch,
output reg Jump,
output reg [1:0] ImmSrc,
output reg [1:0] ALUop

);

always @(*)
begin

    // default
    RegWrite = 0;
    MemWrite = 0;
    MemRead = 0;
    ALUSrc = 0;
    ResultSrc = 0;
    Branch = 0;
    Jump = 0;
    ImmSrc = 0;
    ALUop = 0;

    case(opcode)

    // R-type
    7'b0110011:
    begin
        RegWrite = 1;
        ALUSrc = 0;
        ResultSrc = 0;
        ALUop = 2'b10;
    end

    // I-type (addi)
    7'b0010011:
    begin
        RegWrite = 1;
        ALUSrc = 1;
        ImmSrc = 2'b00;
        ALUop = 2'b00;
    end

    // LW
    7'b0000011:
    begin
        RegWrite = 1;
        MemRead = 1;
        ALUSrc = 1;
        ResultSrc = 1;
        ImmSrc = 2'b00;
        ALUop = 2'b00;
    end

    // SW
    7'b0100011:
    begin
        MemWrite = 1;
        ALUSrc = 1;
        ImmSrc = 2'b01;
        ALUop = 2'b00;
    end

    // BEQ
    7'b1100011:
    begin
        Branch = 1;
        ImmSrc = 2'b10;
        ALUop = 2'b01;
    end

    // JAL
    7'b1101111:
    begin
        Jump = 1;
        RegWrite = 1;
        ImmSrc = 2'b11;
    end

    endcase

end

endmodule






module alu_control(

input [1:0] ALUop,
input [2:0] funct3,
input funct7,

output reg [2:0] alu_ctrl

);

always @(*)
begin

case(ALUop)

// for lw, sw, addi
2'b00:
    alu_ctrl = 3'b000;

// for beq
2'b01:
    alu_ctrl = 3'b001;

// R-type
2'b10:
begin

    case(funct3)

    3'b000:
        if(funct7)
            alu_ctrl = 3'b001;
        else
            alu_ctrl = 3'b000;

    3'b111:
        alu_ctrl = 3'b010;

    3'b110:
        alu_ctrl = 3'b011;

    3'b100:
        alu_ctrl = 3'b100;

    default:
        alu_ctrl = 3'b000;

    endcase

end

default:
    alu_ctrl = 3'b000;

endcase

end

endmodule







module data_memory(

input clk,
input MemWrite,
input MemRead,

input [31:0] addr,
input [31:0] wd,

output reg [31:0] rd

);

reg [31:0] mem [0:255];

always @(posedge clk)
begin
    if (MemWrite)
        mem[addr[9:2]] <= wd;
end

always @(*)
begin
    if (MemRead)
        rd = mem[addr[9:2]];
    else
        rd = 0;
end

endmodule

module riscv_top(

input clk,
input reset,

output [31:0] pc,
output [31:0] instruction,
output [31:0] alu_result,
output [31:0] mem_data

);

wire [31:0] pc_next;

wire [31:0] rd1;
wire [31:0] rd2;

wire [31:0] imm;

wire [2:0] alu_ctrl;

wire RegWrite;
wire MemWrite;
wire MemRead;
wire ALUSrc;
wire ResultSrc;
wire Branch;
wire Jump;

wire [1:0] ImmSrc;
wire [1:0] ALUop;

wire zero;





pc PC(
.clk(clk),
.reset(reset),
.pc_next(pc_next),
.pc(pc)
);




assign pc_next = pc + 4;




instruction_memory IMEM(
.adder(pc),
.instruction(instruction)
);



control_unit CU(

.opcode(instruction[6:0]),

.RegWrite(RegWrite),
.MemWrite(MemWrite),
.MemRead(MemRead),
.ALUSrc(ALUSrc),
.ResultSrc(ResultSrc),
.Branch(Branch),
.Jump(Jump),
.ImmSrc(ImmSrc),
.ALUop(ALUop)

);




register_file RF(

.clk(clk),
.we(RegWrite),

.rs1(instruction[19:15]),
.rs2(instruction[24:20]),
.rd(instruction[11:7]),

.wd(ResultSrc ? mem_data : alu_result),

.rd1(rd1),
.rd2(rd2)

);




imm_gen IMM(

.instr(instruction),
.imm_src(ImmSrc),
.imm_out(imm)

);




alu_control ALUCTRL(

.ALUop(ALUop),
.funct3(instruction[14:12]),
.funct7(instruction[30]),

.alu_ctrl(alu_ctrl)

);




wire [31:0] alu_b;

assign alu_b = ALUSrc ? imm : rd2;




alu ALU(

.a(rd1),
.b(alu_b),
.alu_ctrl(alu_ctrl),

.result(alu_result),
.zero(zero)

);




data_memory DM(

.clk(clk),
.MemWrite(MemWrite),
.MemRead(MemRead),

.addr(alu_result),
.wd(rd2),
.rd(mem_data)

);

endmodule

