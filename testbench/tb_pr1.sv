`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_pr1 ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic [31:0] instr;
    logic [31:0] iaddr;

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
    end
    endtask

    pr1 #() DUT (.*);

    logic [31:0] imem [4095:0];
    int fptr;
    
    initial begin
        imem = '{default: 0};
        fptr = $fopen("/home/ecegridfs/a/337mg016/r5processor/main.bin", "rb");
        $fread(imem, fptr);
        foreach (imem[i])
            imem[i] = {<<8{imem[i]}};
        $fclose(fptr);
    end
    

    initial begin

        
        n_rst = 1;

        reset_dut;
    
    

        repeat (3000) begin
            instr = imem[iaddr >> 2];
            @(negedge clk);
        end

        $finish;
    end
endmodule

/* verilator coverage_on */

