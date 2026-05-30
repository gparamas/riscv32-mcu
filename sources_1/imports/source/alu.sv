`timescale 1ns / 10ps

module alu 
    import types::*;
#(
    // parameters
) (
    input aluop_t aluop,
    input logic [31:0] a, b,
    input logic [2:0] funct3,
    output logic [31:0] c,
    output logic take_branch
);

    logic ltu, equal, lt;

    assign equal = a == b;
    assign lt = $signed(a) < $signed(b);
    assign ltu = a < b;

    assign take_branch = ((~(|funct3[2:1])) & (equal ^ funct3[0])) |
			((funct3[2] & ~funct3[1]) & (lt ^ funct3[0])) |
			(&funct3[2:1] & (ltu ^ funct3[0]));



    always_comb begin
        case(aluop)
            PASSTHROUGH: c = b;
            SUB: c = a - b;
            ADD: c = a + b;
            SHIFT_LEFT: c = a << b;
            SHIFT_RIGHT: c = a >> b;
            SHIFT_RIGHT_A: c = $signed(a) >>> b;
            SET_LESS_THAN: c = lt ? 1 : 0;
            SET_LESS_THAN_U: c = ltu ? 1 : 0;
            XOR: c = a ^ b;
            AND: c = a & b;
            OR: c = a | b;
            ADD4: c = a + 32'h4;
            default: c = a + b;
        endcase
    end


endmodule

