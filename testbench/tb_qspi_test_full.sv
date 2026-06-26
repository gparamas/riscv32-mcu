`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_qspi_test_full ();

    localparam CLK_PERIOD = 10ns;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic clk, n_rst;
    logic psel, penable, pwrite;
    logic [2:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic psaterr;

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

    qspi_test_full #() DUT (.*);

    task apb_read;
        input logic [2:0] addr;
        begin
            @(posedge clk);
            psel = 1'b1;
            pwrite = 1'b0;
            paddr = addr;
            penable = 1'b0;

            @(posedge clk);
            psel = 1'b1;
            pwrite = 1'b0;
            paddr = addr;
            penable = 1'b1;

            @(posedge clk);
            psel = '0;
            pwrite = '0;
            paddr = '0;
            pwdata = '0;
            penable = '0;

        end
    endtask

    task apb_write;
        input logic [2:0] addr;
        input logic [31:0] data;
        begin
            @(posedge clk);
            psel = 1'b1;
            pwrite = 1'b1;
            paddr = addr;
            pwdata = data;
            penable = 1'b0;

            @(posedge clk);
            psel = 1'b1;
            pwrite = 1'b1;
            paddr = addr;
            pwdata = data;
            penable = 1'b1;

            @(posedge clk);
            psel = '0;
            pwrite = '0;
            paddr = '0;
            pwdata = '0;
            penable = '0;
            

        end
    endtask


    task send_wren;
    begin
        apb_write(3'h3, 32'h06);
        apb_write(3'h3, 32'h00);
        apb_write(3'h3, 32'h00);

        apb_read(3'h0);
        while(prdata[0] != 1'b0) begin
            apb_read(3'h0);
        end
    end
    endtask

    task send_wrsr;
    input byte cr, sr;
    begin
        apb_write(3'h3, 32'h01);
        apb_write(3'h3, 32'h0);
        apb_write(3'h3, 32'h2);
        apb_write(3'h3, {24'h0, sr});
        apb_write(3'h3, {24'h0, cr});

        apb_read(3'h0);
        while(prdata[0] != 1'b0) begin
            apb_read(3'h0);
        end
    end
    endtask

    task send_rdsr;
        input int read_times;
        int loop1, loop2;
        begin
            loop1 = 1;
            loop2 = 1;
            apb_write(3'h3, 32'h05);
            apb_write(3'h3, read_times);
            apb_write(3'h3, 32'h0);


            while(loop2) begin
                while(loop1) begin
                        apb_read(3'h0);
                        if(prdata[4]) begin
                            loop1 = 0;
                        end
                end
                apb_read(3'h2);
                if(prdata == 32'h40) begin
                    loop2 = 0;
                end
                loop1 = 1;
            end

            apb_write(3'h1, 32'h01);
        end
    endtask

    task send_4read;
        input int read_times;
        input logic [23:0] addr;
        input int xip;
        int i, loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, 32'h11101011);
            apb_write(3'h3, read_times);
            apb_write(3'h3, 32'h2);
            if(xip) begin
                apb_write(3'h3, {addr, 8'h0F});
            end
            else begin
                apb_write(3'h3, {addr, 8'h00});
            end
            apb_write(3'h3, 32'h0);

            for(i = 0; i < read_times; i++) begin
                while(loop1) begin
                    apb_read(3'h0);
                    if(prdata[4]) begin
                        loop1 = 0;
                    end
                end
                apb_read(3'h2);
                loop1 = 1;
            end
        end
    endtask

    task send_4read_xip;
        input int read_times;
        input logic [23:0] addr;
        int i, loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, {addr, 8'hFF});
            apb_write(3'h3, read_times);
            apb_write(3'h3, 1);
            apb_write(3'h3, 0);

            for(i = 0; i < read_times; i++) begin
                while(loop1) begin
                    apb_read(3'h0);
                    if(prdata[4]) begin
                        loop1 = 0;
                    end
                end
                apb_read(3'h2);
                loop1 = 1;
            end
        end
    endtask

    task send_4pp;
        input logic [23:0] addr;
        input logic [7:0] items[];
        int i, loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, 32'h00111000);
            apb_write(3'h3, 0);
            apb_write(3'h3, ((items.size() - 1) / 4) + 1);
            apb_write(3'h3, {addr, items[0]});
            for (i = 1; i < items.size(); i=i+4) begin
                while(loop1) begin
                    apb_read(3'h0);
                    if(~prdata[3]) begin
                        loop1 = 0;
                    end
                end
                apb_write(3'h3, {items[i], items[i+1], items[i+2], items[i+3]});
                loop1 = 1;
            end
        end
    endtask

    task send_rdscur;
        input int read_times;   
        int i, loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, 32'h2B);
            apb_write(3'h3, read_times);
            apb_write(3'h3, 32'h0);

            for(i = 0; i < read_times; i++) begin
                while(loop1) begin
                    apb_read(3'h0);
                    if(prdata[4]) begin
                        loop1 = 0;
                    end
                end
                apb_read(3'h2);
                loop1 = 1;
            end
        end
    endtask

    task send_burstread;
        input logic [7:0] mode;
        int loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, 32'hC0);
            apb_write(3'h3, 0);
            apb_write(3'h3, 32'h1);
            apb_write(3'h3, {24'h0, mode});
            while(loop1) begin
                apb_read(3'h0);
                if(~prdata[0]) begin
                    loop1 = 0;
                end
            end
        end
    endtask

    task send_se;
        input logic [23:0] addr;
        int loop1;
        begin
            loop1 = 1;
            apb_write(3'h3, 32'h20);
            apb_write(3'h3, 0);
            apb_write(3'h3, 32'h3);
            apb_write(3'h3, {24'h0, addr[23:16]});
            apb_write(3'h3, {24'h0, addr[15:8]});
            apb_write(3'h3, {24'h0, addr[7:0]});
            
            while(loop1) begin
                apb_read(3'h0);
                if(~prdata[0]) begin
                    loop1 = 0;
                end
            end
        end
    endtask


    initial begin
        n_rst = 1;
        psel = 1'b0;
        penable = 1'b0;
        pwrite = 1'b0;
        paddr = 1'b0;
        pwdata = '0;

        reset_dut;

        send_wren();

        repeat(5) @(posedge clk);

        send_wrsr(8'h40, 8'h40);

        repeat(5) @(posedge clk);

        send_rdsr(32'hFFFFFFFF);

        repeat(5) @(posedge clk);

        send_4read(10, 24'h0, 0);

        repeat(5) @(posedge clk);

        send_wren();

        repeat(5) @(posedge clk);

        send_4pp(24'h0, '{8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE});

        repeat(5) @(posedge clk);

        send_rdsr(32'hFFFFFFFF);

        repeat(5) @(posedge clk);

        send_rdscur(1);

        repeat(5) @(posedge clk);

        send_burstread(8'h02);

        repeat(5) @(posedge clk);

        send_4read(4, 24'h0, 1);

        repeat(5) @(posedge clk);

        send_4read_xip(4, 24'h10);

        repeat(5) @(posedge clk);
        
        send_wren();

        repeat(5) @(posedge clk);

        send_se(24'h0);

        repeat(5) @(posedge clk);

        send_rdsr(32'hFFFFFFFF);

        repeat(5) @(posedge clk);

        send_4read(10, 24'h0, 0);

        repeat(10) @(posedge clk);



        $finish;
    end
endmodule

/* verilator coverage_on */

