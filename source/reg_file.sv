`timescale 1ns / 10ps
//`include "D:/vivado-projects/project_3/project_3.srcs/sources_1/imports/source/header.sv"
module reg_file #(
    // parameters
) (
    input logic clk, input logic n_rst,
    input logic [4:0] rs1, rs2, rd, 
    input logic [31:0] wdata,
    input logic wen, 
    output logic [31:0] rdata1, rdata2
);
    logic [31:0] regfile [31:0];

`ifdef vivado
    initial begin
        regfile = '{default: 0};
    end
    always_ff@(posedge clk) begin
        if(wen && rd != '0) begin
            regfile[rd] <= wdata; 
        end
    end
`else
    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            regfile <= '{default: 0};
        end
        else if(wen && rd != '0) begin
            regfile[rd] <= wdata; 
        end
    end
`endif


    assign rdata1 = rs1 == '0 ? '0 : regfile[rs1];
    assign rdata2 = rs2 == '0 ? '0 : regfile[rs2];



endmodule

