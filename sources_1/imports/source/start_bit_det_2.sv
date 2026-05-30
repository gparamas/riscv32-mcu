`timescale 1ns / 10ps

module start_bit_det_2 #(
    // parameters
) (
    input logic clk, 
    input logic serial_in,
    output logic new_packet_detected
);
    logic last_serial_in = 1'b0;

    always_ff@(posedge clk) begin
        last_serial_in <= serial_in;
    end

    assign new_packet_detected = last_serial_in & ~serial_in;



endmodule

