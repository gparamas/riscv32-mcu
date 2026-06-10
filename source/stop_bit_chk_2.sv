`timescale 1ns / 10ps
`include "D:/riscv32-mcu/source/header.sv"
module stop_bit_chk_2 #(
    // parameters
) (
    input logic clk, input logic n_rst,
    input logic sbc_clear, sbc_enable,
    input logic stop_bit, 
    output logic framing_error
);
    logic next_framing_error;

`ifdef vivado
    initial begin
        framing_error = 1'b0;
    end
    always_ff@(posedge clk) begin
        framing_error <= next_framing_error;
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            framing_error <= 1'b0;
        end else begin
            framing_error <= next_framing_error;
        end
    end
`endif

    assign next_framing_error = sbc_enable ? stop_bit != 1'b1 : (sbc_clear ? 1'b0 : framing_error);

endmodule

