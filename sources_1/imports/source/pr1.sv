`timescale 1ns / 10ps


module pr1 
import types::*;
#(
    // parameters
) (
    input logic clk,
    input logic [31:0] instr,
    input logic en,
    output logic [31:0] iaddr,
    input logic [7:0] out_rdata,
    output logic [7:0] out_wdata,
    output logic read_en, write_en, 
    output logic [31:0] apb_addr,
    output logic imem_ren, stall
);

    logic [31:0] next_pc, pc;
    assign iaddr = pc;


    logic [31:0] pcsrc1, pcsrc2;
    logic [31:0] if_id, next_if_id;

    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;
    aluop_t aluop;
    logic [31:0] imm;
    logic [1:0] alusrc1, alusrc2, memsrc;
    logic renm, wenm, memtoreg, wen, branch, jal, jalr, load_stall;
    logic mmio_stall;


    logic [31:0] rdata1, rdata2, reg_wdata;


    logic [152:0] id_ex, next_id_ex;


    logic [31:0] aluout;
    logic take_branch;

    logic [38:0] ex_mem, next_ex_mem;

    logic [31:0] mem_rdata;
    logic [31:0] mem_wb, next_mem_wb;

    assign pcsrc2 = pc + 32'h4;
    assign pcsrc1 = id_ex[118:87] + (id_ex[9] ? id_ex[86:55] : id_ex[150:119]);
    assign next_pc = (stall || ~en) ? pc : (((take_branch && id_ex[8]) || id_ex[9] || id_ex[10]) ? pcsrc1 : pcsrc2);
    assign stall = load_stall | mmio_stall;

    //if

    assign imem_ren = en & ~((take_branch && id_ex[8]) || id_ex[9] || id_ex[10]) & ~stall;
    
    always_comb begin
        if(stall || ~en) begin
            next_if_id = if_id;
        end
        else if(((take_branch && id_ex[8]) || id_ex[9] || id_ex[10])) begin
            next_if_id = '0;
        end
        else begin
            next_if_id = pc;
        end
    end

    //id

    
    
    decoder d1(
        .clk(clk),
        .instr(instr),
        .funct3(funct3), 
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .flush(((take_branch && id_ex[8]) || id_ex[9] || id_ex[10])),
        .aluop(aluop), 
        .imm(imm), 
        .alusrc1(alusrc1), .alusrc2(alusrc2),
        .renm(renm), .wenm(wenm), .memtoreg(memtoreg), .wen(wen), .branch(branch), .jal(jal), .jalr(jalr), .memsrc(memsrc), .load_stall(load_stall)
    );


    reg_file r1(
        .clk(clk),
        .rs1(rs1), .rs2(rs2), .rd(ex_mem[5:1]), 
        .wdata(reg_wdata),
        .wen(ex_mem[38] & ~mmio_stall & en),
        .rdata1(rdata1), .rdata2(rdata2)
    );


    always_comb begin
        if(stall || ~en) begin
            next_id_ex = id_ex;
        end
        else if(((take_branch && id_ex[8]) || id_ex[9] || id_ex[10])) begin
            next_id_ex = '0;
        end
        else begin
            next_id_ex[3:0] = aluop;
            next_id_ex[5:4] = alusrc1;
            next_id_ex[7:6] = alusrc2;
            next_id_ex[14:8] = {renm, wenm, wen, memtoreg, jal, jalr, branch};
            next_id_ex[17:15] = funct3;
            next_id_ex[22:18] = rd;
            next_id_ex[150:23] = {if_id, imm, rdata1, rdata2};
            next_id_ex[152:151] = memsrc;
        end
    end

    //ex
    alu a1(
        .aluop(aluop_t'(id_ex[3:0])),
        .a(id_ex[5:4] == 2'b00 ? (id_ex[86:55]) : (id_ex[5:4] == 2'b01 ? ex_mem[37:6] : (id_ex[5:4] == 2'b11 ? mem_wb[31:0] : id_ex[150:119]))), .b(id_ex[7:6] == 2'b00 ? (id_ex[54:23]) : (id_ex[7:6] == 2'b01 ? ex_mem[37:6] : (id_ex[7:6] == 2'b11 ? mem_wb[31:0] : id_ex[118:87]))),
        .funct3(id_ex[17:15]),
        .c(aluout),
        .take_branch(take_branch)
    );


    

    dmem memory(
        .clk(clk),
        .renm(id_ex[14]), .wenm(id_ex[13]),
        .addr(aluout), .wdata(|id_ex[152:151] ? (&id_ex[152:151] ? mem_wb[31:0] : ex_mem[37:6]) : id_ex[54:23]),
        .funct3(id_ex[17:15]),
        .rdata(mem_rdata),
        .stall(mmio_stall),
        .read_en(read_en), .write_en(write_en), .apb_addr(apb_addr), .out_rdata(out_rdata), .out_wdata(out_wdata)
    );


    always_comb begin
        if(mmio_stall || ~en) begin
            next_ex_mem = ex_mem;
        end
        else begin
            next_ex_mem[0] = id_ex[11];
            next_ex_mem[5:1] = id_ex[22:18];
            next_ex_mem[37:6] = aluout;
            next_ex_mem[38] = id_ex[12];
        end
    end

    //mem

    assign reg_wdata = ex_mem[0] ? mem_rdata : ex_mem[37:6];

    assign next_mem_wb = (stall || ~en )? mem_wb : reg_wdata;
    
    initial begin
            pc = '0;
            if_id = '0;
            id_ex = '0;
            ex_mem = '0;
            mem_wb = '0;
    end
    always_ff@(posedge clk) begin
            pc <= next_pc;
            if_id <= next_if_id;
            id_ex <= next_id_ex;
            ex_mem <= next_ex_mem;
            mem_wb <= next_mem_wb;
    end


    







endmodule

