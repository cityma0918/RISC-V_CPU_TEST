module instr_Decode(
        input [31:0] instr,
        output [4:0] rs1,
        output [4:0] rs2,
        output [4:0] rd,
        output [31:0] imm,
        output [6:0] opcode,
        output [2:0] fun3,
        output [6:0] fun7
    );
    
    //R型指令不需要生成立即数
    wire U_type;
    wire I_type;
    wire J_type;
    wire B_type;
    wire S_type;

    wire [31:0] U_imm;
    wire [31:0] I_imm;
    wire [31:0] J_imm;
    wire [31:0] B_imm;
    wire [31:0] S_imm;

    assign opcode = instr[6:0];
    assign fun3 = instr[14:12];
    assign fun7 = instr[31:25];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];

    //通过相应字段判断指令类型    
    assign U_type = (opcode == 7'b0010111) | (opcode == 7'b0110111);
    assign I_type = (opcode == 7'b0000011) | (opcode == 7'b0010011) | (opcode == 7'b1100111);
    assign J_type = (opcode == 7'b1101111);
    assign B_type = (opcode == 7'b1100011);
    assign S_type = (opcode == 7'b0100011);

    assign U_imm = {instr[31:12], {12{1'b0}}};
    assign I_imm = {{20{instr[31]}}, instr[31:20]};
    assign J_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], {1'b0}};
    assign B_imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], {1'b0}};
    assign S_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    
    assign imm = I_type ? I_imm :U_type ? U_imm :J_type ? J_imm :B_type ? B_imm : S_imm;

endmodule








