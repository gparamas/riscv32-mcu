`timescale 1ns / 10ps
`include "D:/riscv32-mcu/source/header.sv"
module flex_sr #(
    parameter SIZE = 8,
    parameter MSB_FIRST = 0
) (
    input logic clk, input logic n_rst, shift_enable, serial_in, load_enable,
    input logic [SIZE - 1:0] parallel_in, 
    output logic [SIZE - 1:0] parallel_out,
    output logic serial_out
);

`ifdef vivado
    logic [SIZE-1:0] Q = '1, next_Q;
    always_ff@(posedge clk) begin
        Q <= next_Q;
    end
`else
    logic [SIZE-1:0] Q, next_Q;
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            Q <= '1;
        end else begin
            Q <= next_Q;
        end
    end
`endif
    
    always_comb begin
        if(load_enable) begin
            next_Q = parallel_in;
        end 
        else if(shift_enable) begin
            if(MSB_FIRST) begin
                next_Q = {Q[SIZE - 2:0], serial_in};
            end else begin
                next_Q = {serial_in, Q[SIZE - 1:1]};
            end
        end else begin
            next_Q = Q;
        end
    end

    assign parallel_out = Q;
    assign serial_out = MSB_FIRST ? Q[SIZE - 1] : Q[0];
endmodule

