`timescale 1ns / 10ps
/* verilator coverage_off */
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
`ifndef vivado
module tb_top_level ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic uart_rx, uart_tx;

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

    top_level #() DUT (.*);

    logic [31:0] imem [4095:0];
    int fptr, size;
    
    initial begin
        imem = '{default: 0};
        fptr = $fopen("/home/ecegridfs/a/337mg016/r5processor/main.bin", "rb");
        size = $fread(imem, fptr);
        foreach (imem[i])
            imem[i] = {<<8{imem[i]}};
        $fclose(fptr);
    end

    logic [7:0] uart_out, uart_compiled;

    task send_packet;
        input [7:0] data;
        input stop_bit;
        input int size;
        input int data_period;
    
        integer i;
        begin
            // First synchronize to away from clock's rising edge
            @(negedge clk);
            
            // Send start bit
            uart_rx = 1'b0;
            #(data_period * CLK_PERIOD);
            
            // Send data bits
            for(i = 0; i < size; i = i + 1)
            begin
                uart_rx = data[i];
                #(data_period * CLK_PERIOD);
            end
            
            // Send stop bit
            uart_rx = stop_bit;
            #(data_period * CLK_PERIOD);
        end
    endtask

    task check_tx;
        input int data_period;
        integer i;
        begin
            wait(uart_tx == 1'b0);
            uart_out = '0;
            #(data_period * CLK_PERIOD / 2);

            for(i = 0; i < 8; i = i + 1)
            begin
                #(data_period * CLK_PERIOD);
                uart_out[i] = uart_tx;
            end
            #(data_period * CLK_PERIOD);
            uart_compiled = uart_out;

        end
    endtask

    
    
    int i, j;
    initial begin
        uart_rx = 1'b1;
        uart_out = '1;
        uart_compiled = '1;
        
        n_rst = 1;

        reset_dut;
    
        fork
            wait(DUT.pr_en == 1'b1);
            begin
                for(i = 0; i < size / 4; i++) begin
                    for(j = 0; j < 4; j++) begin
                        send_packet(imem[i][8*j +: 8], 1, 8, 100);
                    end
                end
            end
        join_any
        disable fork;
        fork
            repeat(20000) @(posedge clk);
            begin
                for(;;) begin
                    check_tx(100);
                end
            end
        join_any
        disable fork;

        $finish;
    end


endmodule
`else 
/* verilator coverage_off */

module tb_top_level ();

    localparam CLK_PERIOD = 83.33ns;
    localparam CLK_PERIOD_INTERNAL = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic uart_rx, uart_tx;

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
        @(posedge DUT.clk_out);
        @(posedge DUT.clk_out);
        @(negedge DUT.clk_out);
        n_rst = 1;
        @(posedge DUT.clk_out);
        @(posedge DUT.clk_out);
    end
    endtask

    top_level #() DUT (.*);

    logic [31:0] imem [4095:0];
    int fptr, size;
    
    initial begin
        imem = '{default: 0};
        fptr = $fopen("D:/riscv32-mcu/main.bin", "rb");
        size = $fread(imem, fptr);
        foreach (imem[i])
            imem[i] = {<<8{imem[i]}};
        $fclose(fptr);
    end

    logic [7:0] uart_out;

    task send_packet;
        input [7:0] data;
        input stop_bit;
        input int size;
        input int data_period;

        integer i;
        begin
            // First synchronize to away from clock's rising edge
            @(negedge DUT.clk_out);
            
            // Send start bit
            uart_rx = 1'b0;
            #(data_period * CLK_PERIOD_INTERNAL);
            
            // Send data bits
            for(i = 0; i < size; i = i + 1)
            begin
                uart_rx = data[i];
                #(data_period * CLK_PERIOD_INTERNAL);
            end
            
            // Send stop bit
            uart_rx = stop_bit;
            #(data_period * CLK_PERIOD_INTERNAL);
        end
    endtask
    logic [7:0] uart_compiled;

    task check_tx;
        input int data_period;
        integer i;
        begin
            wait(uart_tx == 1'b0);
            uart_out = '0;
            #(data_period * CLK_PERIOD_INTERNAL / 2);

            for(i = 0; i < 8; i = i + 1)
            begin
                #(data_period * CLK_PERIOD_INTERNAL);
                uart_out[i] = uart_tx;
            end

            uart_compiled = uart_out;
            #(data_period * CLK_PERIOD_INTERNAL);
        end
    endtask

    logic [31:0] curr_instr;
    
    int i, j;
    initial begin
        uart_rx = 1'b1;
        uart_out = 0;
        uart_compiled = '1;
        
        n_rst = 1;
        @(posedge DUT.clk_out);
    

        fork
            wait(DUT.pr_en == 1'b1);
            begin
                for(i = 0; i < size / 4; i++) begin
                    curr_instr = imem[i];
                    for(j = 0; j < 4; j++) begin
                        send_packet(imem[i][8*j +: 8], 1, 8, 100);
                    end
                end
            end
        join_any
        disable fork;
        fork
            repeat(20000) @(posedge DUT.clk_out);
            begin
                for(;;) begin
                    check_tx(100);
                end
            end
        join_any
        disable fork;

        $finish;
    end


endmodule

/* verilator coverage_on */



`endif

/* verilator coverage_on */

