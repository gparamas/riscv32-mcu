`timescale 1ns / 10ps

module qspi_apb_subordinate #(
    // parameters
) (
    input logic clk, n_rst,
    input logic psel, pwrite, penable,
    input logic [31:0] pwdata, 
    input logic [2:0] paddr,
    input logic [31:0] rx_data_out, 
    input logic rx_empty, tx_full, underrun, overrun, busy,
    output logic [31:0] prdata, tx_data_in,
    output logic psaterr,
    output logic done_rx, load_tx, reset
);

    logic [31:0] regs [3:0];
    logic [31:0] next_regs [3:0];

    logic [31:0] next_prdata;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            regs <= '{default: 0};
            prdata <= '0;
        end
        else begin
            regs <= next_regs;
            prdata <= next_prdata; 
        end
    end

    assign reset = regs[1][0];

    assign tx_data_in = regs[2];

    always_comb begin
        next_regs = regs;
        next_regs[0][3:0] = {tx_full, underrun ? 1'b1 : regs[0][2], overrun ? 1'b1 : regs[0][1], busy};
        next_regs[1] = '0;
        next_regs[3] = rx_data_out;
        done_rx = 1'b0;
        next_prdata = '0;
        psaterr = 1'b0;
        load_tx = 1'b0;
        if(psel) begin
            if(pwrite) begin
                if(paddr[0]) begin
                    next_regs[paddr[1:0]] = pwdata;
                    if(paddr[1]) begin
                        load_tx  = penable;
                    end
                    else begin
                        next_regs[0][2:1] = 2'b0;
                    end
                end
                else begin
                    psaterr = 1'b1;	
                end
            end
            else begin
                if(~paddr[0]) begin
                    next_prdata = regs[paddr[1:0]];
                    next_regs[0][4] = 1'b0;
                    if(paddr[1] && ~rx_empty) begin
                        done_rx = penable;
                        next_regs[0][4] = 1'b1;
                    end
                end
            end
        end
    end






endmodule

