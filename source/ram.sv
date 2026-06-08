`timescale 1ns / 10ps

module ram #(
    parameter int DEPTH
)(
    input logic clk,
    input logic [15:0] raddr, waddr,
    input logic wen, ren,
    input logic [31:0] wdata,
    output logic [31:0] rdata = '0
);
    logic [31:0] ram [DEPTH-1:0];

    always_ff@(posedge clk) begin
        if (ren) rdata <= ram[raddr];
        if (wen) ram[waddr] <= wdata;
    end

endmodule