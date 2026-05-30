`timescale 1ns / 10ps
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
        fptr = $fopen("D:/vivado-projects/project_3/project_3.srcs/sim_1/imports/riscv32-mcu/main.bin", "rb");
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
        end
    endtask

    
    
    int i, j;
    initial begin
        uart_rx = 1'b1;
        uart_out = 0;
        
        n_rst = 1;

        reset_dut;
    

        for(i = 0; i < size / 4; i++) begin
            for(j = 0; j < 4; j++) begin
                send_packet(imem[i][8*j +: 8], 1, 8, 10);
            end
        end
        fork
            repeat(500) @(posedge clk);
            begin
                for(;;) begin
                    check_tx(10);
                end
            end
        join_any
        disable fork;

        $finish;
    end


endmodule

/* verilator coverage_on */

