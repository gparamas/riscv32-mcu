package types;
    typedef enum logic [3:0] {
        NOOP, PASSTHROUGH, SUB, ADD, SHIFT_LEFT, SET_LESS_THAN, SET_LESS_THAN_U, XOR, SHIFT_RIGHT_A, SHIFT_RIGHT, OR, AND
    } aluop_t;
    typedef enum logic [3:0] {
        IDLE, STORE, LOAD, LUI, AUIPC, REG_REG, REG_IMM, JAL, JALR, BRANCH
    } instr_t;
endpackage
