`timescale 1ns / 10ps

module sync_high (
  input logic clk, async_in,
  output logic sync_out
);

    sync #(.RST_VAL(1'b1)) high (.*);

endmodule

