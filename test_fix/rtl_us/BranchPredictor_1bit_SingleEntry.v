/**
 * @module BranchPredictor_1bit_SingleEntry
 * @brief 只有一个表项的1位动态分支预测器 (最后结果预测器)
 */
module BranchPredictor_1bit_SingleEntry (
    // --- 通用输入 ---
    input wire clk,
    input wire rst_n,

    // --- 更新端口 ---
    // 输入：更新使能信号，当一个分支指令的结果确定时拉高
    input wire update_en,
    // 输入：分支指令的实际跳转结果 (1=Taken, 0=Not Taken)
    input wire branch_taken_actual,

    // --- 预测输出 ---
    // 输出：预测结果 (1=预测跳转, 0=预测不跳转)
    output wire predicted_taken
);

    // 单一的状态寄存器，代表唯一的BHT表项
    reg prediction_state;

    // 预测逻辑：直接输出当前状态
    assign predicted_taken = prediction_state;

    // 更新逻辑：用实际结果覆盖状态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时，默认预测不跳转
            prediction_state <= 1'b0;
        end else if (update_en) begin
            // 当更新信号有效时，用实际结果更新状态
            prediction_state <= branch_taken_actual;
        end
    end

endmodule