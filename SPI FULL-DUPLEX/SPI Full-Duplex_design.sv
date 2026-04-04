interface spi_if;

  logic clk;
  logic reset;
  logic start;

  logic mode; 

  logic sclk;
  logic ss;
  logic mosi;
  logic miso;
  logic done;

  logic [7:0] master_tx;
  logic [7:0] master_rx;

  logic [7:0] slave_tx;
  logic [7:0] slave_rx;

  modport spi_master_mp (
    input  clk, reset, start, miso, master_tx, mode,
    output sclk, ss, mosi, done, master_rx
  );

  modport spi_slave_mp (
    input  sclk, ss, mosi, slave_tx, mode,
    output miso, slave_rx
  );

endinterface


module spi_master(spi_if.spi_master_mp intf);

  typedef enum logic [1:0] {IDLE, TRANSFER, DONE} state_t;
  state_t state, next_state;

  logic [2:0] bit_count;
  logic [7:0] shift_tx, shift_rx;
  logic sclk_en;


  logic cpol, cpha;

  assign cpol = intf.mode; 
  assign cpha = intf.mode;

  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  always_comb begin
    case (state)
      IDLE:     next_state = intf.start ? TRANSFER : IDLE;
      TRANSFER: next_state = (bit_count == 3'd7 && sclk_en && (intf.sclk == ~cpol)) ? DONE : TRANSFER;
      DONE:     next_state = IDLE;
      default:  next_state = IDLE;
    endcase
  end

  always_ff @(posedge intf.clk or posedge intf.reset) begin
    if (intf.reset) begin
      intf.sclk <= 0;
      intf.ss <= 1;
      intf.mosi <= 0;
      intf.done <= 0;
      intf.master_rx <= 0;
      bit_count <= 0;
      shift_tx <= 0;
      shift_rx <= 0;
      sclk_en <= 0;
    end
    else begin
      case (state)

        IDLE: begin
          intf.ss <= 1;
          intf.sclk <= cpol; 
          intf.done <= 0;
          bit_count <= 0;
          sclk_en <= 0;

          if (intf.start) begin
            intf.ss <= 0;
            shift_tx <= intf.master_tx;
            shift_rx <= 0;
            sclk_en <= 1;

            if (cpha == 0)
              intf.mosi <= intf.master_tx[7]; 
          end
        end

        TRANSFER: begin
          if (sclk_en) begin
            intf.sclk <= ~intf.sclk;

            // MODE HANDLING
            if (intf.sclk == cpol) begin
              // SHIFT edge
              intf.mosi <= shift_tx[7];
              shift_tx <= {shift_tx[6:0], 1'b0};
            end
            else begin
              // SAMPLE edge
              shift_rx <= {shift_rx[6:0], intf.miso};
              bit_count <= bit_count + 1;
            end
          end
        end

        DONE: begin
          intf.ss <= 1;
          intf.sclk <= cpol;
          intf.done <= 1;
          intf.master_rx <= shift_rx;
          sclk_en <= 0;
        end

      endcase
    end
  end
  
  

property p_ss_active;
  @(posedge intf.clk)
  (state == TRANSFER) |-> (intf.ss == 0);
endproperty

assert property (p_ss_active)
  else $error("SPI ERROR: SS not LOW during TRANSFER");



property p_8bit_transfer;
  @(posedge intf.clk)
  (state == TRANSFER && next_state == DONE) |-> (bit_count == 3'd7);
endproperty

assert property (p_8bit_transfer)
  else $error("SPI ERROR: Transfer not exactly 8 bits");



property p_idle_sclk;
  @(posedge intf.clk)
  (state == IDLE) |-> (intf.sclk == cpol);
endproperty

assert property (p_idle_sclk)
  else $error("SPI ERROR: SCLK not matching CPOL in IDLE");



endmodule



module spi_slave(spi_if.spi_slave_mp intf);

  logic [2:0] bit_count;
  logic [7:0] shift_tx, shift_rx;

  logic cpol, cpha;
  assign cpol = intf.mode;
  assign cpha = intf.mode;

  
  always_ff @(negedge intf.ss) begin
    shift_tx <= intf.slave_tx;
    shift_rx <= 0;
    bit_count <= 0;

    if (cpha == 0)
      intf.miso <= intf.slave_tx[7]; // Mode0 preload
  end

 
  always_ff @(posedge intf.sclk or negedge intf.sclk) begin
    if (!intf.ss) begin
      if ((intf.sclk == ~cpol)) begin
        shift_rx <= {shift_rx[6:0], intf.mosi};
        bit_count <= bit_count + 1;
      end
    end
  end

  
  always_ff @(posedge intf.sclk or negedge intf.sclk) begin
    if (!intf.ss) begin
      if ((intf.sclk == cpol)) begin
        shift_tx <= {shift_tx[6:0], 1'b0};
        intf.miso <= shift_tx[6];
      end
    end
  end

 
  always_ff @(posedge intf.ss) begin
    intf.slave_rx <= shift_rx;
  end

endmodule
