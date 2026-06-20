`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_qspi_fsm ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [31:0] wdata;
    logic empty, full, reset;
    wire sio1, sio2, sio3, sio4;
    logic cs;
    logic [31:0] rdata;
    logic data_ready, done;


    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(negedge clk);
        @(negedge clk);
        @(posedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    qspi_fsm #() DUT (.*);

    logic [7:0] received_cmd;
    logic sio1_drive, sio2_drive, sio3_drive, sio4_drive;
    logic sio_drive_en;

    assign sio1 = sio_drive_en ? sio1_drive : 1'bz;
    assign sio2 = sio_drive_en ? sio2_drive : 1'bz;
    assign sio3 = sio_drive_en ? sio3_drive : 1'bz;
    assign sio4 = sio_drive_en ? sio4_drive : 1'bz;

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


    task send_single;
        input logic [7:0] data;
        int i;
        begin
            sio_drive_en = 1'b1;
            for(i = 0; i < 8; i++) begin
                sio1_drive = data[7 - i];
                @(negedge clk);
            end
            sio_drive_en = 1'b0;
        end
    endtask

    task check_cmd;
        input logic [7:0] cmd;
        int i;
        begin
            wait(cs == 0);
            for(i = 0; i < 8; i++) begin
                @(negedge clk);
                received_cmd[7 - i] = sio1;
                if(sio1 !== cmd[7 - i]) begin
                    $display("Expected %b, got %b", cmd[7 - i], sio1);
                end
            end
        end
    endtask

    task check_byte_single;
        input logic [7:0] btc;
        int i;
        begin
            for(i = 0; i < 8; i++) begin
                @(negedge clk);
                received_cmd[7 - i] = sio1;
                if(sio1 !== btc[7 - i]) begin
                    $display("Expected %b, got %b", btc[7 - i], sio1);
                end
            end
        end
    endtask

    task send_cmd;
        input logic [7:0] cmd;
        input logic [31:0] send_num;
        input logic [31:0] read_num;
        begin
            @(posedge clk);
            wdata = send_num;
            empty = 1'b0;

            wait(done);
            @(negedge clk);
            @(posedge clk);
            wdata = read_num;

            wait(done);
            @(negedge clk);
            @(posedge clk);
            wdata = {24'b0, cmd};
            empty = 1'b1;
        end
    endtask

    task send_byte;
        input byte data;
        begin
            wait(done);
            @(negedge clk);
            @(posedge clk);
            wdata = {24'b0, data};
        end
    endtask

    task send_word;
        input logic [31:0] data;
        begin
            wait(done);
            @(negedge clk);
            @(posedge clk);
            wdata = data;
        end
    endtask

    task stream_quad;
        input logic [31:0] data;
        int i, j;
        begin
            sio_drive_en = 1'b1;
            for(i = 0; i < 4; i++) begin
                for(j = 0; j < 2; j++) begin
                    sio1_drive = data[i*8 + (1 - j)*4];
                    sio2_drive = data[i*8 + (1 - j)*4 + 1];
                    sio3_drive = data[i*8 + (1 - j)*4 + 2];
                    sio4_drive = data[i*8 + (1 - j)*4 + 3];
                    @(negedge clk);
                end
            end
            sio_drive_en = 1'b0;
        end
    endtask


    task send_rdsr;
        input int read_times;   
        int i;
        begin
            send_cmd(8'h05, 32'h0, read_times);
            check_cmd(8'h05);
            if(read_times == 32'hFFFFFFFF) begin
                for(;;) begin
                    send_single(8'hFF);
                    if(reset) break;
                end
            end else begin
                for(i = 0; i < read_times; i++) begin
                    send_single(8'hFF);
                end
            end
        end
    endtask

    task send_wrsr;
        input logic [7:0] sr;
        input logic [7:0] cr;
        begin
            fork
                begin
                    send_cmd(8'h01, 2, 0);
                    send_byte(sr);
                    send_byte(cr);
                end
                begin
                    check_cmd(8'h01);
                    check_byte_single(sr);
                    check_byte_single(cr);
                end
            join
        end
    endtask

    task send_4read;
        input logic [23:0] addr;
        input int read_times;
        int i;
        begin
            fork
                begin
                    send_cmd(8'hEB, 32'h2, read_times);
                    send_word({addr, 8'h00});
                    send_word(32'h0);
                    wait(DUT.state == READ_DATA);
                    for(i = 0; i < read_times; i++) begin
                        stream_quad(32'hFEFEFEFE);
                    end
                end
                
                check_cmd(8'hEB);

            join
        end
    endtask


    initial begin
        n_rst = 1;
        empty = 1'b1;
        full = 1'b0;
        reset = 1'b0;
        sio_drive_en = 1'b0;
        sio1_drive = 1'b0;
        sio2_drive = 1'b0;
        sio3_drive = 1'b0;
        sio4_drive = 1'b0;

        reset_dut;

        // fork
        //     send_rdsr(32'hFFFFFFFF);
        //     begin
        //         repeat(100) @(posedge clk);
        //         reset = 1'b1;
        //         @(posedge clk);
        //         reset = 1'b0;
        //     end
        // join

        //send_wrsr(8'hAA, 8'h55);
        send_4read(24'hDDDDDD, 2);


        repeat(10) @(posedge clk);    

        $finish;
    end
endmodule

/* verilator coverage_on */

