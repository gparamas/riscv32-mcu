`timescale 1ns / 10ps

module timer (
  input logic clk, enable_timer,
  input logic [13:0] bit_period,
  input logic [3:0] data_size,
  output logic shift_strobe, packet_done  
);
    logic r_flag1, r_flag2, r_flag3;
    flex_counter #(.SIZE(4)) f1(.clk(clk), .clear(~enable_timer), .rollover_val(4'h3), .count_enable(~r_flag1), .rollover_flag(r_flag1));
    flex_counter #(.SIZE(14)) f2(.clk(clk), .clear(~enable_timer), .rollover_val(bit_period), .count_enable(r_flag1), .rollover_flag(r_flag2));
    flex_counter #(.SIZE(5)) f3(.clk(clk), .clear(~enable_timer), .rollover_val({'0, data_size + 4'b0001}), .count_enable(r_flag2), .rollover_flag(r_flag3));

    assign shift_strobe = r_flag2;
    assign packet_done = r_flag3 & enable_timer;

endmodule

