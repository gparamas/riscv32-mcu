`timescale 1ns / 10ps

module imem #(
    // parameters
) (
    input logic clk, n_rst,
    input logic wen, ren, stall,
    input logic [31:0] waddr, raddr,
    input logic [31:0] wdata,
    output logic [31:0] rdata
);

    logic [31:0] ram_rdata;
    logic pstall, pren;
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            pstall <= '0;
            pren <= '0;
        end
        else begin
            pstall <= stall;
            pren <= ren;
        end
    end


    ram #(.DEPTH(8192)) irambf (
        .clk(clk),
        .n_rst(n_rst),
        .raddr(raddr[12:0]),
        .waddr(waddr[12:0]),
        .ren(ren),
        .wen(wen),
        .wdata(wdata),
        .rdata(ram_rdata)
    );

    assign rdata = (pren || pstall) ? ram_rdata : '0;

    


endmodule

