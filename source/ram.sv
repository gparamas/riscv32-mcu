`timescale 1ns / 10ps

module ram #(
    parameter int DEPTH
)(
    input logic clk, n_rst,
    input logic [$clog2(DEPTH)-1:0] raddr, waddr,
    input logic wen, ren,
    input logic [31:0] wdata,
    output logic [31:0] rdata = '0
);
    logic [31:0] ram [DEPTH-1:0];

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            ram <= '{default: 0};
        end
        else begin
        if (ren) begin rdata <= ram[raddr]; end
        if (wen) begin ram[waddr] <= wdata; end
        end
    end

endmodule