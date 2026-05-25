`timescale 1ns / 10ps

module tx_controller #(
    // parameters
) (
    input logic clk, n_rst,
    input logic tx_empty, packet_done, 
    output logic timer_en, load_en
);

    typedef enum logic [1:0] {
        IDLE, LOAD, SEND
    } state_t;

    state_t state, next_state;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end


    always_comb begin: NEXT_STATE_LOGIC
        case(state)
            IDLE: next_state = tx_empty ? LOAD : IDLE;
            LOAD: next_state = SEND;
            SEND: next_state = packet_done ? IDLE : SEND;
            default: next_state = state;
        endcase
    end

    always_comb begin: OUTPUT_LOGIC
        case(state)
            IDLE: {timer_en, load_en} = 2'b00;
            LOAD: {timer_en, load_en} = 2'b01;
            SEND: {timer_en, load_en} = 2'b10;
            default: {timer_en, load_en} = 2'b00;
        endcase
    end

endmodule

