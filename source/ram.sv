`timescale 1ns / 10ps
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module ram #(
    parameter int DEPTH
)(
    input logic clk, input logic n_rst,
    input logic [$clog2(DEPTH)-1:0] raddr, waddr,
    input logic wen, ren,
    input logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] ram [DEPTH-1:0];

`ifdef vivado
    initial begin
        rdata = '0;
    end
    always_ff@(posedge clk) begin
        if (ren) begin rdata <= ram[raddr]; end
        if (wen) begin ram[waddr] <= wdata; end
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            rdata <= '0;
        end else begin
            if (ren) begin rdata <= ram[raddr]; end
            if (wen) begin ram[waddr] <= wdata; end
        end
    end
`endif

endmodule