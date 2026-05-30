`timescale 1ns / 10ps

module tx_fifo #(
    // parameters
) (
    input logic clk,
    input logic [7:0] tx_data_in,
    input logic load, done,
    output logic tx_full, tx_empty,
    output logic [7:0] tx_data_out
);

    logic [31:0][7:0] regs = '0, next_regs;
    logic [4:0] write_addr = '0, next_write_addr, read_addr = '0, next_read_addr, tx_count = '0, next_tx_count;

    always_ff@(posedge clk) begin
        regs <= next_regs;
        write_addr <= next_write_addr;
        read_addr <= next_read_addr;
        tx_count <= next_tx_count;
    end

    always_comb begin: REGS_AND_WRITE_ADDR
        next_regs = regs;
        next_write_addr = write_addr;
        if(load && ~tx_full) begin
            next_regs[write_addr] = tx_data_in;
            next_write_addr = write_addr == 5'h1F ? '0 : write_addr + 1;
        end
    end

    always_comb begin: READ_ADDR
        next_read_addr = read_addr;
        if(done) begin
            next_read_addr = read_addr == 5'h1F ? '0 : read_addr + 1;
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

