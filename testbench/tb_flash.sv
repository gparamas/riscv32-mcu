`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_flash ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end


    logic SCLK, CS;
    wire SI, SO, WP, SIO3;

    // clockgen
    always begin
        SCLK = 0;
        #(CLK_PERIOD / 2.0);
        SCLK = 1;
        #(CLK_PERIOD / 2.0);
    end

    // task reset_dut;
    // begin
    //     n_rst = 0;
    //     @(posedge clk);
    //     @(posedge clk);
    //     @(negedge clk);
    //     n_rst = 1;
    //     @(posedge clk);
    //     @(posedge clk);
    // end
    // endtask

    flash #() DUT (.*);

    initial begin
        // n_rst = 1;

        //reset_dut;

        $finish;
    end
endmodule

/* verilator coverage_on */

