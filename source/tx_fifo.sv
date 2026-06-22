`timescale 1ns / 10ps
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module tx_fifo #(
    // parameters
    parameter int DEPTH = 32,
    parameter int WIDTH = 8,
    parameter CE = 0
) (
    input logic clk, input logic n_rst,
    input logic [WIDTH-1:0] tx_data_in,
    input logic load, done,
    input logic ce,
    output logic tx_full, tx_empty,
    output logic [WIDTH-1:0] tx_data_out
);

    (* ram_style = "distributed" *) logic [WIDTH - 1:0] regs [DEPTH - 1:0];
    logic [$clog2(DEPTH) - 1:0] write_addr, next_write_addr, read_addr, next_read_addr, tx_count, next_tx_count;

`ifdef vivado
    initial begin
        regs = '{default: 0};
        write_addr = '0;
        read_addr = '0;
        tx_count = '0;
    end
    always_ff@(posedge clk) begin
        if(load && ~tx_full) begin 
            regs[write_addr] <= tx_data_in;
        end
        write_addr <= next_write_addr;
        read_addr <= next_read_addr;
        tx_count <= next_tx_count;
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            regs <= '{default: 0};
            write_addr <= '0;
            read_addr <= '0;
            tx_count <= '0;
        end else begin
            if(CE) begin
                if(ce) begin
                    if(load && ~tx_full) begin 
                        regs[write_addr] <= tx_data_in;
                    end
                    write_addr <= next_write_addr;
                    read_addr <= next_read_addr;
                    tx_count <= next_tx_count;
                end
            end
            else begin
                if(load && ~tx_full) begin 
                    regs[write_addr] <= tx_data_in;
                end
                write_addr <= next_write_addr;
                read_addr <= next_read_addr;
                tx_count <= next_tx_count;
            end
        end
    end
`endif

    always_comb begin: REGS_AND_WRITE_ADDR
        next_write_addr = write_addr;
        if(load && ~tx_full) begin
            next_write_addr = write_addr == '1 ? '0 : write_addr + 1;
        end
    end

    always_comb begin: READ_ADDR
        next_read_addr = read_addr;
        if(done) begin
            next_read_addr = read_addr == '1 ? '0 : read_addr + 1;
        end
    end

    always_comb begin: TX_COUNT 
        next_tx_count = tx_count;
        if(load && !done) begin
            next_tx_count = tx_count + 1;
        end
        else if(done && !load) begin
            next_tx_count = tx_count - 1;
        end
    end

    assign tx_data_out = regs[read_addr];
    assign tx_empty = |tx_count;
    assign tx_full = &tx_count;




endmodule

