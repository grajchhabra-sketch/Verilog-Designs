`timescale 1ns/1ps

module tb;

  spi_if intf();

  spi_master master (intf);
  spi_slave slave (intf);

  always #5 intf.clk = ~intf.clk;

  class spi_trans;
    rand bit mode;
    rand bit [7:0] master_tx;
    rand bit [7:0] slave_tx;
  endclass

  
  task run_transfer(spi_trans tr);
    begin
      intf.mode      = tr.mode;
      intf.master_tx = tr.master_tx;
      intf.slave_tx  = tr.slave_tx;

      #20;
      intf.start = 1;
      #10;
      intf.start = 0;

      wait(intf.done);

      #40;
    end
  endtask


  initial begin
    spi_trans tr1, tr2;

    intf.clk = 0;
    intf.reset = 1;
    intf.start = 0;
    intf.mode  = 0;

    #20;
    intf.reset = 0;

 
    tr1 = new();
  tr1.randomize() with { mode == 0; };
    run_transfer(tr1);

    
    tr2 = new();
    tr2.randomize() with { mode == 1; };
    run_transfer(tr2);

    #10000;
    $finish;
  end


  initial begin
    $monitor("TIME=%0t | MODE=%0d | SS=%b SCLK=%b MOSI=%b MISO=%b | M_TX=%h S_TX=%h | M_RX=%h S_RX=%h DONE=%b",
              $time, intf.mode,
              intf.ss, intf.sclk, intf.mosi, intf.miso,
              intf.master_tx, intf.slave_tx,
              intf.master_rx, intf.slave_rx,
              intf.done);
  end

endmodule
