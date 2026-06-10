`timescale 1ns / 10ps
`include "D:/riscv32-mcu/source/header.sv"
module sync_high (
  input logic clk, input logic n_rst, async_in,
  output logic sync_out
);

    sync #(.RST_VAL(1'b1)) high (.clk(clk), .n_rst(n_rst), .async_in(async_in), .sync_out(sync_out));

endmodule

