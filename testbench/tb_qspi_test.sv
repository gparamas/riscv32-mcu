`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_qspi_test ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [31:0] wdata; 
    logic empty, full;
    logic reset;
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
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(posedge clk);
        @(posedge clk);
    end
    endtask

    qspi_test #() DUT (.*);


    logic [7:0] received_cmd;

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


    // task send_single;
    //     input logic [7:0] data;
    //     int i;
    //     begin
    //         sio_drive_en = 1'b1;
    //         for(i = 0; i < 8; i++) begin
    //             sio1_drive = data[7 - i];
    //             @(negedge clk);
    //         end
    //         sio_drive_en = 1'b0;
    //     end
    // endtask

    task check_cmd;
        input logic [7:0] cmd;
        int i;
        begin
            wait(DUT.cs == 0);
            for(i = 0; i < 8; i++) begin
                @(negedge clk);
                received_cmd[7 - i] = DUT.sio1;
                if(DUT.sio1 !== cmd[7 - i]) begin
                    $display("Expected %b, got %b", cmd[7 - i], DUT.sio1);
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
                received_cmd[7 - i] = DUT.sio1;
                if(DUT.sio1 !== btc[7 - i]) begin
                    $display("Expected %b, got %b", btc[7 - i], DUT.sio1);
                end
            end
        end
    endtask

    task send_cmd;
        input logic [31:0] cmd;
        input logic [31:0] send_num;
        input logic [31:0] read_num;
        begin
            @(negedge clk);
            while(~DUT.q1.ce) 
                @(negedge clk);
            @(posedge clk);
            wdata = cmd;
            empty = 1'b0;

            wait(done);
            @(negedge clk);
            while(~DUT.q1.ce) 
                @(negedge clk);
            @(posedge clk);
            wdata = read_num;

            wait(done);
            @(negedge clk);
            while(~DUT.q1.ce) 
                @(negedge clk);
            @(posedge clk);
            wdata = send_num;
            empty = 1'b1;
        end
    endtask

    task send_byte;
        input byte data;
        begin
            wait(done);
            @(negedge clk);
            while(~DUT.q1.ce) 
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
            while(~DUT.q1.ce) 
                @(negedge clk);
            @(posedge clk);
            wdata = data;
        end
    endtask

    // task stream_quad;
    //     input logic [31:0] data;
    //     int i, j;
    //     begin
    //         sio_drive_en = 1'b1;
    //         for(i = 0; i < 4; i++) begin
    //             for(j = 0; j < 2; j++) begin
    //                 sio1_drive = data[i*8 + (1 - j)*4];
    //                 sio2_drive = data[i*8 + (1 - j)*4 + 1];
    //                 sio3_drive = data[i*8 + (1 - j)*4 + 2];
    //                 sio4_drive = data[i*8 + (1 - j)*4 + 3];
    //                 @(negedge clk);
    //             end
    //         end
    //         sio_drive_en = 1'b0;
    //     end
    // endtask


    task send_rdsr;
        input int read_times;   
        int i;
        begin
            send_cmd(32'h05, 32'h0, read_times);
            check_cmd(8'h05);
            if(read_times == 32'hFFFFFFFF) begin
                for(;;) begin
                    @(negedge clk);
                    if(reset) break;
                end
            end else begin
                for(i = 0; i < read_times; i++) begin
                    repeat(8) @(negedge clk);
                end
            end
        end
    endtask

    task send_rdscur;
        input int read_times;   
        int i;
        begin
            send_cmd(32'h2B, 32'h0, read_times);
            check_cmd(8'h2B);
            if(read_times == 32'hFFFFFFFF) begin
                for(;;) begin
                    @(negedge clk);
                    if(reset) break;
                end
            end else begin
                for(i = 0; i < read_times; i++) begin
                    repeat(8) @(negedge clk);
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
                    send_cmd(32'h01, 2, 0);
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
        input int xip;
        input logic [7:0] toggle;
        int i;
        begin
            fork
                begin
                    if(!xip) begin
                        send_cmd(32'h11101011, 32'h2, read_times);
                        send_word({addr, toggle});
                        send_word(32'h0);
                    end
                    else begin
                        send_cmd({addr, toggle}, 32'h1, read_times);
                        send_word(32'h0);
                    end
                    wait(DUT.q1.state == IDLE); 
                end
                
                check_cmd(8'hEB);

            join
        end
    endtask


    task send_wren;
    begin
            send_cmd(32'h06, 32'h0, 32'h0);
            wait(DUT.q1.state == IDLE);
    end
    endtask

    task send_4pp;
        input logic [23:0] addr;
        input logic [7:0] items[];
        int i;
        begin
            send_cmd(32'h00111000, ((items.size() - 1) / 4) + 1, 32'h0);
            send_word({addr, items[0]});
            for (i = 1; i < items.size(); i=i+4) begin
                send_word({items[i], items[i+1], items[i+2], items[i+3]});
            end
            wait(DUT.q1.state == IDLE);
        end
    endtask

    task send_burstread;
        input logic [7:0] mode;
        begin
           send_cmd(32'hC0, 1, 0); 
           send_byte(mode);
           wait(DUT.q1.state == IDLE);
        end
    endtask

    task send_se;
        input logic [23:0] addr;
        begin
            send_cmd({32'h20}, 3, 0);
            send_byte(addr[23:16]);
            send_byte(addr[15:8]);
            send_byte(addr[7:0]);
            wait(DUT.q1.state == IDLE);
        end
    endtask

    

    initial begin
        n_rst = 1;
        empty = 1'b1;
        full = 1'b0;
        reset = 1'b0;
        wdata = '0;

        reset_dut;

        //send_rdsr(3);
        send_wren();
        repeat(5) @(posedge clk);
        send_wrsr(8'h40, 8'h40);
        repeat(5) @(posedge clk);
        fork
            send_rdsr(32'hFFFFFFFF);
            begin
                wait(rdata[0] == 1'b1);
                wait(rdata[0] != 1'b1);
                reset = 1'b1;
                @(negedge clk);
                @(posedge clk);
                reset = 1'b0;
            end
        join

        repeat(5) @(posedge clk);

        send_4read(24'h0, 10, 0, 8'h0);

        repeat(5) @(posedge clk);

        send_wren();

        repeat(5) @(posedge clk);
        
        send_4pp(24'h0, '{8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'hEE, 8'hBB, 8'hCC, 8'hDD});

        repeat(5) @(posedge clk);


        fork
            send_rdsr(32'hFFFFFFFF);
            begin
                wait(rdata[0] == 1'b1);
                wait(rdata[0] != 1'b1);
                reset = 1'b1;
                @(negedge clk);
                @(posedge clk);
                reset = 1'b0;
            end
        join

        repeat(5) @(posedge clk);

        send_rdscur(1);

        repeat(5) @(posedge clk);
        
        send_burstread(8'h02);

        repeat(5) @(posedge clk);

        send_4read(24'h0, 12, 0, 8'h0F);
        
        repeat(5) @(posedge clk);

        send_4read(24'h0, 12, 1, 8'hFF);

        repeat(5) @(posedge clk);

        send_wren();

        repeat(5) @(posedge clk);

        send_se(24'h0);

        repeat(5) @(posedge clk);

        fork
            send_rdsr(32'hFFFFFFFF);
            begin
                wait(rdata[0] == 1'b1);
                wait(rdata[0] != 1'b1);
                reset = 1'b1;
                @(negedge clk);
                @(posedge clk);
                reset = 1'b0;
            end
        join

        repeat(5) @(posedge clk);

        send_4read(24'h0, 12, 0, 8'h0F);

        repeat(10) @(posedge clk);


        $finish;
    end
endmodule

/* verilator coverage_on */

