module traffic_light_controller(
    input clk,
    input reset,

    output reg NS_G,
    output reg NS_Y,
    output reg NS_R,

    output reg EW_G,
    output reg EW_Y,
    output reg EW_R
);

reg [1:0] state, next_state;

parameter S0 = 2'b00,
          S1 = 2'b01,
          S2 = 2'b10,
          S3 = 2'b11;


//// STATE REGISTER
always @(posedge clk or posedge reset)
begin
    if(reset)
        state <= S0;
    else
        state <= next_state;
end


//// NEXT STATE LOGIC
always @(*)
begin
    case(state)

        S0: next_state = S1;
        S1: next_state = S2;
        S2: next_state = S3;
        S3: next_state = S0;

        default: next_state = S0;

    endcase
end


//// OUTPUT LOGIC (MOORE)
always @(*)
begin
    case(state)

        S0: begin
            NS_G = 1; NS_Y = 0; NS_R = 0;
            EW_G = 0; EW_Y = 0; EW_R = 1;
        end

        S1: begin
            NS_G = 0; NS_Y = 1; NS_R = 0;
            EW_G = 0; EW_Y = 0; EW_R = 1;
        end

        S2: begin
            NS_G = 0; NS_Y = 0; NS_R = 1;
            EW_G = 1; EW_Y = 0; EW_R = 0;
        end

        S3: begin
            NS_G = 0; NS_Y = 0; NS_R = 1;
            EW_G = 0; EW_Y = 1; EW_R = 0;
        end

        default: begin
            NS_G = 0; NS_Y = 0; NS_R = 1;
            EW_G = 0; EW_Y = 0; EW_R = 1;
        end

    endcase
end

endmodule
