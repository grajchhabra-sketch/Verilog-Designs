module testbench;
  reg [3:0]a;
  reg [3:0]b;
  reg [2:0]op;
  
  wire [3:0]y;
  integer i,j,k;
  
  
  alu DUT(a,b,op,y);
  initial
    begin
      $monitor($time,"a=%b,b=%b,op=%b,y=%b",a,b,op,y);
     
      
      for(k=0; k<8 ; k=k+1)begin
        op=k;
        for(i = 0; i < 16; i = i + 1) begin
        for(j = 0; j < 16; j = j + 1) begin

            a = i;
            b = j;
          #5;
        end
        end
      end
      $finish;
    end
endmodule
  
        
