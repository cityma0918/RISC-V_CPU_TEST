/**
 * @module BranchPredictor_2bit_SingleEntry
 * @brief 只有一个表项的2位饱和计数动态分支预测器
 */
module BranchPredictor_2bit_SingleEntry (
    // --- 通用输入 ---
    input wire clk,
    input wire rst_n,

    // --- 更新端口 ---
    input wire update_en,
    input wire branch_taken_actual, // 1=Taken, 0=Not Taken

    // --- 预测输出 ---
    output wire predicted_taken
);

    // 状态定义 (方便代码阅读)
    localparam STRONGLY_NOT_TAKEN = 2'b00;
    localparam WEAKLY_NOT_TAKEN   = 2'b01;
    localparam WEAKLY_TAKEN       = 2'b10;
    localparam STRONGLY_TAKEN     = 2'b11;

    // 单一的2位状态寄存器，代表唯一的BHT表项
    reg [1:0] prediction_state;

    // 预测逻辑：输出状态的最高位
    assign predicted_taken = prediction_state[1];

    // 更新逻辑：饱和计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时，初始化为强不跳转
            prediction_state <= STRONGLY_NOT_TAKEN;
        end else if (update_en) begin
            case (prediction_state)
                STRONGLY_NOT_TAKEN: // 00
                    prediction_state <= branch_taken_actual ? WEAKLY_NOT_TAKEN : STRONGLY_NOT_TAKEN;
                
                WEAKLY_NOT_TAKEN:   // 01
                    prediction_state <= branch_taken_actual ? WEAKLY_TAKEN : STRONGLY_NOT_TAKEN;
                
                WEAKLY_TAKEN:       // 10
                    prediction_state <= branch_taken_actual ? STRONGLY_TAKEN : WEAKLY_NOT_TAKEN;
                
                STRONGLY_TAKEN:     // 11
                    prediction_state <= branch_taken_actual ? STRONGLY_TAKEN : WEAKLY_TAKEN;
            endcase
        end
    end

endmodule