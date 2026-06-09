`timescale 1ns / 10ps
`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module start_bit_det_2 #(
    // parameters
) (
    input logic clk, input logic n_rst,
    input logic serial_in,
    output logic new_packet_detected
);
    logic last_serial_in;

`ifdef vivado
    initial begin
        last_serial_in = 1'b0;
    end
    always_ff@(posedge clk) begin
        last_serial_in <= serial_in;
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            last_serial_in <= 1'b0;
        end else begin
            last_serial_in <= serial_in;
        end
    end
`endif

    assign new_packet_detected = last_serial_in & ~serial_in;



endmodule

