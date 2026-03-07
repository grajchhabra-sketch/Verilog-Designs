module alu(input [3:0]a, input [3:0]b, input [2:0]op, output reg [3:0]y);
  
  always@(*)
    begin
      case(op)
        
        3'b000 : y=a+b;
        3'b001 : y=a-b;
        3'b010 : y=a&b;
        3'b000 : y=a|b;
        3'b000 : y=a^b;
        3'b000 : y=~a;
        3'b000 : y=a<<1; //left shift
        3'b000 : y=a>>1;
        
        default: y=4'b0000;
      endcase
    end
  endmodule
        
