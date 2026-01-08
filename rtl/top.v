`include "master2.v"
`include "slave.v"

module top(input clk,
  input start,
  input rst,
  input [7:0] header_in,
  input [7:0] data_in
);

  wire [1:0] data;
  wire [1:0] ctrl;
  wire ack;
  wire busy;

  master2 MASTER(
    .clk(clk),
    .rst(rst),
    .start(start),
    .header_in(header_in),
    .data_in(data_in),
    .data(data),
    .ack(ack),
    .ctrl(ctrl),
    .busy(busy)
  );

  slave SLAVE(
    .clk(clk),
    .ctrl(ctrl),
    .data(data),
    .ack(ack)
  );

endmodule

