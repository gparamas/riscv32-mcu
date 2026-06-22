`timescale 1ns / 10ps

module qspi_test_full #(
    // parameters
) (
    input logic clk, n_rst,
    input logic psel, penable, pwrite,
    input logic [2:0] paddr,
    input logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic psaterr
);

    wire sio1, sio2, sio3, sio4;
    logic cs;
    logic ce, cen;

    flash f1(.SCLK(cen ? ce : clk), .CS(cs), .SI(sio1), .SO(sio2), .WP(sio3), .SIO3(sio4));

    apb_qspi aq1t (
        .clk(clk),
        .n_rst(n_rst),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .psaterr(psaterr),
        .cs(cs),
        .sio1(sio1), .sio2(sio2), .sio3(sio3), .sio4(sio4), 
        .ce(ce), .cen(cen)
    );

endmodule

