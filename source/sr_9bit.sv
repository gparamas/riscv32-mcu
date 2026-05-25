`timescale 1ns / 10ps

module sr_9bit (
    input logic clk, n_rst, shift_strobe, serial_in,
    output logic [7:0] packet_data,
    output logic stop_bit
);
    flex_sr #(.SIZE(9)) sr(.clk(clk), .n_rst(n_rst), .shift_enable(shift_strobe), .serial_in(serial_in), .load_enable(1'b0), .parallel_in(9'b0), .parallel_out({stop_bit, packet_data}));


endmodule

