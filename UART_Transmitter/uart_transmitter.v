//// BAUD GENERATOR

module baud_gen(input clk , input reset , output reg baud_tick);
  reg [12:0]count;
  parameter BAUD_DIV=5208;
  
  always@(posedge clk or posedge reset)
    begin
      
      if(reset)
        begin
          count<=0;
          baud_tick<=0;
        end
      else
        begin
          if(count == BAUD_DIV - 1)
            begin
            count<=0;
            baud_tick<=1;
            end
          else
            begin
              count<=count+1;
              baud_tick<=0;
            end
        end
    end
endmodule

//// UART TRANSMITTER

module uart_tx(input clk, input reset, input start, input baud_tick,                input [7:0] data_in , output reg tx, output reg busy);
  
  reg [1:0]state, next_state;
  reg [7:0]data_reg;
  reg [3:0]bit_count;
  
  localparam IDLE=2'b00;
  localparam START=2'b01;
  localparam DATA=2'b10;
  localparam STOP=2'b11;
  
  // STATE REGISTER
  
  always@(posedge clk or posedge reset)
    begin
      
      if(reset)
          state <= IDLE;
      else
          state<= next_state;
    end
  
  // NEXT STATE LOGIC
  
  always@(*)
    begin
      case(state)
        
        IDLE:
          if(start)
            next_state = START;
        else
          next_state = IDLE;
        
        START:
          if(baud_tick)
            next_state = DATA;
        else
          next_state = START;
        
        DATA:
           if(baud_tick)
            next_state = STOP;
        else
          next_state = DATA;
        
        STOP:
         if(baud_tick)
            next_state = IDLE ;
        else
          next_state = STOP;
        
        default:
          next_state = IDLE;
      endcase
    end
  
  
// OUTPUT LOGIC
  
  always@(posedge clk or posedge reset)
    begin
      if(reset)
        begin 
          tx<=1;
          busy<=0;
          bit_count<=0;
        end
      else
        begin
          case(state)
            
            IDLE:
              begin
                tx<=1;
                busy<=0;
                
                if(start)
                  begin
                    data_reg <=data_in;
                    bit_count <=0;
                    busy<=1;
                   
                   end
              end
            
            START:
              begin
                if(baud_tick)
                  tx<=0;
              end
            
            DATA:
              begin
                if(baud_tick)
                  begin
                    tx<= data_reg[bit_count];
                    bit_count= bit_count+1;
                    
                  end
              end
            
            STOP:
              begin
                if(baud_tick)
                  tx<=1;
              end
          endcase
        end 
    end
endmodule

//// UART TOP MODULE(IT CONNECTS EVERYTHING)


module uart_top(
    input clk,
    input reset,
    input start,
    input [7:0] data_in,
    output tx,
    output busy
);

wire baud_tick;

baud_gen bg(
    .clk(clk),
    .reset(reset),
    .baud_tick(baud_tick)
);

uart_tx tx_unit(
    .clk(clk),
    .reset(reset),
    .start(start),
    .baud_tick(baud_tick),
    .data_in(data_in),
    .tx(tx),
    .busy(busy)
);

endmodule
                 
