`timescale 1ns / 10ps

module qspi_fsm #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [31:0] wdata, 
    input logic empty,
    input logic reset,
    inout wire sio1, sio2, sio3, sio4,
    output logic cs,
    output logic [31:0] rdata,
    output logic data_ready, done, underrun, busy
);

    typedef enum logic [3:0] {
        IDLE,
        GET_SEND_NUM,
        GET_READ_NUM,
        SEND_COMMAND,
        WAIT_COMMAND,
        LOAD_DATA,
        SEND_DATA,
        WAIT_SDATA,
        READ_DATA,
        WAIT_RDATA,
        LOAD_RDATA
    } state_t;

    state_t state, n_state;
    logic [31:0] write_data, n_write_data;
    logic [31:0] read_data, n_read_data;
    logic [31:0] send_num, n_send_num;
    logic [31:0] read_num, n_read_num;

    logic rw1, rw2, rw3, shift_en, load_en;
    logic sio1_out, sio2_out, sio3_out, sio4_out;
    logic single_or_quad, n_single_or_quad; 

    logic start_xip, n_start_xip;

    assign n_start_xip = state == GET_SEND_NUM ? write_data == 32'h11101011 : start_xip;




    assign n_single_or_quad = state == GET_SEND_NUM ? write_data == 32'h11101011 || write_data == 32'h00111000 || write_data[3:0] == 4'hF: single_or_quad; 

    logic [3:0][7:0] sr_out;
    assign rdata = read_data;

    always_ff@(negedge clk, negedge n_rst) begin
        if(~n_rst) begin
            state <= IDLE;
            write_data <= '0;
            read_data <= '0;
            send_num <= '0;
            read_num <= '0;
            single_or_quad <= 1'b0;
            start_xip <= 1'b0;
        end else begin
            if(reset) begin
                state <= IDLE;
                write_data <= '0;
                read_data <= '0;
                send_num <= '0;
                read_num <= '0;
                single_or_quad <= 1'b0;
                start_xip <= 1'b0;
            end else begin
                    state <= n_state;
                    write_data <= n_write_data;
                    read_data <= n_read_data;
                    send_num <= n_send_num;
                    read_num <= n_read_num;
                    single_or_quad <= n_single_or_quad;
                    start_xip <= n_start_xip;
            end
        end
    end

    flex_sr #(.MSB_FIRST(1), .POS(0)) f1(.clk(clk), .n_rst(n_rst), .shift_enable(shift_en), .load_enable(load_en), .parallel_in(single_or_quad ? {write_data[28], write_data[24], write_data[20], write_data[16], write_data[12], write_data[8], write_data[4], write_data[0]} : {write_data[7:0]}), .parallel_out(sr_out[0]), .serial_in(sio1), .serial_out(sio1_out));

    flex_sr #(.MSB_FIRST(1), .POS(0)) f2(.clk(clk), .n_rst(n_rst), .shift_enable(shift_en), .load_enable(load_en), .parallel_in({write_data[29], write_data[25], write_data[21], write_data[17], write_data[13], write_data[9], write_data[5], write_data[1]}), .parallel_out(sr_out[1]), .serial_in(sio2), .serial_out(sio2_out));

    flex_sr #(.MSB_FIRST(1), .POS(0)) f3(.clk(clk), .n_rst(n_rst), .shift_enable(shift_en), .load_enable(load_en), .parallel_in({write_data[30], write_data[26], write_data[22], write_data[18], write_data[14], write_data[10], write_data[6], write_data[2]}), .parallel_out(sr_out[2]), .serial_in(sio3), .serial_out(sio3_out));

    flex_sr #(.MSB_FIRST(1), .POS(0)) f4(.clk(clk), .n_rst(n_rst), .shift_enable(shift_en), .load_enable(load_en), .parallel_in({write_data[31], write_data[27], write_data[23], write_data[19], write_data[15], write_data[11], write_data[7], write_data[3]}), .parallel_out(sr_out[3]), .serial_in(sio4), .serial_out(sio4_out));

    assign sio1 = rw1 ? sio1_out : 1'bz;
    assign sio2 = rw2 ? sio2_out : 1'bz;
    assign sio3 = rw3 && single_or_quad ? sio3_out : (~single_or_quad ? 1'b1 : 1'bz);
    assign sio4 = rw3 && single_or_quad ? sio4_out : (~single_or_quad ? 1'b1 : 1'bz);

    logic [3:0] count_out;
    logic rollover_flag;
    logic ctr_en, ctr_clear;


    flex_counter #(.SIZE(4), .POS(0)) bit_counter(.clk(clk), .n_rst(n_rst), .count_enable(ctr_en), .clear(ctr_clear), .rollover_val(4'h8), .count_out(count_out), .rollover_flag(rollover_flag));


    always_comb begin
        n_state = state;
        n_write_data = write_data;
        n_read_data = read_data;
        n_send_num = send_num;
        n_read_num = read_num;
        

        rw1 = 1'b0;
        rw2 = 1'b0;
        rw3 = 1'b0; 
        shift_en = 1'b0;
        load_en = 1'b0;
        cs = 1'b1;
        data_ready = 1'b0;
        done = 1'b0;
        ctr_en = 1'b0;
        ctr_clear = 1'b1;
        underrun = 1'b0;
        busy = 1'b1;

        case(state) 
            IDLE: begin
                if(~empty) begin
                    n_write_data = wdata;
                    done = 1'b1;
                    n_state = GET_SEND_NUM;
                end
                busy = 1'b0;
            end
            GET_SEND_NUM: begin
                if(~empty) begin
                    n_read_num = wdata;
                    done = 1'b1;
                    n_state = GET_READ_NUM;
                end
            end
            GET_READ_NUM: begin
                if(~empty) begin
                    n_send_num = wdata;
                    done = 1'b1;
                    n_state = SEND_COMMAND;
                end
            end
            SEND_COMMAND: begin
                load_en = 1'b1;
                n_state = WAIT_COMMAND;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
            end
            WAIT_COMMAND: begin
                rw1 = 1'b1;
                rw2 = write_data[3:0] == 4'hF;
                rw3 = write_data[3:0] == 4'hF;
                cs = 1'b0;
                shift_en = 1'b1;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                if(count_out == 4'h7) begin
                    if(|send_num) begin
                        if(empty) begin
                            underrun = 1'b1;
                            n_state = IDLE;
                        end else begin
                            n_write_data = wdata;
                            done = 1'b1;
                            n_state = SEND_DATA;
                        end
                    end
                end
                if(rollover_flag) begin
                    if (|read_num) begin
                        n_state = READ_DATA;
                    end else begin
                        n_state = IDLE;
                    end
                end
            end
            SEND_DATA: begin
                rw1 = 1'b1;
                rw2 = 1'b1;
                rw3 = 1'b1;
                cs = 1'b0;
                load_en = 1'b1;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                n_state = WAIT_SDATA;
            end
            WAIT_SDATA: begin
                rw1 = 1'b1;
                rw2 = 1'b1;
                rw3 = 1'b1;
                cs = 1'b0;
                shift_en = 1'b1;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                if(count_out == 4'h1) begin
                    n_send_num = send_num - 1;
                end
                if(count_out == 4'h6) begin
                    if(|send_num) begin
                        if(empty) begin
                            underrun = 1'b1;
                            n_state = IDLE;
                        end
                        else begin
                            n_write_data = wdata;
                            done = 1'b1;
                        end
                    end
                end
                if(rollover_flag) begin
                    if(|send_num) begin
                        load_en = 1'b1;
                    end
                    else if (|read_num) begin
                        n_state = READ_DATA;
                    end
                    else begin
                        n_state = IDLE;
                    end
                end
            end
            READ_DATA: begin
                cs = 1'b0;
                shift_en = 1'b1;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                if(rollover_flag) begin
                    n_state = WAIT_RDATA;
                end
            end
            WAIT_RDATA: begin
                cs = 1'b0;
                shift_en = 1'b1;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                n_read_num = &read_num ? read_num : read_num - 1;
                n_read_data = single_or_quad ? {sr_out[3][1], sr_out[2][1], sr_out[1][1], sr_out[0][1], sr_out[3][0], sr_out[2][0], sr_out[1][0], sr_out[0][0], sr_out[3][3], sr_out[2][3], sr_out[1][3], sr_out[0][3], sr_out[3][2], sr_out[2][2], sr_out[1][2], sr_out[0][2], sr_out[3][5], sr_out[2][5], sr_out[1][5], sr_out[0][5], sr_out[3][5], sr_out[2][4], sr_out[1][4], sr_out[0][4], sr_out[3][7], sr_out[2][7], sr_out[1][7], sr_out[0][7], sr_out[3][6], sr_out[2][6], sr_out[1][6], sr_out[0][6]} : {24'b0, sr_out[1]};
                n_state = LOAD_RDATA;
            end
            LOAD_RDATA: begin
                cs = 1'b0;
                ctr_en = 1'b1;
                ctr_clear = 1'b0;
                shift_en = 1'b1;
                data_ready = 1'b1;
                if(|read_num) begin
                    n_state = READ_DATA;
                end
                else begin
                    n_state = IDLE;
                end
            end
            default: n_state = IDLE;
        endcase
    end

endmodule

