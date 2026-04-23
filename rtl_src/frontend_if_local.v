module frontend_if_local #(
        parameter integer ISSUE_QUEUE_DEPTH = 8
    )(
        input  wire clk,
        input  wire rst_n,
        input  wire dual_enable,
        input  wire [31:0] iq_free_slots,
        input  wire flush,
        input  wire redirect_valid,
        input  wire [31:0] redirect_pc,
        input  wire bp_update_en,
        input  wire bp_update_taken,
        output wire push0_valid,
        output wire [31:0] push0_pc,
        output wire [31:0] push0_instr,
        output wire push0_pred_taken,
        output wire push1_valid,
        output wire [31:0] push1_pc,
        output wire [31:0] push1_instr,
        output wire push1_pred_taken
    );

    reg [31:0] pc_f;

    wire [63:0] instr_pair;
    wire [31:0] instr0;
    wire conditional_jump_if;
    wire [31:0] imm_if;
    wire predict_taken;
    wire can_fetch;
    wire can_dual_fetch;
    wire [31:0] next_pc_seq;
    wire [31:0] next_pc_pred;

    instr_rom u_instr_rom(
        .raddr(pc_f),
        .r_en(1'b1),
        .rdata(instr0),
        .rdata_pair(instr_pair)
    );

    Branch_PreDecode u_predecode(
        .instruction_if(instr0),
        .is_conditional_branch_if(conditional_jump_if),
        .imm_offset_if(imm_if)
    );

    BranchPredictor_1bit_SingleEntry u_branch_predictor(
        .clk(clk),
        .rst_n(rst_n),
        .update_en(bp_update_en),
        .branch_taken_actual(bp_update_taken),
        .predicted_taken(predict_taken)
    );

    assign can_fetch = (iq_free_slots != 32'h0);
    assign can_dual_fetch = dual_enable &&
                            (iq_free_slots >= 32'd2) &&
                            !(conditional_jump_if && predict_taken);
    assign next_pc_seq = pc_f + (can_dual_fetch ? 32'd8 : 32'd4);
    assign next_pc_pred = (conditional_jump_if && predict_taken) ? (pc_f + imm_if) : next_pc_seq;

    assign push0_valid = can_fetch && !flush;
    assign push0_pc = pc_f;
    assign push0_instr = instr_pair[31:0];
    assign push0_pred_taken = conditional_jump_if && predict_taken;
    assign push1_valid = push0_valid && can_dual_fetch;
    assign push1_pc = pc_f + 32'd4;
    assign push1_instr = instr_pair[63:32];
    assign push1_pred_taken = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_f <= 32'h0;
        end
        else if (flush && redirect_valid) begin
            pc_f <= redirect_pc;
        end
        else if (can_fetch) begin
            pc_f <= next_pc_pred;
        end
    end
endmodule
