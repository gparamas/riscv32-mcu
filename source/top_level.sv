`timescale 1ns / 10ps
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module top_level #(
    // parameters
) (
    input logic clk, input logic n_rst,
    input logic uart_rx,
    output logic uart_tx
);
    logic clk_out, locked;

`ifdef vivado 
    clk_wiz_0 clk_wiz_inst (
    .clk_in1  (clk),
    .clk_out1 (clk_out),
    .reset    (1'b0),
    .locked   (locked)
);
`else
    assign clk_out = clk;  
`endif

    logic read_en, write_en;
    logic [31:0] apb_addr_pr, apb_addr_dma, iaddr, instr;
    logic [31:0] out_rdata, prdata_uart, prdata_qspi, pwdata, out_wdata;
    logic psel_uart, penable, pwrite, psaterr_uart;
    logic psel_qspi, psaterr_qspi;
    logic [2:0] paddr;
    logic [31:0] instr_wdata;
    logic [31:0] instr_waddr;
    logic uart_dreq, read_en_dma, write_en_dma, pr_en;
    logic imem_ren, stall, flush;

    dma dm1(
        .clk(clk_out), .n_rst(n_rst),
        .rdata(out_rdata[7:0]), .uart_dreq(uart_dreq), 
        .read_en(read_en_dma), .write_en(write_en_dma), .pr_en(pr_en),
        .wdata(instr_wdata), .waddr(instr_waddr), .raddr(apb_addr_dma)
    );

    imem im1(
        .clk(clk_out), .n_rst(n_rst),
        .wen(write_en_dma), .ren(imem_ren), .stall(stall),
        .waddr(instr_waddr), .raddr(iaddr),
        .wdata(instr_wdata), .rdata(instr), .flush(flush)
    );

    pr1 p1(
        .clk(clk_out), .n_rst(n_rst),
        .instr(instr), .iaddr(iaddr), .out_rdata(out_rdata), .stall(stall),
        .read_en(read_en), .write_en(write_en),
        .apb_addr(apb_addr_pr), .out_wdata(out_wdata), .en(pr_en), .imem_ren(imem_ren), .flush(flush)
    );

    apb_manager am1(
        .clk(clk_out), .n_rst(n_rst),
        .prdata_uart(prdata_uart), .psaterr_uart(psaterr_uart), .prdata_qspi(prdata_qspi), .psaterr_qspi(psaterr_qspi),
        .apb_addr(pr_en ? apb_addr_pr : apb_addr_dma), .wdata(out_wdata),
        .read_en(pr_en ? read_en : read_en_dma), .write_en(pr_en ? write_en : write_en_dma),
        .psel_uart(psel_uart), .penable(penable), .psel_qspi(psel_qspi),
        .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .out_rdata(out_rdata)
    );

    apb_uart au1(
        .clk(clk_out), .n_rst(n_rst),
        .serial_in(uart_rx), .uart_tx(uart_tx),
        .psel(psel_uart), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata[7:0]), .prdata(prdata_uart[7:0]),
        .psaterr(psaterr_uart), .uart_dreq(uart_dreq)
    );

    apb_qspi aq1t (
        .clk(clk),
        .n_rst(n_rst),
        .psel(psel_qspi),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata_qspi),
        .psaterr(psaterr_qspi),
        .cs(cs),
        .sio1(sio1), .sio2(sio2), .sio3(sio3), .sio4(sio4)
    );

    flash f1(.SCLK(clk), .CS(cs), .SI(sio1), .SO(sio2), .WP(sio3), .SIO3(sio4));

endmodule

