`include "top.v"

module tb_top;

  reg clk = 0;
  reg rst;
  reg start;
  reg [7:0] header_in;
  reg [7:0] data_in;

  wire [1:0] data;
  wire [1:0] ctrl;
  wire ack;
  wire busy;

  // 100 MHz clock
  always #5 clk = ~clk;

  // DUT
  top DUT(
    .clk(clk),
    .start(start),
    .rst(rst),
    .header_in(header_in),
    .data_in(data_in)
  );

  initial begin
    $display("----- CUSTOM PROTOCOL FULL TEST -----");

    rst = 1;
    start = 0;
    header_in = 0;
    data_in = 0;

    #20;
    rst = 0;

    //---------------- WRITE TEST ----------------
    $display("WRITE TRANSACTION");

    header_in = 8'b01100111;    // write frame
    data_in   = 8'hA5;           // data to slave

    start = 1; #10; start = 0;


    if(DUT.MASTER.read_data == 8'hA5)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    #200;
    $display("READ DATA = %h", DUT.SLAVE.received_data);
    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_top);
  end
  
endmodule
