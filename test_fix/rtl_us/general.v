

// DFF with write_enable , reset_val 
module dff_we_rv #(parameter width = 32,parameter reset_val = 32'h0)(
       input clk,
       input rst_n,
       input we,
       input [width-1:0] d,
       output[width-1:0] q
);

reg[width-1:0] r;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        r <= reset_val;
    end
    else begin
        if(we == 1'b1)begin
            r <= d;
        end
        else begin
            r <= r;
        end
    end
end

assign q = r;

endmodule

//DFF with write_enable,reset_val, flush,flush_val
module dff_we_fv #(parameter width = 32,parameter reset_val = 32'h0,parameter flush_val = 32'h0)(
       input clk,
       input rst_n,
       input we,
       input flush,
       input [width-1:0] d,
       output[width-1:0] q
);

reg[width-1:0] r;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        r <= reset_val;
    end
    else begin
        if(we == 1'b1)begin
            if(flush == 1'b1)begin
                r <= flush_val;
            end
            else begin
                r <= d;
            end
        end
        else begin
            r <= r;
        end
    end
end

assign q = r;

endmodule

module ControlSignalUnbinder (
    // --- 输入 ---
    input wire [36:0] i_control_bus,

    // --- 输出 ---

    // 类别 1: 存储器访问指令 (8 outputs)
    output wire o_lhu, o_lbu, o_lw, o_lh, o_lb,
    output wire o_sw, o_sh, o_sb,

    // 类别 2: 控制转移类指令 (8 outputs)
    output wire o_jal, o_jalr,
    output wire o_bgeu, o_bltu, o_bge, o_blt, o_bne, o_beq,

    // 类别 3: 移位运算 (6 outputs)
    output wire o_srai, o_sra, o_srli, o_srl, o_slli, o_sll,

    // 类别 4: 比较运算 (4 outputs)
    output wire o_sltiu, o_sltu, o_slti, o_slt,

    // 类别 5: 算术逻辑运算 (11 outputs)
    output wire o_xori, o_ori, o_andi, o_xor_, o_or_, o_and_,
    output wire o_addi, o_auipc, o_lui, o_sub, o_add
);

    // 使用赋值语句左侧的位拼接操作，将总线一次性解绑到所有输出端口。
    // `{}`内部的信号顺序必须与绑定时完全一致，以确保正确解码。
    assign {
        // [36:29] 存储器访问指令
        o_lhu, o_lbu, o_lw, o_lh, o_lb,
        o_sw, o_sh, o_sb,

        // [28:21] 控制转移类指令
        o_jal, o_jalr,
        o_bgeu, o_bltu, o_bge, o_blt, o_bne, o_beq,

        // [20:15] 移位运算
        o_srai, o_sra, o_srli, o_srl, o_slli, o_sll,

        // [14:11] 比较运算
        o_sltiu, o_sltu, o_slti, o_slt,

        // [10:0] 算术逻辑运算
        o_xori, o_ori, o_andi, o_xor_, o_or_, o_and_,
        o_addi, o_auipc, o_lui, o_sub, o_add
        
    } = i_control_bus;

endmodule
