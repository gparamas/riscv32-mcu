`timescale 1ns / 10ps

module decoder 
    import types::*;
 #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [31:0] instr,
    input logic flush,
    output logic [2:0] funct3, 
    output logic [4:0] rs1, rs2, rd,
    output aluop_t aluop, 
    output logic [31:0] imm, 
    output logic [1:0] alusrc1, alusrc2, memsrc,
    output logic renm, wenm, memtoreg, wen, branch, jal, jalr
);
    
    logic [4:0] prd, prd2;
    instr_t instr_type;




    always_ff@(posedge clk, negedge n_rst) begin
        if(~n_rst) begin
            prd <= '0;
            prd2 <= '0;
        end
        else begin
            prd <= flush ? '0 : rd & {5{instr_type != BRANCH && instr_type != STORE}};
            prd2 <= flush ? '0 : prd;
        end
    end

    logic [6:0] opcode;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign funct7 = instr[31:25];
   
    always_comb begin
        if(opcode[6]) begin
            if(opcode[3]) begin
                instr_type = JAL;
            end
            else if(opcode[2]) begin
                instr_type = JALR;
            end
            else begin
                instr_type = BRANCH;
            end
        end
        else if(&opcode[1:0] && ~opcode[4]) begin
            if(opcode[5]) begin
                instr_type = STORE;
            end
            else begin
                instr_type = LOAD;
            end
        end
        else if(opcode[2]) begin
            if(opcode[5]) begin
                instr_type = LUI;
            end
            else begin
                instr_type = AUIPC;
            end
        end
        else if(opcode[5]) begin
            instr_type = REG_REG;
        end
        else begin
            instr_type = REG_IMM;
        end
    end

    always_comb begin
        branch = '0; jal = '0; jalr = '0;
        memsrc = 2'b0;
        case(instr_type) 
            REG_REG: begin
                alusrc1 = (rs1 == prd && rs1 != 5'b0) ? 2'h1 : ((rs1 == prd2 && rs1 != 5'b0) ? 2'h3 : 2'h0);
                alusrc2 = (rs2 == prd && rs1 != 5'b0) ? 2'h1 : ((rs2 == prd2 && rs2 != 5'b0) ? 2'h3 : 2'h0);
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
            end
            REG_IMM: begin
                alusrc1 = (rs1 == prd && rs1 != 5'b0) ? 2'h1 : ((rs1 == prd2 && rs1 != 5'b0) ? 2'h3 : 2'h0);
                alusrc2 = 2'h2;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
            end
            LOAD: begin
                alusrc1 = (rs1 == prd && rs1 != 5'b0) ? 2'h1 : ((rs1 == prd2 && rs1 != 5'b0) ? 2'h3 : 2'h0);
                alusrc2 = 2'h2;
                renm = 1'b1; wenm = 1'b0; memtoreg = 1'b1;
                wen = 1'b1;
            end
            STORE: begin
                alusrc1 = (rs1 == prd && rs1 != 5'b0) ? 2'h1 : ((rs1 == prd2 && rs1 != 5'b0) ? 2'h3 : 2'h0);
                alusrc2 = 2'h2;
                memsrc = (rs2 == prd && rs2 != 5'b0) ? 2'b01 : ((rs2 == prd2 && rs2 != 5'b0) ? 2'b11 : 2'b0);
                renm = 1'b0; wenm = 1'b1; memtoreg = 1'b0;
                wen = 1'b0;
            end
            LUI:  begin
                alusrc1 = 2'b0;
                alusrc2 = 2'h2;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
            end
            AUIPC: begin
                alusrc1 = 2'h2;
                alusrc2 = 2'h2;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
            end
            BRANCH: begin
                alusrc1 = (rs1 == prd && rs1 != 5'b0) ? 2'h1 : ((rs1 == prd2 && rs1 != 5'b0) ? 2'h3 : 2'h0);
                alusrc2 = (rs2 == prd && rs2 != 5'b0) ? 2'h1 : ((rs2 == prd2 && rs2 != 5'b0) ? 2'h3 : 2'h0);
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b0; 
                branch = 1'b1; jal = 1'b0; jalr = 1'b0;
            end
            JALR: begin
                alusrc1 = 2'h2;
                alusrc2 = 2'b0;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1; 
                branch = 1'b0; jal = 1'b0; jalr = 1'b1;
            end
            JAL: begin
                alusrc1 = 2'h2;
                alusrc2 = 2'b0;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
                branch = 1'b0; jal = 1'b1; jalr = 1'b0;
            end
            default: begin
                alusrc1 = 2'h0;
                alusrc2 = 2'b0;
                renm = 1'b0; wenm = 1'b0; memtoreg = 1'b0;
                wen = 1'b1;
                branch = 1'b0; jal = 1'b0; jalr = 1'b0;
            end
        endcase
    end

    always_comb begin
        case(instr_type)
            STORE, LOAD, AUIPC, JAL, JALR: aluop = ADD;
            LUI: aluop = PASSTHROUGH;
            REG_REG, REG_IMM: 
                case(funct3)
                    3'b000: aluop = (instr_type == REG_REG && funct7[5]) ? SUB : ADD;
                    3'b001: aluop = SHIFT_LEFT;
                    3'b010: aluop = SET_LESS_THAN;
                    3'b011: aluop = SET_LESS_THAN_U;
                    3'b100: aluop = XOR;
                    3'b101: aluop = funct7[5] ? SHIFT_RIGHT_A : SHIFT_RIGHT;
                    3'b110: aluop = OR;
                    3'b111: aluop = AND;
                    default: aluop = ADD;
                endcase
            default: aluop = ADD;
        endcase
    end

    always_comb begin
        case(instr_type)
            REG_IMM, LOAD, JALR:
                imm = instr_type == REG_IMM && (funct3 == 3'b101 || funct3 == 3'b001) ? {27'b0, instr[24:20]} : {{21{instr[31]}}, instr[30:20]};
            STORE:
                imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
            AUIPC, LUI:
                imm = {instr[31:12], 12'b0};
            BRANCH: 
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            JAL: 
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};  
            default: imm = instr;
        endcase
    end
	


    


endmodule

