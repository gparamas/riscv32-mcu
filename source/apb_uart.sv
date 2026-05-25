`timescale 1ns / 10ps

module apb_uart #(
    // parameters
) (
    input logic clk, n_rst, serial_in, psel, penable, pwrite,
    input logic [2:0] paddr,
    input logic [7:0] pwdata,
    output logic [7:0] prdata,
    output logic psaterr, uart_tx, uart_dreq
    
);

    logic [7:0] tx_data_in, tx_data_out, rx_data;
    logic [13:0] bit_period;
    logic [3:0] data_size;
    logic tx_empty, tx_full;
    logic overrun_error, framing_error;
    logic data_ready, data_read;
    logic load, done;


    apb_subordinate a1(
        .clk(clk),
        .n_rst(n_rst),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .rx_data(rx_data),
        .pwdata(pwdata),
        .paddr(paddr),
        .data_read(data_read),
        .psaterr(psaterr),
        .load(load),
        .tx_data_in(tx_data_in),
        .data_size(data_size),
        .prdata(prdata),
        .bit_period(bit_period),
        .tx_full(tx_full),
        .tx_busy(tx_empty),
        .uart_dreq(uart_dreq)
    );

    tx_fifo f1(
        .clk(clk),
        .n_rst(n_rst),
        .tx_data_in(tx_data_in),
        .load(load),
        .tx_empty(tx_empty),
        .done(done),
        .tx_data_out(tx_data_out),
        .tx_full(tx_full)
    );

    tx_serializer t1(
        .clk(clk),
        .n_rst(n_rst),
        .tx_data_out(tx_data_out),
        .tx_empty(tx_empty),
        .data_size(data_size),
        .bit_period(bit_period),
        .done(done),
        .uart_tx(uart_tx)
    );

    rcv_block rcv(
        .clk(clk),
        .n_rst(n_rst),
        .serial_in(serial_in),
        .data_read(data_read),
        .data_size(data_size),
        .bit_period(bit_period),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error)
    );

endmodule

