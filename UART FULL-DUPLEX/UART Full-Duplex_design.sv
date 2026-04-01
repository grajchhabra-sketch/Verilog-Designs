interface  uart_if;
  logic clk;
  logic reset;
  logic baud_tick;
  logic baud_tick_16;
  
  logic [7:0]data_in;
  logic valid;
  logic tx;
  logic ready;
  
  logic rx;
  logic [7:0]data_out;
  logic valid_rx;
  
  
  modport baud_gen_mp(
    input clk, reset,
    output baud_tick, baud_tick_16);
  
  modport uart_tx_mp(
    input clk, reset, valid, baud_tick, data_in,
    output tx, ready);
  
  modport uart_rx_mp(
    input clk, reset, baud_tick_16, rx,
    output data_out, valid_rx);
  
endinterface


// baud_generator

module baud_gen(uart_if.baud_gen_mp intf);
  localparam BAUD_DIV= 50;
  localparam BAUD_DIV_16= 50/16;
  
  logic [$clog2(BAUD_DIV)-1 :0]count;
   logic [$clog2(BAUD_DIV_16)-1:0] count16;
  
  always_ff@(posedge intf.clk or posedge intf.reset)
  begin
    
    if(intf.reset)
      begin
      count<=0;
      count16<=0;
    intf.baud_tick<=0;
    intf.baud_tick_16<=0;
      end
    
    else
      begin
        if(count==BAUD_DIV-1)
          begin
          count<=0;
        intf.baud_tick<=1;
          end
        else
          begin
            count<=count+1;
            intf.baud_tick<=0;
          end
          
          if (count16 == BAUD_DIV_16-1) begin
        count16 <= 0;
        intf.baud_tick_16 <= 1;
      end else begin
        count16 <= count16 + 1;
        intf.baud_tick_16 <= 0;
      end
      end
      
  end
endmodule


// TRANSMITTER

module uart_tx(uart_if.uart_tx_mp intf);

  typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
  state_t state, next_state;

  logic [7:0] shift_reg;
  logic [2:0] bit_count;

  // state register
  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  // next state logic
  always_comb begin
    next_state = state;

    case (state)
      IDLE:
        if (intf.valid && intf.ready)
          next_state = START;

      START:
        if (intf.baud_tick)
          next_state = DATA;

      DATA:
        if (intf.baud_tick && bit_count == 7)
          next_state = STOP;

      STOP:
        if (intf.baud_tick)
          next_state = IDLE;

      default:
        next_state = IDLE;
    endcase
  end

  // output logic
  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset) begin
      intf.tx    <= 1;
      intf.ready <= 1;
      shift_reg  <= 0;
      bit_count  <= 0;
    end
    else begin
      case (state)

        IDLE: begin
          intf.tx    <= 1;
          intf.ready <= 1;

          if (intf.valid && intf.ready) begin
            shift_reg <= intf.data_in;
            bit_count <= 0;
            intf.ready <= 0;
          end
        end

        START: begin
          if (intf.baud_tick)
            intf.tx <= 0;
        end

        DATA: begin
          if (intf.baud_tick) begin
            intf.tx     <= shift_reg[0];
            shift_reg   <= {1'b0, shift_reg[7:1]};
            bit_count   <= bit_count + 1;
          end
        end

        STOP: begin
          if (intf.baud_tick) begin
            intf.tx    <= 1;
            intf.ready <= 1;
          end
        end

      endcase
    end
  end
  
  property tx_handshake;
  @(posedge intf.clk)
  (intf.valid && !intf.ready) |-> $stable(intf.data_in);
endproperty

assert property(tx_handshake)
  else $error("Data changed while TX not ready");
endmodule

module uart_rx(uart_if.uart_rx_mp intf);

  typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
  state_t state, next_state;

  logic [7:0] shift_reg;
  logic [2:0] bit_count;
  logic [3:0] sample_count;

  logic rx_sync1, rx_sync2;
  logic rx_d;


  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset) begin
      rx_sync1 <= 1;
      rx_sync2 <= 1;
      rx_d     <= 1;
    end else begin
      rx_sync1 <= intf.rx;
      rx_sync2 <= rx_sync1;
      rx_d     <= rx_sync2;
    end
  end

 
  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    next_state = state;

    case (state)

      IDLE:
        if (rx_d == 1 && rx_sync2 == 0)
          next_state = START;

      START:
        if (intf.baud_tick_16 && sample_count == 7) begin
          if (rx_sync2 == 0)
            next_state = DATA;
          else
            next_state = IDLE;
        end

      DATA:
        if (intf.baud_tick_16 && sample_count == 15 && bit_count == 7)
          next_state = STOP;

      STOP:
        if (intf.baud_tick_16 && sample_count == 15)
          next_state = IDLE;

    endcase
  end


  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset) begin
      shift_reg     <= 0;
      bit_count     <= 0;
      sample_count  <= 0;
      intf.data_out <= 0;
      intf.valid_rx <= 0;
    end
    else begin

      case (state)

        IDLE: begin
          bit_count <= 0;
          sample_count <= 0;

          if (rx_d == 1 && rx_sync2 == 0)
            intf.valid_rx <= 0;
        end

        START: begin
          if (intf.baud_tick_16) begin
            if (sample_count == 7)
              sample_count <= 0;
            else
              sample_count <= sample_count + 1;
          end
        end

        DATA: begin
          if (intf.baud_tick_16) begin
            if (sample_count == 15) begin
              sample_count <= 0;

              shift_reg <= {rx_sync2, shift_reg[7:1]};
              bit_count <= bit_count + 1;
            end
            else begin
              sample_count <= sample_count + 1;
            end
          end
        end

        STOP: begin
          if (intf.baud_tick_16) begin
            if (sample_count == 15) begin
              intf.data_out <= shift_reg;
              intf.valid_rx <= 1;
              sample_count <= 0;
            end
            else begin
              sample_count <= sample_count + 1;
            end
          end
        end

      endcase
    end
  end

  property rx_data_stable;
    @(posedge intf.clk)
    intf.valid_rx |-> $stable(intf.data_out);
  endproperty

  assert property(rx_data_stable)
    else $error("RX data changed while valid_rx is high");

endmodule
