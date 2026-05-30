`timescale 1ns / 10ps

module dma #(
    // parameters
) (
    input logic clk,
    input logic [7:0] rdata,
    input logic uart_dreq,
    output logic read_en, write_en, pr_en,
    output logic [31:0] wdata,
    output logic [31:0] waddr,
    output logic [31:0] raddr
);
    typedef enum logic [3:0] {
        IDLE, READ1, WAIT1, READ2, WAIT2, READ3, WAIT3, READ4, WAIT4, WAIT5, WRITE, INCR, DONE
    } state_t;

    state_t state, n_state;
    logic [31:0] instr, n_instr;
    logic [31:0] c_waddr, n_waddr;

    assign waddr = c_waddr;

    initial begin
        state = IDLE;
        instr = '0;
        c_waddr = '0;
    end

    always_ff@(posedge clk) begin
        state <= n_state;
        instr <= n_instr;
        c_waddr <= n_waddr;
    end

    always_comb begin
        case(state)
            IDLE: n_state = uart_dreq ? READ1 : state;
            READ1: n_state = WAIT1;
            WAIT1: n_state = uart_dreq ? READ2 : state;
            READ2: n_state = rdata == 8'hFF ? DONE: WAIT2;
            WAIT2: n_state = uart_dreq ? READ3 : state;
            READ3: n_state = WAIT3;
            WAIT3: n_state = uart_dreq ? READ4 : state;
            READ4: n_state = WAIT4;
            WAIT4: n_state = WAIT5;
            WAIT5: n_state = WRITE;
            WRITE: n_state = INCR;
            INCR: n_state = IDLE;
            default: n_state = state;
        endcase
    end

    always_comb begin
        if(state == INCR) begin
	        n_waddr = c_waddr + 32'h4;
        end
        else begin
	        n_waddr = c_waddr;
        end
    end

    always_comb begin
        case(state)
            READ2: n_instr = {instr[31:8], rdata};
            READ3: n_instr = {instr[31:16], rdata, instr[7:0]};
            READ4: n_instr = {instr[31:24], rdata, instr[15:0]};
            WAIT5: n_instr = {rdata, instr[23:0]};
            default: n_instr = instr;
        endcase
    end

    always_comb begin
        case(state)
            READ1, READ2, READ3, READ4: {read_en, write_en, raddr, wdata, pr_en} = {1'b1, 1'b0, 32'h2C006, 32'b0, 1'b0};
            WRITE: {read_en, write_en, raddr, wdata, pr_en} = {1'b0, 1'b1, 32'b0, instr, 1'b0};
            DONE: {read_en, write_en, raddr, wdata, pr_en} = {1'b0, 1'b0, 32'b0, 32'b0, 1'b1};
            default: {read_en, write_en, raddr, wdata, pr_en} = '0;
        endcase
    end



endmodule

