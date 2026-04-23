`include "issue_uop.vh"

module data_path(
        input  wire clk,
        input  wire rst_n,
        input  wire dual_issue_enable,
        input  wire issue0_valid,
        input  wire [31:0] issue0_pc,
        input  wire [31:0] issue0_instr,
        input  wire [`ISSUE_UOP_W-1:0] issue0_uop,
        input  wire issue1_valid,
        input  wire [31:0] issue1_pc,
        input  wire [31:0] issue1_instr,
        input  wire [`ISSUE_UOP_W-1:0] issue1_uop,
        output wire issue_pop0,
        output wire issue_pop1,
        output wire front_flush,
        output wire front_redirect_valid,
        output wire [31:0] front_redirect_pc,
        output wire bp_update_en,
        output wire bp_update_taken,
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

    wire [4:0] issue0_rs1 = issue0_uop[`ISSUE_UOP_RS1_MSB:`ISSUE_UOP_RS1_LSB];
    wire [4:0] issue0_rs2 = issue0_uop[`ISSUE_UOP_RS2_MSB:`ISSUE_UOP_RS2_LSB];
    wire [4:0] issue0_rd_idx = issue0_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire [31:0] issue0_imm = issue0_uop[`ISSUE_UOP_IMM_MSB:`ISSUE_UOP_IMM_LSB];
    wire [3:0] issue0_ALUctrl = issue0_uop[`ISSUE_UOP_ALUCTRL_MSB:`ISSUE_UOP_ALUCTRL_LSB];
    wire [36:0] issue0_control_bus = issue0_uop[`ISSUE_UOP_CTRLBUS_MSB:`ISSUE_UOP_CTRLBUS_LSB];
    wire issue0_use_rs1 = issue0_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire issue0_use_rs2 = issue0_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire issue0_writes_rd = issue0_uop[`ISSUE_UOP_WRITES_RD_BIT];
    wire issue0_is_ls = issue0_uop[`ISSUE_UOP_IS_LS_BIT];
    wire issue0_is_ctrl = issue0_uop[`ISSUE_UOP_IS_CTRL_BIT];
    wire issue0_pred_taken = issue0_uop[`ISSUE_UOP_PRED_TAKEN_BIT];

    wire [4:0] issue1_rs1 = issue1_uop[`ISSUE_UOP_RS1_MSB:`ISSUE_UOP_RS1_LSB];
    wire [4:0] issue1_rs2 = issue1_uop[`ISSUE_UOP_RS2_MSB:`ISSUE_UOP_RS2_LSB];
    wire [4:0] issue1_rd_idx = issue1_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire [31:0] issue1_imm = issue1_uop[`ISSUE_UOP_IMM_MSB:`ISSUE_UOP_IMM_LSB];
    wire [3:0] issue1_ALUctrl = issue1_uop[`ISSUE_UOP_ALUCTRL_MSB:`ISSUE_UOP_ALUCTRL_LSB];
    wire [36:0] issue1_control_bus = issue1_uop[`ISSUE_UOP_CTRLBUS_MSB:`ISSUE_UOP_CTRLBUS_LSB];
    wire issue1_use_rs1 = issue1_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire issue1_use_rs2 = issue1_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire issue1_writes_rd = issue1_uop[`ISSUE_UOP_WRITES_RD_BIT];

    wire issue0_jal;
    wire issue0_jalr;
    wire issue0_bgeu;
    wire issue0_bltu;
    wire issue0_bge;
    wire issue0_blt;
    wire issue0_bne;
    wire issue0_beq;

    ControlSignalUnbinder u_issue0_ctrl(
        .i_control_bus(issue0_control_bus),
        .o_jal(issue0_jal),
        .o_jalr(issue0_jalr),
        .o_bgeu(issue0_bgeu),
        .o_bltu(issue0_bltu),
        .o_bge(issue0_bge),
        .o_blt(issue0_blt),
        .o_bne(issue0_bne),
        .o_beq(issue0_beq)
    );

    wire [31:0] rf_issue0_rs1;
    wire [31:0] rf_issue0_rs2;
    wire [31:0] rf_issue1_rs1;
    wire [31:0] rf_issue1_rs2;

    reg ex0_valid;
    reg [31:0] ex0_pc;
    reg [31:0] ex0_instr;
    reg [`ISSUE_UOP_W-1:0] ex0_uop;
    reg [31:0] ex0_rs1_val;
    reg [31:0] ex0_rs2_val;

    reg ex1_valid;
    reg [31:0] ex1_pc;
    reg [31:0] ex1_instr;
    reg [`ISSUE_UOP_W-1:0] ex1_uop;
    reg [31:0] ex1_rs1_val;
    reg [31:0] ex1_rs2_val;

    reg mem0_valid;
    reg [31:0] mem0_pc;
    reg [31:0] mem0_instr;
    reg [`ISSUE_UOP_W-1:0] mem0_uop;
    reg [31:0] mem0_result;
    reg [31:0] mem0_rs2_val;

    reg mem1_valid;
    reg [31:0] mem1_pc;
    reg [31:0] mem1_instr;
    reg [`ISSUE_UOP_W-1:0] mem1_uop;
    reg [31:0] mem1_result;

    reg wb0_valid_r;
    reg [31:0] wb0_pc_r;
    reg [31:0] wb0_instr_r;
    reg [`ISSUE_UOP_W-1:0] wb0_uop;
    reg [31:0] wb0_wdata_r;
    reg [31:0] wb0_mem_addr_r;
    reg [3:0] wb0_mem_rmask_r;
    reg [3:0] wb0_mem_wmask_r;
    reg [31:0] wb0_mem_rdata_r;
    reg [31:0] wb0_mem_wdata_r;

    reg wb1_valid_r;
    reg [31:0] wb1_pc_r;
    reg [31:0] wb1_instr_r;
    reg [`ISSUE_UOP_W-1:0] wb1_uop;
    reg [31:0] wb1_wdata_r;

    wire [4:0] ex0_rd_idx = ex0_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire [31:0] ex0_imm = ex0_uop[`ISSUE_UOP_IMM_MSB:`ISSUE_UOP_IMM_LSB];
    wire [3:0] ex0_ALUctrl = ex0_uop[`ISSUE_UOP_ALUCTRL_MSB:`ISSUE_UOP_ALUCTRL_LSB];
    wire [36:0] ex0_control_bus = ex0_uop[`ISSUE_UOP_CTRLBUS_MSB:`ISSUE_UOP_CTRLBUS_LSB];
    wire ex0_use_rs1 = ex0_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire ex0_use_rs2 = ex0_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire ex0_writes_rd = ex0_uop[`ISSUE_UOP_WRITES_RD_BIT];
    wire ex0_is_ls = ex0_uop[`ISSUE_UOP_IS_LS_BIT];

    wire [4:0] ex1_rd_idx = ex1_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire [31:0] ex1_imm = ex1_uop[`ISSUE_UOP_IMM_MSB:`ISSUE_UOP_IMM_LSB];
    wire [3:0] ex1_ALUctrl = ex1_uop[`ISSUE_UOP_ALUCTRL_MSB:`ISSUE_UOP_ALUCTRL_LSB];
    wire [36:0] ex1_control_bus = ex1_uop[`ISSUE_UOP_CTRLBUS_MSB:`ISSUE_UOP_CTRLBUS_LSB];
    wire ex1_use_rs1 = ex1_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire ex1_use_rs2 = ex1_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire ex1_writes_rd = ex1_uop[`ISSUE_UOP_WRITES_RD_BIT];

    wire [4:0] mem0_rd_idx = mem0_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire [36:0] mem0_control_bus = mem0_uop[`ISSUE_UOP_CTRLBUS_MSB:`ISSUE_UOP_CTRLBUS_LSB];
    wire mem0_writes_rd = mem0_uop[`ISSUE_UOP_WRITES_RD_BIT];

    wire [4:0] mem1_rd_idx = mem1_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire mem1_writes_rd = mem1_uop[`ISSUE_UOP_WRITES_RD_BIT];

    wire [4:0] wb0_rd_idx = wb0_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire wb0_writes_rd = wb0_uop[`ISSUE_UOP_WRITES_RD_BIT];
    wire [4:0] wb1_rd_idx = wb1_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];
    wire wb1_writes_rd = wb1_uop[`ISSUE_UOP_WRITES_RD_BIT];

    wire ex0_lhu;
    wire ex0_lbu;
    wire ex0_lw;
    wire ex0_lh;
    wire ex0_lb;
    wire ex0_sw;
    wire ex0_sh;
    wire ex0_sb;
    wire ex0_jal;
    wire ex0_jalr;
    wire ex0_bgeu;
    wire ex0_bltu;
    wire ex0_bge;
    wire ex0_blt;
    wire ex0_bne;
    wire ex0_beq;
    wire ex0_srai;
    wire ex0_sra;
    wire ex0_srli;
    wire ex0_srl;
    wire ex0_slli;
    wire ex0_sll;
    wire ex0_sltiu;
    wire ex0_sltu;
    wire ex0_slti;
    wire ex0_slt;
    wire ex0_xori;
    wire ex0_ori;
    wire ex0_andi;
    wire ex0_xor_;
    wire ex0_or_;
    wire ex0_and_;
    wire ex0_addi;
    wire ex0_auipc;
    wire ex0_lui;
    wire ex0_sub;
    wire ex0_add;

    ControlSignalUnbinder u_ex0_ctrl(
        .i_control_bus(ex0_control_bus),
        .o_lhu(ex0_lhu), .o_lbu(ex0_lbu), .o_lw(ex0_lw), .o_lh(ex0_lh), .o_lb(ex0_lb),
        .o_sw(ex0_sw), .o_sh(ex0_sh), .o_sb(ex0_sb),
        .o_jal(ex0_jal), .o_jalr(ex0_jalr), .o_bgeu(ex0_bgeu), .o_bltu(ex0_bltu),
        .o_bge(ex0_bge), .o_blt(ex0_blt), .o_bne(ex0_bne), .o_beq(ex0_beq),
        .o_srai(ex0_srai), .o_sra(ex0_sra), .o_srli(ex0_srli), .o_srl(ex0_srl),
        .o_slli(ex0_slli), .o_sll(ex0_sll),
        .o_sltiu(ex0_sltiu), .o_sltu(ex0_sltu), .o_slti(ex0_slti), .o_slt(ex0_slt),
        .o_xori(ex0_xori), .o_ori(ex0_ori), .o_andi(ex0_andi), .o_xor_(ex0_xor_),
        .o_or_(ex0_or_), .o_and_(ex0_and_), .o_addi(ex0_addi), .o_auipc(ex0_auipc),
        .o_lui(ex0_lui), .o_sub(ex0_sub), .o_add(ex0_add)
    );

    wire ex1_lhu;
    wire ex1_lbu;
    wire ex1_lw;
    wire ex1_lh;
    wire ex1_lb;
    wire ex1_sw;
    wire ex1_sh;
    wire ex1_sb;
    wire ex1_jal;
    wire ex1_jalr;
    wire ex1_bgeu;
    wire ex1_bltu;
    wire ex1_bge;
    wire ex1_blt;
    wire ex1_bne;
    wire ex1_beq;
    wire ex1_srai;
    wire ex1_sra;
    wire ex1_srli;
    wire ex1_srl;
    wire ex1_slli;
    wire ex1_sll;
    wire ex1_sltiu;
    wire ex1_sltu;
    wire ex1_slti;
    wire ex1_slt;
    wire ex1_xori;
    wire ex1_ori;
    wire ex1_andi;
    wire ex1_xor_;
    wire ex1_or_;
    wire ex1_and_;
    wire ex1_addi;
    wire ex1_auipc;
    wire ex1_lui;
    wire ex1_sub;
    wire ex1_add;

    ControlSignalUnbinder u_ex1_ctrl(
        .i_control_bus(ex1_control_bus),
        .o_lhu(ex1_lhu), .o_lbu(ex1_lbu), .o_lw(ex1_lw), .o_lh(ex1_lh), .o_lb(ex1_lb),
        .o_sw(ex1_sw), .o_sh(ex1_sh), .o_sb(ex1_sb),
        .o_jal(ex1_jal), .o_jalr(ex1_jalr), .o_bgeu(ex1_bgeu), .o_bltu(ex1_bltu),
        .o_bge(ex1_bge), .o_blt(ex1_blt), .o_bne(ex1_bne), .o_beq(ex1_beq),
        .o_srai(ex1_srai), .o_sra(ex1_sra), .o_srli(ex1_srli), .o_srl(ex1_srl),
        .o_slli(ex1_slli), .o_sll(ex1_sll),
        .o_sltiu(ex1_sltiu), .o_sltu(ex1_sltu), .o_slti(ex1_slti), .o_slt(ex1_slt),
        .o_xori(ex1_xori), .o_ori(ex1_ori), .o_andi(ex1_andi), .o_xor_(ex1_xor_),
        .o_or_(ex1_or_), .o_and_(ex1_and_), .o_addi(ex1_addi), .o_auipc(ex1_auipc),
        .o_lui(ex1_lui), .o_sub(ex1_sub), .o_add(ex1_add)
    );

    wire mem0_lhu;
    wire mem0_lbu;
    wire mem0_lw;
    wire mem0_lh;
    wire mem0_lb;
    wire mem0_sw;
    wire mem0_sh;
    wire mem0_sb;
    wire mem0_jal;
    wire mem0_jalr;

    ControlSignalUnbinder u_mem0_ctrl(
        .i_control_bus(mem0_control_bus),
        .o_lhu(mem0_lhu), .o_lbu(mem0_lbu), .o_lw(mem0_lw), .o_lh(mem0_lh), .o_lb(mem0_lb),
        .o_sw(mem0_sw), .o_sh(mem0_sh), .o_sb(mem0_sb),
        .o_jal(mem0_jal), .o_jalr(mem0_jalr)
    );

    wire rf_wen0 = wb0_valid_r && wb0_writes_rd && (wb0_rd_idx != 5'h0);
    wire rf_wen1 = wb1_valid_r && wb1_writes_rd && (wb1_rd_idx != 5'h0);

    registerFile u_register_file(
        .clk(clk),
        .rst_n(rst_n),
        .raddr0_1(issue0_rs1),
        .raddr0_2(issue0_rs2),
        .rdata0_1(rf_issue0_rs1),
        .rdata0_2(rf_issue0_rs2),
        .raddr1_1(issue1_rs1),
        .raddr1_2(issue1_rs2),
        .rdata1_1(rf_issue1_rs1),
        .rdata1_2(rf_issue1_rs2),
        .wdata0(wb0_wdata_r),
        .waddr0(wb0_rd_idx),
        .w_en0(rf_wen0),
        .wdata1(wb1_wdata_r),
        .waddr1(wb1_rd_idx),
        .w_en1(rf_wen1)
    );

    wire [31:0] ex0_opnum1 = (ex0_auipc || ex0_jal || ex0_jalr) ? ex0_pc : ex0_rs1_val;
    wire [31:0] ex0_opnum2 = (ex0_addi || ex0_auipc || ex0_sltiu || ex0_andi || ex0_ori || ex0_xori ||
                              ex0_slti || ex0_lb || ex0_lbu || ex0_lw || ex0_lh || ex0_lhu ||
                              ex0_sb || ex0_sw || ex0_sh) ? ex0_imm :
                             (ex0_add || ex0_sltu || ex0_bne || ex0_beq || ex0_sll || ex0_srl ||
                              ex0_and_ || ex0_or_ || ex0_xor_ || ex0_bge || ex0_bgeu || ex0_blt ||
                              ex0_slt || ex0_sub || ex0_bltu || ex0_sra) ? ex0_rs2_val :
                             (ex0_srli || ex0_slli || ex0_srai) ? {{27{1'b0}}, ex0_imm[4:0]} :
                             32'd4;

    wire [31:0] ex1_opnum1 = (ex1_auipc || ex1_jal || ex1_jalr) ? ex1_pc : ex1_rs1_val;
    wire [31:0] ex1_opnum2 = (ex1_addi || ex1_auipc || ex1_sltiu || ex1_andi || ex1_ori || ex1_xori ||
                              ex1_slti || ex1_lb || ex1_lbu || ex1_lw || ex1_lh || ex1_lhu ||
                              ex1_sb || ex1_sw || ex1_sh) ? ex1_imm :
                             (ex1_add || ex1_sltu || ex1_bne || ex1_beq || ex1_sll || ex1_srl ||
                              ex1_and_ || ex1_or_ || ex1_xor_ || ex1_bge || ex1_bgeu || ex1_blt ||
                              ex1_slt || ex1_sub || ex1_bltu || ex1_sra) ? ex1_rs2_val :
                             (ex1_srli || ex1_slli || ex1_srai) ? {{27{1'b0}}, ex1_imm[4:0]} :
                             32'd4;

    wire [31:0] ex0_alu_result_raw;
    wire ex0_zero;
    wire ex0_sign;
    wire ex0_carry;
    wire ex0_overflow;
    ALU u_ex0_alu(
        .ALUctrl(ex0_ALUctrl),
        .opnum1(ex0_opnum1),
        .opnum2(ex0_opnum2),
        .result(ex0_alu_result_raw),
        .zero_flag(ex0_zero),
        .sign_flag(ex0_sign),
        .carry_flag(ex0_carry),
        .overflow_flag(ex0_overflow)
    );

    wire [31:0] ex1_alu_result_raw;
    wire ex1_zero;
    wire ex1_sign;
    wire ex1_carry;
    wire ex1_overflow;
    ALU u_ex1_alu(
        .ALUctrl(ex1_ALUctrl),
        .opnum1(ex1_opnum1),
        .opnum2(ex1_opnum2),
        .result(ex1_alu_result_raw),
        .zero_flag(ex1_zero),
        .sign_flag(ex1_sign),
        .carry_flag(ex1_carry),
        .overflow_flag(ex1_overflow)
    );

    wire [31:0] ex0_final_result = ex0_lui ? ex0_imm :
                                   (ex0_slt || ex0_slti) ? ((ex0_overflow ^ ex0_sign) ? 32'd1 : 32'd0) :
                                   (ex0_sltiu || ex0_sltu) ? (ex0_carry ? 32'd1 : 32'd0) :
                                   ex0_alu_result_raw;

    wire [31:0] ex1_final_result = ex1_lui ? ex1_imm :
                                   (ex1_slt || ex1_slti) ? ((ex1_overflow ^ ex1_sign) ? 32'd1 : 32'd0) :
                                   (ex1_sltiu || ex1_sltu) ? (ex1_carry ? 32'd1 : 32'd0) :
                                   ex1_alu_result_raw;

    wire ex0_forward_valid = ex0_valid && ex0_writes_rd && !ex0_is_ls;
    wire [31:0] ex0_forward_value = (ex0_jal || ex0_jalr) ? (ex0_pc + 32'd4) : ex0_final_result;
    wire ex1_forward_valid = ex1_valid && ex1_writes_rd;
    wire [31:0] ex1_forward_value = ex1_final_result;

    wire mem0_is_load = mem0_lb || mem0_lbu || mem0_lw || mem0_lh || mem0_lhu;
    wire mem0_is_store = mem0_sb || mem0_sh || mem0_sw;
    wire [1:0] mem0_store_type = mem0_sw ? 2'b10 :
                                 mem0_sh ? 2'b01 :
                                 mem0_sb ? 2'b00 : 2'b10;
    wire [31:0] mem0_rdata;

    data_ram u_data_ram(
        .clk(clk),
        .w_en(mem0_valid && mem0_is_store),
        .r_en(mem0_valid && mem0_is_load),
        .store_type(mem0_store_type),
        .raddr(mem0_result),
        .waddr(mem0_result),
        .wdata(mem0_rs2_val),
        .rdata(mem0_rdata)
    );

    wire [3:0] mem0_rmask = mem0_is_load ?
                            (mem0_lb || mem0_lbu) ? (4'b0001 << mem0_result[1:0]) :
                            (mem0_lh || mem0_lhu) ? (mem0_result[1] ? 4'b1100 : 4'b0011) :
                            4'b1111 : 4'b0000;

    wire [3:0] mem0_wmask = mem0_is_store ?
                            (mem0_sb) ? (4'b0001 << mem0_result[1:0]) :
                            (mem0_sh) ? (mem0_result[1] ? 4'b1100 : 4'b0011) :
                            4'b1111 : 4'b0000;

    wire [31:0] mem0_load_data =
        (mem0_lb  && (mem0_result[1:0] == 2'b00)) ? {{24{mem0_rdata[7]}},   mem0_rdata[7:0]}   :
        (mem0_lb  && (mem0_result[1:0] == 2'b01)) ? {{24{mem0_rdata[15]}},  mem0_rdata[15:8]}  :
        (mem0_lb  && (mem0_result[1:0] == 2'b10)) ? {{24{mem0_rdata[23]}},  mem0_rdata[23:16]} :
        (mem0_lb  && (mem0_result[1:0] == 2'b11)) ? {{24{mem0_rdata[31]}},  mem0_rdata[31:24]} :
        (mem0_lbu && (mem0_result[1:0] == 2'b00)) ? {24'h0, mem0_rdata[7:0]}   :
        (mem0_lbu && (mem0_result[1:0] == 2'b01)) ? {24'h0, mem0_rdata[15:8]}  :
        (mem0_lbu && (mem0_result[1:0] == 2'b10)) ? {24'h0, mem0_rdata[23:16]} :
        (mem0_lbu && (mem0_result[1:0] == 2'b11)) ? {24'h0, mem0_rdata[31:24]} :
        (mem0_lh  && !mem0_result[1]) ? {{16{mem0_rdata[15]}}, mem0_rdata[15:0]} :
        (mem0_lh  &&  mem0_result[1]) ? {{16{mem0_rdata[31]}}, mem0_rdata[31:16]} :
        (mem0_lhu && !mem0_result[1]) ? {16'h0, mem0_rdata[15:0]} :
        (mem0_lhu &&  mem0_result[1]) ? {16'h0, mem0_rdata[31:16]} :
        (mem0_lw) ? mem0_rdata :
        32'h0;

    wire mem0_forward_valid = mem0_valid && mem0_writes_rd;
    wire [31:0] mem0_forward_value = mem0_is_load ? mem0_load_data :
                                     (mem0_jal || mem0_jalr) ? (mem0_pc + 32'd4) :
                                     mem0_result;

    wire mem1_forward_valid = mem1_valid && mem1_writes_rd;
    wire [31:0] mem1_forward_value = mem1_result;
    wire wb0_forward_valid = wb0_valid_r && wb0_writes_rd;
    wire wb1_forward_valid = wb1_valid_r && wb1_writes_rd;

    wire [31:0] issue0_rs1_eff;
    wire [31:0] issue0_rs2_eff;
    wire [31:0] issue1_rs1_eff;
    wire [31:0] issue1_rs2_eff;

    Forwarding_unit_fastcomp_dual u_forwarding(
        .slot0_use_rs1(issue0_use_rs1),
        .slot0_use_rs2(issue0_use_rs2),
        .slot0_rs1(issue0_rs1),
        .slot0_rs2(issue0_rs2),
        .slot0_rf_rs1(rf_issue0_rs1),
        .slot0_rf_rs2(rf_issue0_rs2),
        .slot1_use_rs1(issue1_use_rs1),
        .slot1_use_rs2(issue1_use_rs2),
        .slot1_rs1(issue1_rs1),
        .slot1_rs2(issue1_rs2),
        .slot1_rf_rs1(rf_issue1_rs1),
        .slot1_rf_rs2(rf_issue1_rs2),
        .ex0_valid(ex0_forward_valid),
        .ex0_rd(ex0_rd_idx),
        .ex0_value(ex0_forward_value),
        .ex1_valid(ex1_forward_valid),
        .ex1_rd(ex1_rd_idx),
        .ex1_value(ex1_forward_value),
        .mem0_valid(mem0_forward_valid),
        .mem0_rd(mem0_rd_idx),
        .mem0_value(mem0_forward_value),
        .mem1_valid(mem1_forward_valid),
        .mem1_rd(mem1_rd_idx),
        .mem1_value(mem1_forward_value),
        .wb0_valid(wb0_forward_valid),
        .wb0_rd(wb0_rd_idx),
        .wb0_value(wb0_wdata_r),
        .wb1_valid(wb1_forward_valid),
        .wb1_rd(wb1_rd_idx),
        .wb1_value(wb1_wdata_r),
        .slot0_rs1_eff(issue0_rs1_eff),
        .slot0_rs2_eff(issue0_rs2_eff),
        .slot1_rs1_eff(issue1_rs1_eff),
        .slot1_rs2_eff(issue1_rs2_eff)
    );

    wire slot0_blocked;
    wire slot1_blocked;
    Hazard_detection_fastcomp_dual u_hazard_detection(
        .slot0_valid(issue0_valid),
        .slot1_valid(issue1_valid),
        .slot0_uop(issue0_uop),
        .slot1_uop(issue1_uop),
        .ex0_valid(ex0_valid),
        .ex0_is_load(ex0_is_ls && ex0_writes_rd),
        .ex0_writes_rd(ex0_writes_rd),
        .ex0_rd(ex0_rd_idx),
        .slot0_blocked(slot0_blocked),
        .slot1_blocked(slot1_blocked)
    );

    issue_select u_issue_select(
        .dual_issue_enable(dual_issue_enable),
        .slot0_valid(issue0_valid),
        .slot1_valid(issue1_valid),
        .slot0_blocked(slot0_blocked),
        .slot1_blocked(slot1_blocked),
        .slot0_uop(issue0_uop),
        .slot1_uop(issue1_uop),
        .slot0_issue(issue_pop0),
        .slot1_issue(issue_pop1)
    );

    wire cmp_zero;
    wire cmp_sign;
    wire cmp_carry;
    wire cmp_overflow;
    sub_fastcomp u_branch_compare(
        .opnum1(issue0_rs1_eff),
        .opnum2(issue0_rs2_eff),
        .zero_flag(cmp_zero),
        .sign_flag(cmp_sign),
        .carry_flag(cmp_carry),
        .overflow_flag(cmp_overflow)
    );

    wire issue0_conditional_branch = issue0_beq || issue0_bne || issue0_blt || issue0_bge || issue0_bltu || issue0_bgeu;
    wire issue0_branch_taken = (issue0_beq && cmp_zero) ||
                               (issue0_bne && !cmp_zero) ||
                               (issue0_blt && (cmp_sign ^ cmp_overflow)) ||
                               (issue0_bge && !(cmp_sign ^ cmp_overflow)) ||
                               (issue0_bltu && cmp_carry) ||
                               (issue0_bgeu && !cmp_carry);
    wire [31:0] issue0_actual_next_pc = issue0_jalr ? ((issue0_rs1_eff + issue0_imm) & 32'hffff_fffe) :
                                        ((issue0_jal || issue0_branch_taken) ? (issue0_pc + issue0_imm) : (issue0_pc + 32'd4));

    assign bp_update_en = issue_pop0 && issue0_conditional_branch;
    assign bp_update_taken = issue0_branch_taken;
    assign front_flush = issue_pop0 &&
                         (issue0_jal || issue0_jalr ||
                          (issue0_conditional_branch && (issue0_pred_taken ^ issue0_branch_taken)));
    assign front_redirect_valid = front_flush;
    assign front_redirect_pc = issue0_actual_next_pc;

    assign commit0_valid = wb0_valid_r;
    assign commit0_pc = wb0_pc_r;
    assign commit0_insn = wb0_instr_r;
    assign commit0_rd = wb0_writes_rd ? wb0_rd_idx : 5'h0;
    assign commit0_rd_wdata = wb0_writes_rd ? wb0_wdata_r : 32'h0;
    assign commit0_mem_addr = wb0_mem_addr_r;
    assign commit0_mem_rmask = wb0_mem_rmask_r;
    assign commit0_mem_wmask = wb0_mem_wmask_r;
    assign commit0_mem_rdata = wb0_mem_rdata_r;
    assign commit0_mem_wdata = wb0_mem_wdata_r;

    assign commit1_valid = wb1_valid_r;
    assign commit1_pc = wb1_pc_r;
    assign commit1_insn = wb1_instr_r;
    assign commit1_rd = wb1_writes_rd ? wb1_rd_idx : 5'h0;
    assign commit1_rd_wdata = wb1_writes_rd ? wb1_wdata_r : 32'h0;
    assign commit1_mem_addr = 32'h0;
    assign commit1_mem_rmask = 4'h0;
    assign commit1_mem_wmask = 4'h0;
    assign commit1_mem_rdata = 32'h0;
    assign commit1_mem_wdata = 32'h0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex0_valid <= 1'b0;
            ex0_pc <= 32'h0;
            ex0_instr <= 32'h0;
            ex0_uop <= {`ISSUE_UOP_W{1'b0}};
            ex0_rs1_val <= 32'h0;
            ex0_rs2_val <= 32'h0;

            ex1_valid <= 1'b0;
            ex1_pc <= 32'h0;
            ex1_instr <= 32'h0;
            ex1_uop <= {`ISSUE_UOP_W{1'b0}};
            ex1_rs1_val <= 32'h0;
            ex1_rs2_val <= 32'h0;

            mem0_valid <= 1'b0;
            mem0_pc <= 32'h0;
            mem0_instr <= 32'h0;
            mem0_uop <= {`ISSUE_UOP_W{1'b0}};
            mem0_result <= 32'h0;
            mem0_rs2_val <= 32'h0;

            mem1_valid <= 1'b0;
            mem1_pc <= 32'h0;
            mem1_instr <= 32'h0;
            mem1_uop <= {`ISSUE_UOP_W{1'b0}};
            mem1_result <= 32'h0;

            wb0_valid_r <= 1'b0;
            wb0_pc_r <= 32'h0;
            wb0_instr_r <= 32'h0;
            wb0_uop <= {`ISSUE_UOP_W{1'b0}};
            wb0_wdata_r <= 32'h0;
            wb0_mem_addr_r <= 32'h0;
            wb0_mem_rmask_r <= 4'h0;
            wb0_mem_wmask_r <= 4'h0;
            wb0_mem_rdata_r <= 32'h0;
            wb0_mem_wdata_r <= 32'h0;

            wb1_valid_r <= 1'b0;
            wb1_pc_r <= 32'h0;
            wb1_instr_r <= 32'h0;
            wb1_uop <= {`ISSUE_UOP_W{1'b0}};
            wb1_wdata_r <= 32'h0;
        end
        else begin
            wb0_valid_r <= mem0_valid;
            wb0_pc_r <= mem0_pc;
            wb0_instr_r <= mem0_instr;
            wb0_uop <= mem0_uop;
            wb0_wdata_r <= mem0_is_load ? mem0_load_data :
                           (mem0_jal || mem0_jalr) ? (mem0_pc + 32'd4) :
                           mem0_result;
            wb0_mem_addr_r <= (mem0_is_load || mem0_is_store) ? mem0_result : 32'h0;
            wb0_mem_rmask_r <= mem0_rmask;
            wb0_mem_wmask_r <= mem0_wmask;
            wb0_mem_rdata_r <= mem0_is_load ? mem0_load_data : 32'h0;
            wb0_mem_wdata_r <= mem0_is_store ? mem0_rs2_val : 32'h0;

            wb1_valid_r <= mem1_valid;
            wb1_pc_r <= mem1_pc;
            wb1_instr_r <= mem1_instr;
            wb1_uop <= mem1_uop;
            wb1_wdata_r <= mem1_result;

            mem0_valid <= ex0_valid;
            mem0_pc <= ex0_pc;
            mem0_instr <= ex0_instr;
            mem0_uop <= ex0_uop;
            mem0_result <= ex0_final_result;
            mem0_rs2_val <= ex0_rs2_val;

            mem1_valid <= ex1_valid;
            mem1_pc <= ex1_pc;
            mem1_instr <= ex1_instr;
            mem1_uop <= ex1_uop;
            mem1_result <= ex1_final_result;

            if (issue_pop0) begin
                ex0_valid <= 1'b1;
                ex0_pc <= issue0_pc;
                ex0_instr <= issue0_instr;
                ex0_uop <= issue0_uop;
                ex0_rs1_val <= issue0_rs1_eff;
                ex0_rs2_val <= issue0_rs2_eff;
            end
            else begin
                ex0_valid <= 1'b0;
                ex0_pc <= 32'h0;
                ex0_instr <= 32'h0;
                ex0_uop <= {`ISSUE_UOP_W{1'b0}};
                ex0_rs1_val <= 32'h0;
                ex0_rs2_val <= 32'h0;
            end

            if (issue_pop1) begin
                ex1_valid <= 1'b1;
                ex1_pc <= issue1_pc;
                ex1_instr <= issue1_instr;
                ex1_uop <= issue1_uop;
                ex1_rs1_val <= issue1_rs1_eff;
                ex1_rs2_val <= issue1_rs2_eff;
            end
            else begin
                ex1_valid <= 1'b0;
                ex1_pc <= 32'h0;
                ex1_instr <= 32'h0;
                ex1_uop <= {`ISSUE_UOP_W{1'b0}};
                ex1_rs1_val <= 32'h0;
                ex1_rs2_val <= 32'h0;
            end
        end
    end
endmodule
