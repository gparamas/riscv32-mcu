`timescale 1ns / 10ps
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module rx_fifo #(
    // parameters
) (
    input logic clk, input logic n_rst,
    input logic [31:0] rx_data_in,
    input logic load, done, ce,
    output logic overrun, rx_empty,
    output logic [31:0] rx_data_out
);

    (* ram_style = "distributed" *) logic [31:0] regs [15:0];
    logic [3:0] write_addr, next_write_addr, read_addr, next_read_addr, rx_count, next_rx_count;
    logic rx_full;

`ifdef vivado
    initial begin
        regs = '{default: 0};
        write_addr = '0;
        read_addr = '0;
        rx_count = '0;
    end
    always_ff@(posedge clk) begin
        if(load && ~rx_full) begin 
            regs[write_addr] <= rx_data_in;
        end
        write_addr <= next_write_addr;
        read_addr <= next_read_addr;
        rx_count <= next_rx_count;
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            regs <= '{default: 0};
            write_addr <= '0;
            read_addr <= '0;
            rx_count <= '0;
        end else begin
            if(ce) begin
                if(load && ~rx_full) begin 
                    regs[write_addr] <= rx_data_in;
                end
                write_addr <= next_write_addr;
                read_addr <= next_read_addr;
                rx_count <= next_rx_count;
            end
        end
    end
`endif

    always_comb begin: REGS_AND_WRITE_ADDR
        next_write_addr = write_addr;
        overrun = 1'b0;
        if(load) begin
            if(~rx_full) begin
                next_write_addr = write_addr == 4'hF ? '0 : write_addr + 1;
            end
            else begin
                overrun = 1'b1;
            end
        end
    end

    always_comb begin: READ_ADDR
        next_read_addr = read_addr;
        if(done) begin
            next_read_addr = read_addr == 4'hF ? '0 : read_addr + 1;
        end
    end

    always_comb begin: rx_COUNT 
        next_rx_count = rx_count;
        if(load && !done) begin
            next_rx_count = rx_count + 1;
        end
        else if(done && !load) begin
            next_rx_count = rx_count - 1;
        end
    end

    assign rx_data_out = regs[read_addr];
    assign rx_empty = |rx_count;
    assign rx_full = &rx_count;

endmodule
