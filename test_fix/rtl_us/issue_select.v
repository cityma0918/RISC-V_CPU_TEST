`include "issue_uop.vh"

module issue_select(
        input  wire dual_issue_enable,
        input  wire slot0_valid,
        input  wire slot1_valid,
        input  wire slot0_blocked,
        input  wire slot1_blocked,
        input  wire [`ISSUE_UOP_W-1:0] slot0_uop,
        input  wire [`ISSUE_UOP_W-1:0] slot1_uop,
        output wire slot0_issue,
        output wire slot1_issue
    );

    wire slot0_is_ls = slot0_uop[`ISSUE_UOP_IS_LS_BIT];
    wire slot0_writes_rd = slot0_uop[`ISSUE_UOP_WRITES_RD_BIT];
    wire [4:0] slot0_rd = slot0_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];

    wire slot1_use_rs1 = slot1_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire slot1_use_rs2 = slot1_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire slot1_writes_rd = slot1_uop[`ISSUE_UOP_WRITES_RD_BIT];
    wire slot1_is_pairable_x = slot1_uop[`ISSUE_UOP_IS_PAIRX_BIT];
    wire [4:0] slot1_rs1 = slot1_uop[`ISSUE_UOP_RS1_MSB:`ISSUE_UOP_RS1_LSB];
    wire [4:0] slot1_rs2 = slot1_uop[`ISSUE_UOP_RS2_MSB:`ISSUE_UOP_RS2_LSB];
    wire [4:0] slot1_rd = slot1_uop[`ISSUE_UOP_RD_MSB:`ISSUE_UOP_RD_LSB];

    wire slot1_dep_slot0 = slot0_writes_rd && (slot0_rd != 5'h0) &&
                           ( (slot1_use_rs1 && (slot1_rs1 == slot0_rd)) ||
                             (slot1_use_rs2 && (slot1_rs2 == slot0_rd)) ||
                             (slot1_writes_rd && (slot1_rd == slot0_rd)) );

    assign slot0_issue = slot0_valid && !slot0_blocked;
    assign slot1_issue = dual_issue_enable &&
                         slot0_issue &&
                         slot1_valid &&
                         !slot1_blocked &&
                         slot0_is_ls &&
                         slot1_is_pairable_x &&
                         !slot1_dep_slot0;
endmodule
