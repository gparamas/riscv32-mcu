`timescale 1ns / 10ps

module rcv_block (
    input logic clk, n_rst, serial_in, data_read, 
    input logic [3:0] data_size,
    input logic [13:0] bit_period,
    output logic [7:0] rx_data, 
    output logic data_ready, overrun_error, framing_error
);
    logic serial_in_sync;
    sync_high s1(.clk(clk), .n_rst(n_rst), .async_in(serial_in), .sync_out(serial_in_sync));

    logic load_buffer, sbc_clear, sbc_enable, enable_timer, packet_done, new_packet_detected, shift_strobe, stop_bit;
    logic [7:0] packet_data;

    stop_bit_chk_2 s3(.clk(clk), .n_rst(n_rst), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));
    start_bit_det_2 s2(.clk(clk), .n_rst(n_rst), .serial_in(serial_in_sync), .new_packet_detected(new_packet_detected));
    rx_data_buff r1(.clk(clk), .n_rst(n_rst), .load_buffer(load_buffer), .packet_data(packet_data), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));
    sr_9bit s4(.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(serial_in_sync), .packet_data(packet_data), .stop_bit(stop_bit));
    timer t1(.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .bit_period(bit_period), .data_size(data_size), .shift_strobe(shift_strobe), .packet_done(packet_done));
    rcu r2(.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));

endmodule

