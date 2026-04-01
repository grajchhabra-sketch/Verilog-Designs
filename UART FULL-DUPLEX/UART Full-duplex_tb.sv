`timescale 1ns/1ps

module testbench;

  uart_if intf();

  baud_gen bg(intf);
  uart_tx  tx(intf);
  uart_rx  rx(intf);

  assign intf.rx = intf.tx;

  class packet;
    rand bit [7:0] data;
  endclass

  packet pkt;

  initial begin
    intf.clk = 0;
    forever #5 intf.clk = ~intf.clk;
  end

  initial begin
    $monitor("t=%0t valid=%0d ready=%0d tx=%0d rx=%0d valid_rx=%0d data_out=%h",
              $time, intf.valid, intf.ready, intf.tx, intf.rx, intf.valid_rx, intf.data_out);
  end

  initial begin

    pkt = new();

    intf.reset   = 1;
    intf.valid   = 0;
    intf.data_in = 0;

    #20;
    intf.reset = 0;

    repeat (5) begin

      wait(intf.ready);

      @(posedge intf.clk);

      assert(pkt.randomize());
      intf.data_in = pkt.data;
      intf.valid   = 1;

      @(posedge intf.clk);
      intf.valid = 0;

while (intf.valid_rx != 1)
  @(posedge intf.clk);

$display("  ");
$display("Sent Data     = %h", pkt.data);
$display("Received Data = %h", intf.data_out);
$display("  ");
      #1000;

    end

    #100000;
    $finish;

  end

endmodule
