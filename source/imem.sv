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

    logic [8191:0][31:0] ram, nram;
    logic [31:0] next_rdata;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            ram <= '0;
            rdata <= '0;
        end
        else begin
            ram <= nram;
            rdata <= next_rdata;
        end
    end

    always_comb begin
        nram = ram;
        next_rdata = stall ? rdata : '0;
        if(ren) begin
            next_rdata = ram[raddr[12:0]];
        end
        if(wen) begin
            nram[waddr[12:0]] = wdata;
        end
    end
    


endmodule

