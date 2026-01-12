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

    rst = 1;
    start = 0;
    header_in = 0;
    data_in = 0;

    #20;
    rst = 0;

    //---------------- WRITE TEST ----------------
    $display("WRITE TRANSACTION");

    header_in = 8'b00000101;    // write frame	2 bytes
    data_in   = 8'h10;           // data to slave

    start = 1; #10; start = 0;

	#200;
    if(DUT.SLAVE.read_memory[0] == 8'h10) begin
      $display("WRITE TRANSACTION TEST PASSED");
      $display("Expected data = %d | Received data = %d",data_in,DUT.SLAVE.read_memory[0]);
    end
    else	begin
      $display("TEST FAILED");
  end

    $display("READ DATA = %h", DUT.SLAVE.read_memory[0]);
    $display("READ DATA = %h", DUT.SLAVE.read_memory[1]);
    
    #200;
    //--------------------------READ TEST------------------------------
    $display("READ TRANSACTION");
    header_in = 8'b00000100;	//2 bytes
    data_in = 8'hA5;
    
    start = 1; #10; start = 0;
    
    #400;
    $display("Read data = %d",DUT.MASTER.read_data[0]);
    if(DUT.MASTER.read_data[0] == 8'd88) begin
      $display("READ TRANSACTION TEST PASSED");
      $display("Expected data = %d | Received data = %d",DUT.SLAVE.saved_data[0],DUT.MASTER.read_data[0]);
    end
    else begin
      $display("TEST FAILED");
    end
    
    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_top);
  end
  
endmodule
