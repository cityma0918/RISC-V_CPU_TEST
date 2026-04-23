//details 这是一个纯组合逻辑单元，用于快速识别条件分支并提取其立即数偏移量。
module Branch_PreDecode (
    // 输入：来自指令存储器的32位指令码
    input wire [31:0] instruction_if,

    // 输出：识别信号
    output wire is_conditional_branch_if, // 这是一条条件分支指令吗？

    // 输出：提取并经过符号位扩展的32位立即数偏移量
    output wire [31:0] imm_offset_if
);

    // RISC-V B-Type (条件分支) 的操作码常量
    localparam OPCODE_BRANCH = 7'b1100011;

    // --- 1. 识别指令类型 ---
    // 仅当指令的opcode匹配B-Type时，输出1
    assign is_conditional_branch_if = (instruction_if[6:0] == OPCODE_BRANCH);

    // --- 2. 重组B-Type指令的立即数 ---
    // 这是预解码的核心逻辑，通过硬连线(wire concatenation)实现
    // B-Type immediate: imm[12|10:5|4:1|11]
    // 来自指令位: inst[31|30:25|11:8|7]s
    wire [31:0] b_imm_ext;
    assign b_imm_ext = {{19{instruction_if[31]}}, // 符号位扩展 (imm[12]是符号位)
                        instruction_if[31],     // imm[12]
                        instruction_if[7],      // imm[11]
                        instruction_if[30:25],  // imm[10:5]
                        instruction_if[11:8],   // imm[4:1]
                        1'b0};                  // imm[0] is always 0

    // --- 3. 选择最终的立即数输出 ---
    // 如果是条件分支，则输出重组后的立即数；否则，输出0。
    assign imm_offset_if = is_conditional_branch_if ? b_imm_ext : 32'h0;

endmodule