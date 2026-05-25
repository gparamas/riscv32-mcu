`timescale 1ns / 10ps

module apb_subordinate (
    input logic clk, n_rst, data_ready, overrun_error, framing_error, psel, penable, pwrite, tx_full, tx_busy,
    input logic [7:0] rx_data, pwdata,
    input logic [2:0] paddr,
    output logic data_read, psaterr, load,
    output logic [7:0] tx_data_in,
    output logic [3:0] data_size,
    output logic [7:0] prdata,
    output logic [13:0] bit_period,
    output logic uart_dreq
);
    logic [7:0] s_prdata, next_prdata;
    logic [7:0] tx_data, next_tx_data;
    logic s_load, next_load;
    logic next_dstatus, s_dstatus;
    logic [1:0] next_estatus, s_estatus;
    logic [3:0] s_dsize, next_dsize;
    logic [13:0] s_bitperiod, next_bitperiod;
    logic s_psaterr, next_psaterr;
    logic s_data_read, next_data_read;
    logic n_uart_dreq;

    assign n_uart_dreq = next_dstatus && ~s_dstatus;

    always_ff@(posedge clk or negedge n_rst) begin
        if(~n_rst) begin
            s_dstatus <= 1'b0;
            s_estatus <= 2'b0;
            s_prdata <= 8'b0;
            s_dsize <= 4'h8;
            s_bitperiod <= 14'ha;
            s_psaterr <= 1'b0;
            s_data_read <= 1'b0;
            tx_data <= 8'hFF;
            s_load <= 1'b0;
            uart_dreq <= '0;
        end
        else begin
            uart_dreq <= n_uart_dreq;
            s_estatus <= next_estatus;
            s_dstatus <= next_dstatus;
            s_prdata <= next_prdata;
            s_dsize <= next_dsize;
            s_bitperiod <= next_bitperiod;
            s_psaterr <= next_psaterr;
            s_data_read <= next_data_read;
            tx_data <= next_tx_data;
            s_load <= next_load;
        end
    end

    assign next_estatus = {overrun_error, framing_error};

    always_comb begin
        next_dstatus = data_ready;
        next_bitperiod = s_bitperiod;
        next_dsize = s_dsize;
        next_prdata = s_prdata;
        next_psaterr = s_psaterr;
        next_data_read = 1'b0;
        next_load = 1'b0;
        next_tx_data = tx_data;
        if(psel) begin
            if(pwrite) begin
                if(paddr == 3'h2) begin
                    next_bitperiod = {s_bitperiod[13:8], pwdata};
                    next_psaterr = 1'b0;
                end 
                else if(paddr == 3'h3) begin
                    next_bitperiod = {pwdata, s_bitperiod[7:0]};
                    next_psaterr = 1'b0;
                end 
                else if(paddr == 3'h4) begin
                    next_dsize = pwdata;
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h5) begin
                    next_tx_data = pwdata;
                    next_load = s_load == 1'b1 ? 1'b0 : 1'b1;
                    next_psaterr = 1'b0;
                end
                else begin
                    next_psaterr = 1'b1;
                end
            end
            else begin
                if(paddr == 3'h0) begin
                    next_prdata = {5'b0, tx_full, tx_busy, s_dstatus};
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h1) begin
                    next_prdata = {6'b0, s_estatus};
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h6) begin
                    next_prdata = (s_dsize == 4'h7) ? {1'b0, rx_data[7:1]} : ((s_dsize == 4'h5) ? {3'b0, rx_data[7:3]} : rx_data);
                    next_data_read = s_data_read ? 1'b0 : 1'b1;
                    next_dstatus = s_data_read ? 1'b0 : s_data_read;
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h2) begin
                    next_prdata = s_bitperiod[7:0];
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h3) begin
                    next_prdata = {2'b0, s_bitperiod[13:8]};
                    next_psaterr = 1'b0;
                end
                else if(paddr == 3'h4) begin
                    next_prdata = s_dsize;
                    next_psaterr = 1'b0;
                end
                else begin
                    next_psaterr = 1'b1;
                end
            end
        end
    end

    assign bit_period = s_bitperiod;
    assign data_size = s_dsize;
    assign data_read = s_data_read;
    assign prdata = s_prdata;
    assign psaterr = s_psaterr;
    assign tx_data_in = tx_data;
    assign load = s_load;

endmodule

