`timescale 1ns / 10ps

module tx_timer #(
    // parameters
) (
    input logic clk, n_rst,
    input logic timer_en, 
    input logic [13:0] bit_period,
    input logic [3:0] data_size,
    output logic shift_strobe, packet_done
);
    logic rflag, rflag2;
    logic [13:0] c1;
    logic [4:0] c2;
    flex_counter #(.SIZE(14)) f1(.clk(clk), .n_rst(n_rst), .clear(~timer_en), .rollover_val(bit_period), .count_enable(timer_en), .rollover_flag(rflag), .count_out(c1));
    flex_counter #(.SIZE(5)) f3(.clk(clk), .n_rst(n_rst), .clear(~timer_en), .rollover_val({'0, data_size + 4'b0010}), .count_enable(rflag), .rollover_flag(rflag2), .count_out(c2));

    assign shift_strobe = rflag;
    assign packet_done = rflag2 & timer_en;


endmodule

