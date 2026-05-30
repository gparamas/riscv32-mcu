`timescale 1ns / 10ps

module rcu (
    input logic clk, new_packet_detected, packet_done, framing_error, 
    output logic sbc_clear, sbc_enable, load_buffer, enable_timer
);

    typedef enum logic [3:0] {IDLE, CLEAR_F_ERROR, LOAD, CHECK_STOP_BIT, WAIT_STOP_BIT, SEND} state_t;

    state_t state = IDLE, n_state;

    always_ff@(posedge clk) begin
        state <= n_state;
    end

    always_comb begin
        case(state) 
            IDLE: n_state = new_packet_detected ? CLEAR_F_ERROR : state;
            CLEAR_F_ERROR: n_state = LOAD;
            LOAD: n_state = packet_done ? CHECK_STOP_BIT : state;
            CHECK_STOP_BIT: n_state = WAIT_STOP_BIT;
            WAIT_STOP_BIT: n_state = framing_error ? IDLE: SEND;
            SEND: n_state = IDLE;
            default: n_state = IDLE;
        endcase
    end

    always_comb begin
        case(state) 
            IDLE:  {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0;
            CLEAR_F_ERROR: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b1001;
            LOAD: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0001;
            CHECK_STOP_BIT: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0100;
            WAIT_STOP_BIT: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0100;
            SEND: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0010;
            default: {sbc_clear, sbc_enable, load_buffer, enable_timer} = 4'b0;
        endcase
    end

endmodule

