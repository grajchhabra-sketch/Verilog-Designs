module vending_machine(input clk, input reset, input coin5, input coin10, output reg dispense , output reg change5);
  reg[1:0]state,next_state;
  
  parameter s0=2'b00;
  parameter s5=2'b01;
  parameter s10=2'b10;
  parameter s15=2'b11;
  
  always@(posedge clk or posedge reset)
    begin
      if(reset)
        state<=s0;
      else
        state<=next_state;
    end
  
  always@(*)
    begin
      case(state)
        
      s0: 
        if(coin5)
          next_state=s5;
        else if(coin10)
          next_state=s10;
        else 
          next_state=s0;
        
         s5: 
        if(coin5)
          next_state=s10;
        else if(coin10)
          next_state=s15;
        else 
          next_state=s5;
        
         s10: 
        if(coin5)
          next_state=s15;
        else if(coin10)
          next_state=s0;
        else 
          next_state=s10;
        
         s15: 
          next_state=s0;
        
        default:
          next_state=s0;
        
        
      endcase
    end
  
  always@(*)
    begin
      dispense=0;
      change5=0;
      
      case(state)
        
        s15:
          dispense=1;
        s10:
        if(coin10)
          begin
            dispense=1;
            change5=1;
          end
        default:
    begin
        dispense = 0;
        change5 = 0;
    end
      endcase
    end
  endmodule
