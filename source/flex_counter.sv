`timescale 1ns / 10ps

module flex_counter #(
        SIZE = 8
    ) (
        input logic clk,
        input logic clear, count_enable,
        input logic [SIZE-1:0] rollover_val,
        output logic [SIZE-1:0] count_out,
        output logic rollover_flag
    );

    
    logic[SIZE-1:0] n_c_out;
    logic n_r_flag;

    initial begin
        {count_out, rollover_flag} = (SIZE + 1)'('b0);
    end

    always_ff@(posedge clk) begin
        {count_out , rollover_flag} <= {n_c_out, n_r_flag};
    end

    always_comb begin
        if(clear) begin
            n_c_out = SIZE'('b0);
        end
        else if(count_enable) begin
            if(count_out >= rollover_val) begin
                n_c_out = {(SIZE-1)'('b0), 1'b1};
            end
            else begin
                n_c_out = count_out + 1'b1;
            end 
        end
        else begin
            n_c_out = count_out;
        end
    end

    always_comb begin
        if(count_out == rollover_val - 1'b1 && count_enable || count_out == rollover_val && ~count_enable) begin
            n_r_flag = 1'b1;
        end
        else begin
            n_r_flag = 1'b0;
        end
    end

endmodule

