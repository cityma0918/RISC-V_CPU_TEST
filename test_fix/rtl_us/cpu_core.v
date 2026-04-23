`include "issue_uop.vh"

module cpu_core(
        input clk,
        input rst_n,
        output wire commit0_valid,
        output wire [31:0] commit0_pc,
        output wire [31:0] commit0_insn,
        output wire [4:0] commit0_rd,
        output wire [31:0] commit0_rd_wdata,
        output wire [31:0] commit0_mem_addr,
        output wire [3:0] commit0_mem_rmask,
        output wire [3:0] commit0_mem_wmask,
        output wire [31:0] commit0_mem_rdata,
        output wire [31:0] commit0_mem_wdata,
        output wire commit1_valid,
        output wire [31:0] commit1_pc,
        output wire [31:0] commit1_insn,
        output wire [4:0] commit1_rd,
        output wire [31:0] commit1_rd_wdata,
        output wire [31:0] commit1_mem_addr,
        output wire [3:0] commit1_mem_rmask,
        output wire [3:0] commit1_mem_wmask,
        output wire [31:0] commit1_mem_rdata,
        output wire [31:0] commit1_mem_wdata
    );

    integer dual_mode;
    wire dual_issue_enable = (dual_mode != 0);

    wire [31:0] iq_free_slots;
    wire front_flush;
    wire front_redirect_valid;
    wire [31:0] front_redirect_pc;
    wire bp_update_en;
    wire bp_update_taken;

    wire push0_valid;
    wire [31:0] push0_pc;
    wire [31:0] push0_instr;
    wire push0_pred_taken;
    wire push1_valid;
    wire [31:0] push1_pc;
    wire [31:0] push1_instr;
    wire push1_pred_taken;

    wire head0_valid;
    wire [31:0] head0_pc;
    wire [31:0] head0_instr;
    wire [`ISSUE_UOP_W-1:0] head0_uop;
    wire head1_valid;
    wire [31:0] head1_pc;
    wire [31:0] head1_instr;
    wire [`ISSUE_UOP_W-1:0] head1_uop;
    wire pop0;
    wire pop1;

    frontend_if_local u_frontend_if_local(
        .clk(clk),
        .rst_n(rst_n),
        .dual_enable(dual_issue_enable),
        .iq_free_slots(iq_free_slots),
        .flush(front_flush),
        .redirect_valid(front_redirect_valid),
        .redirect_pc(front_redirect_pc),
        .bp_update_en(bp_update_en),
        .bp_update_taken(bp_update_taken),
        .push0_valid(push0_valid),
        .push0_pc(push0_pc),
        .push0_instr(push0_instr),
        .push0_pred_taken(push0_pred_taken),
        .push1_valid(push1_valid),
        .push1_pc(push1_pc),
        .push1_instr(push1_instr),
        .push1_pred_taken(push1_pred_taken)
    );

    wire [4:0] push0_rs1;
    wire [4:0] push0_rs2;
    wire [4:0] push0_rd;
    wire [31:0] push0_imm;
    wire [6:0] push0_opcode;
    wire [2:0] push0_fun3;
    wire [6:0] push0_fun7;
    wire [3:0] push0_ALUctrl;
    wire push0_auipc;
    wire push0_jal;
    wire push0_jalr;
    wire push0_lui;
    wire push0_addi;
    wire push0_add;
    wire push0_sub;
    wire push0_sltiu;
    wire push0_sltu;
    wire push0_bne;
    wire push0_beq;
    wire push0_sll;
    wire push0_srl;
    wire push0_and_;
    wire push0_andi;
    wire push0_or_;
    wire push0_ori;
    wire push0_xor_;
    wire push0_xori;
    wire push0_srli;
    wire push0_slli;
    wire push0_bge;
    wire push0_bgeu;
    wire push0_sra;
    wire push0_srai;
    wire push0_blt;
    wire push0_bltu;
    wire push0_slt;
    wire push0_slti;
    wire push0_lbu;
    wire push0_lb;
    wire push0_sb;
    wire push0_sw;
    wire push0_lw;
    wire push0_sh;
    wire push0_lh;
    wire push0_lhu;

    wire [4:0] push1_rs1;
    wire [4:0] push1_rs2;
    wire [4:0] push1_rd;
    wire [31:0] push1_imm;
    wire [6:0] push1_opcode;
    wire [2:0] push1_fun3;
    wire [6:0] push1_fun7;
    wire [3:0] push1_ALUctrl;
    wire push1_auipc;
    wire push1_jal;
    wire push1_jalr;
    wire push1_lui;
    wire push1_addi;
    wire push1_add;
    wire push1_sub;
    wire push1_sltiu;
    wire push1_sltu;
    wire push1_bne;
    wire push1_beq;
    wire push1_sll;
    wire push1_srl;
    wire push1_and_;
    wire push1_andi;
    wire push1_or_;
    wire push1_ori;
    wire push1_xor_;
    wire push1_xori;
    wire push1_srli;
    wire push1_slli;
    wire push1_bge;
    wire push1_bgeu;
    wire push1_sra;
    wire push1_srai;
    wire push1_blt;
    wire push1_bltu;
    wire push1_slt;
    wire push1_slti;
    wire push1_lbu;
    wire push1_lb;
    wire push1_sb;
    wire push1_sw;
    wire push1_lw;
    wire push1_sh;
    wire push1_lh;
    wire push1_lhu;

    instr_Decode u_instr_decode0(
        .instr(push0_instr),
        .rs1(push0_rs1),
        .rs2(push0_rs2),
        .rd(push0_rd),
        .imm(push0_imm),
        .opcode(push0_opcode),
        .fun3(push0_fun3),
        .fun7(push0_fun7)
    );

    instr_Decode u_instr_decode1(
        .instr(push1_instr),
        .rs1(push1_rs1),
        .rs2(push1_rs2),
        .rd(push1_rd),
        .imm(push1_imm),
        .opcode(push1_opcode),
        .fun3(push1_fun3),
        .fun7(push1_fun7)
    );

    maincontroller u_maincontroller0(
        .fun3(push0_fun3),
        .fun7(push0_fun7),
        .opcode(push0_opcode),
        .ALUctrl(push0_ALUctrl),
        .addi(push0_addi),
        .auipc(push0_auipc),
        .jal(push0_jal),
        .jalr(push0_jalr),
        .lui(push0_lui),
        .add(push0_add),
        .sub(push0_sub),
        .sltiu(push0_sltiu),
        .sltu(push0_sltu),
        .bne(push0_bne),
        .beq(push0_beq),
        .sll(push0_sll),
        .srl(push0_srl),
        .and_(push0_and_),
        .andi(push0_andi),
        .or_(push0_or_),
        .ori(push0_ori),
        .xor_(push0_xor_),
        .xori(push0_xori),
        .srli(push0_srli),
        .slli(push0_slli),
        .bge(push0_bge),
        .bgeu(push0_bgeu),
        .sra(push0_sra),
        .srai(push0_srai),
        .blt(push0_blt),
        .bltu(push0_bltu),
        .slt(push0_slt),
        .slti(push0_slti),
        .lbu(push0_lbu),
        .lb(push0_lb),
        .sb(push0_sb),
        .sw(push0_sw),
        .lw(push0_lw),
        .sh(push0_sh),
        .lh(push0_lh),
        .lhu(push0_lhu)
    );

    maincontroller u_maincontroller1(
        .fun3(push1_fun3),
        .fun7(push1_fun7),
        .opcode(push1_opcode),
        .ALUctrl(push1_ALUctrl),
        .addi(push1_addi),
        .auipc(push1_auipc),
        .jal(push1_jal),
        .jalr(push1_jalr),
        .lui(push1_lui),
        .add(push1_add),
        .sub(push1_sub),
        .sltiu(push1_sltiu),
        .sltu(push1_sltu),
        .bne(push1_bne),
        .beq(push1_beq),
        .sll(push1_sll),
        .srl(push1_srl),
        .and_(push1_and_),
        .andi(push1_andi),
        .or_(push1_or_),
        .ori(push1_ori),
        .xor_(push1_xor_),
        .xori(push1_xori),
        .srli(push1_srli),
        .slli(push1_slli),
        .bge(push1_bge),
        .bgeu(push1_bgeu),
        .sra(push1_sra),
        .srai(push1_srai),
        .blt(push1_blt),
        .bltu(push1_bltu),
        .slt(push1_slt),
        .slti(push1_slti),
        .lbu(push1_lbu),
        .lb(push1_lb),
        .sb(push1_sb),
        .sw(push1_sw),
        .lw(push1_lw),
        .sh(push1_sh),
        .lh(push1_lh),
        .lhu(push1_lhu)
    );

    wire [36:0] push0_control_bus = {
        push0_lhu, push0_lbu, push0_lw, push0_lh, push0_lb,
        push0_sw, push0_sh, push0_sb,
        push0_jal, push0_jalr,
        push0_bgeu, push0_bltu, push0_bge, push0_blt, push0_bne, push0_beq,
        push0_srai, push0_sra, push0_srli, push0_srl, push0_slli, push0_sll,
        push0_sltiu, push0_sltu, push0_slti, push0_slt,
        push0_xori, push0_ori, push0_andi, push0_xor_, push0_or_, push0_and_,
        push0_addi, push0_auipc, push0_lui, push0_sub, push0_add
    };

    wire [36:0] push1_control_bus = {
        push1_lhu, push1_lbu, push1_lw, push1_lh, push1_lb,
        push1_sw, push1_sh, push1_sb,
        push1_jal, push1_jalr,
        push1_bgeu, push1_bltu, push1_bge, push1_blt, push1_bne, push1_beq,
        push1_srai, push1_sra, push1_srli, push1_srl, push1_slli, push1_sll,
        push1_sltiu, push1_sltu, push1_slti, push1_slt,
        push1_xori, push1_ori, push1_andi, push1_xor_, push1_or_, push1_and_,
        push1_addi, push1_auipc, push1_lui, push1_sub, push1_add
    };

    wire push0_r_type = (push0_opcode == 7'b0110011);
    wire push0_i_type = (push0_opcode == 7'b0010011) || (push0_opcode == 7'b0000011) || (push0_opcode == 7'b1100111);
    wire push0_s_type = (push0_opcode == 7'b0100011);
    wire push0_b_type = (push0_opcode == 7'b1100011);
    wire push0_supported = |push0_control_bus;
    wire push0_is_ls = push0_lb | push0_lbu | push0_lw | push0_lh | push0_lhu | push0_sb | push0_sh | push0_sw;
    wire push0_is_ctrl = push0_jal | push0_jalr | push0_beq | push0_bne | push0_blt | push0_bge | push0_bltu | push0_bgeu;
    wire push0_use_rs1 = push0_r_type | push0_i_type | push0_s_type | push0_b_type;
    wire push0_use_rs2 = push0_r_type | push0_s_type | push0_b_type;
    wire push0_writes_rd = push0_supported && !push0_s_type && !push0_b_type;
    wire push0_is_pairable_x = push0_supported && !push0_is_ls && !push0_is_ctrl;

    wire push1_r_type = (push1_opcode == 7'b0110011);
    wire push1_i_type = (push1_opcode == 7'b0010011) || (push1_opcode == 7'b0000011) || (push1_opcode == 7'b1100111);
    wire push1_s_type = (push1_opcode == 7'b0100011);
    wire push1_b_type = (push1_opcode == 7'b1100011);
    wire push1_supported = |push1_control_bus;
    wire push1_is_ls = push1_lb | push1_lbu | push1_lw | push1_lh | push1_lhu | push1_sb | push1_sh | push1_sw;
    wire push1_is_ctrl = push1_jal | push1_jalr | push1_beq | push1_bne | push1_blt | push1_bge | push1_bltu | push1_bgeu;
    wire push1_use_rs1 = push1_r_type | push1_i_type | push1_s_type | push1_b_type;
    wire push1_use_rs2 = push1_r_type | push1_s_type | push1_b_type;
    wire push1_writes_rd = push1_supported && !push1_s_type && !push1_b_type;
    wire push1_is_pairable_x = push1_supported && !push1_is_ls && !push1_is_ctrl;

    wire [`ISSUE_UOP_W-1:0] push0_uop = {
        push0_pred_taken,
        push0_is_pairable_x,
        push0_is_ctrl,
        push0_is_ls,
        push0_writes_rd,
        push0_use_rs2,
        push0_use_rs1,
        push0_control_bus,
        push0_ALUctrl,
        push0_imm,
        push0_rd,
        push0_rs2,
        push0_rs1
    };

    wire [`ISSUE_UOP_W-1:0] push1_uop = {
        push1_pred_taken,
        push1_is_pairable_x,
        push1_is_ctrl,
        push1_is_ls,
        push1_writes_rd,
        push1_use_rs2,
        push1_use_rs1,
        push1_control_bus,
        push1_ALUctrl,
        push1_imm,
        push1_rd,
        push1_rs2,
        push1_rs1
    };

    issue_queue #(
        .DEPTH(8)
    ) u_issue_queue(
        .clk(clk),
        .rst_n(rst_n),
        .flush(front_flush),
        .push0_valid(push0_valid),
        .push0_pc(push0_pc),
        .push0_instr(push0_instr),
        .push0_uop(push0_uop),
        .push1_valid(push1_valid),
        .push1_pc(push1_pc),
        .push1_instr(push1_instr),
        .push1_uop(push1_uop),
        .pop0(pop0),
        .pop1(pop1),
        .head0_valid(head0_valid),
        .head0_pc(head0_pc),
        .head0_instr(head0_instr),
        .head0_uop(head0_uop),
        .head1_valid(head1_valid),
        .head1_pc(head1_pc),
        .head1_instr(head1_instr),
        .head1_uop(head1_uop),
        .free_slots(iq_free_slots)
    );

    data_path u_data_path(
        .clk(clk),
        .rst_n(rst_n),
        .dual_issue_enable(dual_issue_enable),
        .issue0_valid(head0_valid),
        .issue0_pc(head0_pc),
        .issue0_instr(head0_instr),
        .issue0_uop(head0_uop),
        .issue1_valid(head1_valid),
        .issue1_pc(head1_pc),
        .issue1_instr(head1_instr),
        .issue1_uop(head1_uop),
        .issue_pop0(pop0),
        .issue_pop1(pop1),
        .front_flush(front_flush),
        .front_redirect_valid(front_redirect_valid),
        .front_redirect_pc(front_redirect_pc),
        .bp_update_en(bp_update_en),
        .bp_update_taken(bp_update_taken),
        .commit0_valid(commit0_valid),
        .commit0_pc(commit0_pc),
        .commit0_insn(commit0_insn),
        .commit0_rd(commit0_rd),
        .commit0_rd_wdata(commit0_rd_wdata),
        .commit0_mem_addr(commit0_mem_addr),
        .commit0_mem_rmask(commit0_mem_rmask),
        .commit0_mem_wmask(commit0_mem_wmask),
        .commit0_mem_rdata(commit0_mem_rdata),
        .commit0_mem_wdata(commit0_mem_wdata),
        .commit1_valid(commit1_valid),
        .commit1_pc(commit1_pc),
        .commit1_insn(commit1_insn),
        .commit1_rd(commit1_rd),
        .commit1_rd_wdata(commit1_rd_wdata),
        .commit1_mem_addr(commit1_mem_addr),
        .commit1_mem_rmask(commit1_mem_rmask),
        .commit1_mem_wmask(commit1_mem_wmask),
        .commit1_mem_rdata(commit1_mem_rdata),
        .commit1_mem_wdata(commit1_mem_wdata)
    );

    initial begin
        dual_mode = 0;
        if ($value$plusargs("dual=%d", dual_mode)) begin
        end
    end
endmodule
