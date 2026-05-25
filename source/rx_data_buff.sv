`timescale 1ns / 10ps

module rx_data_buff #(
    // parameters
) (
    input logic clk, n_rst,
    input logic load_buffer,
    input logic [7:0] packet_data,
    input logic data_read,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic overrun_error
);

    logic [7:0] next_rx_data;
    logic next_overrun_error;
    logic next_data_ready;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            rx_data <= 8'hFF;
            overrun_error <= 0;
            data_ready <= 0;
        end
        else begin
            rx_data <= next_rx_data;
            overrun_error <= next_overrun_error;
            data_ready <= next_data_ready;
        end
    end

    assign next_rx_data = load_buffer ? packet_data : rx_data;
    assign next_overrun_error = load_buffer && data_ready == 1'b1 ? 1'b1 : ((data_read && data_ready == 1'b1 && overrun_error == 1'b1) ? 1'b0 : overrun_error);
    assign next_data_ready =  load_buffer ? 1'b1 : ((data_read == 1'b1) ? 1'b0 : data_ready);



endmodule

