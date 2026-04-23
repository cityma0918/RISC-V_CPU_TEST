module pcRegister(
        input clk,
        input rst_n,
        input wen,
        input jal,
        input jalr,
        input conditional_jump_IF,
        input conditional_jump_EX,
        input [31:0] imm_from_pipeline,
        input [31:0] imm_IF,
        input [31:0] rs1_data,
        input predict_taken,
        input branch_prediction_fail,
        input isjump,
        input [31:0] pc_from_pipeline,
        output [31:0] pc
    );

    reg [31:0] pc_out;

    wire [31:0] predict_pc;
    wire [31:0] target_pc_EX;
    wire [31:0] final_next_pc;

    // 3. PC选择逻辑
    // 如果预解码器识别出是条件分支，则根据预测器的预测来决定下一PC
    // 否则 (对于jal, jalr, add, lw等所有其他指令)，默认为顺序执行
    assign predict_pc = conditional_jump_IF ?   (predict_taken ? (pc_out + imm_IF) : (pc_out + 4)) :
                                                (pc_out + 4);
    assign target_pc_EX  =  jalr ? (rs1_data + imm_from_pipeline) :                                    // 如果 jalr 为真，则...
                            jal  ? (pc_from_pipeline + imm_from_pipeline) :                            // 否则，如果 jal 为真，则...
                            (conditional_jump_EX && isjump) ? (pc_from_pipeline + imm_from_pipeline) :    // 否则，如果 条件分支跳转 为真，则...
                            (pc_from_pipeline + 4);                                                // 否则 (默认情况) ...
    assign final_next_pc = branch_prediction_fail ? target_pc_EX : predict_pc;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_out <= 32'h00000000;
        end
        else if(wen) begin
            pc_out <= final_next_pc;
        end
        else begin
            pc_out <= pc_out;
        end
    end

    assign pc = pc_out;

endmodule