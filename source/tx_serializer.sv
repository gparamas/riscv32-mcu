`timescale 1ns / 10ps

module tx_serializer #(
    // parameters
) (
    input logic clk, n_rst,
    input logic tx_empty,
    input logic [7:0] tx_data_out,
    input logic [13:0] bit_period,
    input logic [3:0] data_size,
    output logic uart_tx, done
);
    logic [9:0] packet;
    always_comb begin
        packet = '0;
        if(data_size == 4'h5) begin
            packet = {4'hF, tx_data_out[4:0], 1'b0};
        end
        else if(data_size == 4'h7) begin
            packet = {2'h3, tx_data_out[6:0], 1'b0};
        end
        else if(data_size == 4'h8) begin
            packet = {1'b1, tx_data_out, 1'b0};
        end
    end
    logic packet_done, timer_en, load_en, shift_strobe;
    
    flex_sr #(.SIZE(10)) sr(.clk(clk), .n_rst(n_rst), .shift_enable(shift_strobe), .load_enable(load_en), .parallel_in(packet), .serial_out(uart_tx), .serial_in(1'b1));
    tx_controller tx_con(.clk(clk), .n_rst(n_rst), .tx_empty(tx_empty), .packet_done(packet_done), .timer_en(timer_en), .load_en(load_en));
    tx_timer t1(.clk(clk), .n_rst(n_rst), .timer_en(timer_en), .bit_period(bit_period), .data_size(data_size), .packet_done(packet_done), .shift_strobe(shift_strobe));

    assign done = packet_done;


endmodule

