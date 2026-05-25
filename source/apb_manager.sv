`timescale 1ns / 10ps

module apb_manager #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [7:0] prdata, wdata,
    input logic psaterr,
    input logic [31:0] apb_addr, 
    input logic read_en, write_en,
    output logic psel_uart, penable, pwrite, 
    output logic [2:0] paddr,
    output logic [7:0] pwdata,
    output logic [7:0] out_rdata
);
    typedef enum logic [1:0] {
        IDLE, ADDRESS_PHASE, DATA_PHASE
    } state_t;

    state_t state, n_state;
    logic n_psel_uart, n_penable, n_pwrite;
    logic [2:0] n_paddr;
    logic [7:0] n_pwdata;
    logic [7:0] rdata, n_rdata;
    logic [31:0] r_apb_addr, n_r_apb_addr;
    logic [7:0] r_wdata, n_r_wdata;
    logic r_write_en, n_r_write_en;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            state <= IDLE;
            psel_uart <= 1'b0;
            penable <= 1'b0;
            paddr <= '0;
            pwrite <= '0;
            pwdata <= '0;
            rdata <= '0;
            r_apb_addr <= '0;
            r_wdata <= '0;
            r_write_en <= '0;
        end
        else begin
            state <= n_state;
            psel_uart <= n_psel_uart;
            penable <= n_penable;
            paddr <= n_paddr;
            pwrite <= n_pwrite;
            pwdata <= n_pwdata;
            rdata <= n_rdata;
            r_apb_addr <= n_r_apb_addr;
            r_wdata <= n_r_wdata;
            r_write_en <= n_r_write_en;
        end
    end

    
    always_comb begin
        n_psel_uart = 1'b0;
        n_paddr = 1'b0;
        n_penable = 1'b0;
        n_pwrite = 1'b0;
        n_state = IDLE;
        n_pwdata = wdata;
        n_rdata = rdata;
        n_r_apb_addr = r_apb_addr;
        n_r_wdata = r_wdata;
        n_r_write_en = r_write_en;
        if((read_en | write_en) && (state == IDLE)) begin
            if(apb_addr >= 32'h25000) begin
                n_paddr = apb_addr[2:0];
                n_psel_uart = 1'b1;
                n_penable = 1'b0;
                n_pwrite = write_en;
                n_pwdata = wdata;
                n_state = ADDRESS_PHASE;
                n_r_apb_addr = apb_addr;
                n_r_wdata = wdata;
                n_r_write_en = write_en;
            end
        end
        else if (state == ADDRESS_PHASE) begin
            n_penable = 1'b1;
            n_psel_uart = 1'b1;
            n_pwrite = r_write_en;
            n_pwdata = r_wdata;
            n_paddr = r_apb_addr[2:0];
            n_state = DATA_PHASE;
        end	
        else if (state == DATA_PHASE) begin
            n_state = IDLE;
            if(!pwrite) begin
                n_rdata = prdata;
            end
        end
    end

    always_comb begin
        if(state == DATA_PHASE && pwrite == 1'b0) begin
            out_rdata = prdata;
        end
        else begin
            out_rdata = rdata;
        end
    end



endmodule

