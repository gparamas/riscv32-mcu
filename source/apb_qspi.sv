`timescale 1ns / 10ps

module apb_qspi #(
    // parameters
) (
    input logic clk, n_rst,
    input logic psel, pwrite, penable,
    input logic [31:0] pwdata, 
    input logic [2:0] paddr,
    output logic [31:0] prdata,
    output logic psaterr,
    output logic cs,
    inout wire sio1, sio2, sio3, sio4
);
    
    logic reset, underrun, overrun;
    logic load_tx, done_tx, tx_full, tx_empty;
    logic [31:0] tx_data_in, tx_data_out;
    logic load_rx, done_rx, rx_empty;
    logic [31:0] rx_data_in, rx_data_out;
    logic busy;

    qspi_fsm q1 (
        .clk(clk), 
        .n_rst(n_rst), 
        .wdata(tx_data_out), 
        .empty(~tx_empty), 
        .reset(reset), 
        .sio1(sio1), .sio2(sio2), .sio3(sio3), .sio4(sio4), .cs(cs), 
        .rdata(rx_data_in), 
        .data_ready(load_rx), 
        .done(done_tx),
        .underrun(underrun),
        .busy(busy)
    );

    tx_fifo #(
        .DEPTH(16),
        .WIDTH(32),
        .CE(1)
    ) f1(
        .clk(clk), .n_rst(n_rst),
        .tx_data_in(tx_data_in),
        .load(load_tx),
        .tx_empty(tx_empty),
        .done(done_tx),
        .tx_data_out(tx_data_out),
        .tx_full(tx_full)
    );

    rx_fifo r1 (
        .clk(clk), .n_rst(n_rst),
        .load(load_rx),
        .done(done_rx),
        .overrun(overrun),
        .rx_empty(rx_empty),
        .rx_data_out(rx_data_out),
        .rx_data_in(rx_data_in),
        .reset(reset)
    );

    qspi_apb_subordinate aq1 (
        .clk(clk), .n_rst(n_rst),
        .psel(psel), .pwrite(pwrite), .penable(penable),
        .pwdata(pwdata), .paddr(paddr),
        .rx_data_out(rx_data_out),
        .tx_data_in(tx_data_in),
        .rx_empty(~rx_empty), .tx_full(tx_full), .underrun(underrun), .overrun(overrun), .busy(busy),
        .prdata(prdata),
        .psaterr(psaterr),
        .done_rx(done_rx),
        .load_tx(load_tx),
        .reset(reset)
    );

endmodule

