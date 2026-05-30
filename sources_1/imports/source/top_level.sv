`timescale 1ns / 10ps

module top_level #(
    // parameters
) (
    input logic clk,
    input logic uart_rx,
    output logic uart_tx
);
    logic clk_out, locked;
    
    clk_wiz_0 clk_wiz_inst (
    .clk_in1  (clk),
    .clk_out1 (clk_out),
    .reset    (1'b0),
    .locked   (locked)
);

    logic read_en, write_en;
    logic [31:0] apb_addr_pr, apb_addr_dma, iaddr, instr;
    logic [7:0] out_rdata, prdata, pwdata, out_wdata;
    logic psel_uart, penable, pwrite, psaterr;
    logic [2:0] paddr;
    logic [31:0] instr_wdata;
    logic [31:0] instr_waddr;
    logic uart_dreq, read_en_dma, write_en_dma, pr_en;
    logic imem_ren, stall;

    dma dm1(
        .clk(clk_out),
        .rdata(out_rdata), .uart_dreq(uart_dreq), 
        .read_en(read_en_dma), .write_en(write_en_dma), .pr_en(pr_en),
        .wdata(instr_wdata), .waddr(instr_waddr), .raddr(apb_addr_dma)
    );

    imem im1(
        .clk(clk_out),
        .wen(write_en_dma), .ren(imem_ren), .stall(stall),
        .waddr(instr_waddr), .raddr(iaddr),
        .wdata(instr_wdata), .rdata(instr)
    );

    pr1 p1(
        .clk(clk_out),
        .instr(instr), .iaddr(iaddr), .out_rdata(out_rdata), .stall(stall),
        .read_en(read_en), .write_en(write_en),
        .apb_addr(apb_addr_pr), .out_wdata(out_wdata), .en(pr_en), .imem_ren(imem_ren)
    );

    apb_manager am1(
        .clk(clk_out),
        .prdata(prdata), .psaterr(psaterr),
        .apb_addr(pr_en ? apb_addr_pr : apb_addr_dma), .wdata(out_wdata),
        .read_en(pr_en ? read_en : read_en_dma), .write_en(pr_en ? write_en : write_en_dma),
        .psel_uart(psel_uart), .penable(penable),
        .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .out_rdata(out_rdata)
    );

    apb_uart au1(
        .clk(clk_out),
        .serial_in(uart_rx), .uart_tx(uart_tx),
        .psel(psel_uart), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata), .prdata(prdata),
        .psaterr(psaterr), .uart_dreq(uart_dreq)
    );


endmodule

