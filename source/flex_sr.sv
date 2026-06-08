`timescale 1ns / 10ps

module flex_sr #(
    parameter SIZE = 8,
    parameter MSB_FIRST = 0
) (
    input logic clk, shift_enable, serial_in, load_enable,
    input logic [SIZE - 1:0] parallel_in, 
    output logic [SIZE - 1:0] parallel_out,
    output logic serial_out
);

    logic [SIZE-1:0] Q = '1, next_Q;
    
    always_ff@(posedge clk) begin
        Q <= next_Q;
    end
    
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

