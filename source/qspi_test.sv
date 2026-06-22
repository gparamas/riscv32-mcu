`timescale 1ns / 10ps

module qspi_test #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [31:0] wdata, 
    input logic empty,
    input logic reset,
    output logic [31:0] rdata,
    output logic data_ready, done, underrun

);

    wire sio1, sio2, sio3, sio4;
    logic cs;
    logic ce, cen;

    qspi_fsm q1(.clk(clk), .n_rst(n_rst), .underrun(underrun), .ce(ce), .cen(cen), .wdata(wdata), .empty(empty), .reset(reset), .sio1(sio1), .sio2(sio2), .sio3(sio3), .sio4(sio4), .cs(cs), .rdata(rdata), .data_ready(data_ready), .done(done));
    flash f1(.SCLK(cen ? ce : clk), .CS(cs), .SI(sio1), .SO(sio2), .WP(sio3), .SIO3(sio4));



endmodule

