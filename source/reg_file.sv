`timescale 1ns / 10ps

module reg_file #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [4:0] rs1, rs2, rd, 
    input logic [31:0] wdata,
    input logic wen, 
    output logic [31:0] rdata1, rdata2
);
    logic [31:0][31:0] regfile;
    logic [31:0][31:0] n_regfile;

    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            regfile <= '0;
            //regfile[2] <= 32'h00032B98;
        end
        else begin
            regfile <= n_regfile;
        end
    end

    always_comb begin
        n_regfile = regfile;
        if(wen) begin
	        n_regfile[rd] = wdata;
        end
        n_regfile[0] = '0;
    end

    assign rdata1 = regfile[rs1];
    assign rdata2 = regfile[rs2];



endmodule

