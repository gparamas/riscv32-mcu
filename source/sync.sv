`timescale 1ns / 10ps

module sync #(
    parameter RST_VAL=0
) (
    input logic clk, input logic n_rst, async_in,
    output logic sync_out
);
    //first and second flip flop state
    logic ff_1, ff_2;

    //flip flop logic - if n_rst is low assert to RST_VAL, otherwise propagate the input signal
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            ff_1 <= RST_VAL;
            ff_2 <= RST_VAL;
        end else begin
            ff_1 <= async_in;
            ff_2 <= ff_1;
        end
    end

    //take output from end of second flip flop
    assign sync_out = ff_2;
endmodule

