`timescale 1ns / 10ps
/* verilator coverage_off */

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
        fptr = $fopen("/home/ecegridfs/a/337mg016/r5processor/mmio.bin", "rb");
        size = $fread(imem, fptr);
        foreach (imem[i])
            imem[i] = {<<8{imem[i]}};
        $fclose(fptr);
    end

    task send_packet;
        input [7:0] data;
        input stop_bit;
        input int size;
        input int data_period;
    
        integer i;
        begin
            // First synchronize to away from clock's rising edge
            @(negedge clk)
            
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

    
    
    int i, j;
    initial begin
        uart_rx = 1'b1;
        
        n_rst = 1;

        reset_dut;
    

        for(i = 0; i < size / 4; i++) begin
            for(j = 0; j < 4; j++) begin
                send_packet(imem[i][8*j +: 8], 1, 8, 10);
            end
        end
        repeat(5000) @(posedge clk);

        $finish;
    end


endmodule

/* verilator coverage_on */

