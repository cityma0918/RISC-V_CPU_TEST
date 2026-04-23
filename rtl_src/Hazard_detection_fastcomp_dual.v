`include "issue_uop.vh"

module Hazard_detection_fastcomp_dual(
        input  wire slot0_valid,
        input  wire slot1_valid,
        input  wire [`ISSUE_UOP_W-1:0] slot0_uop,
        input  wire [`ISSUE_UOP_W-1:0] slot1_uop,
        input  wire ex0_valid,
        input  wire ex0_is_load,
        input  wire ex0_writes_rd,
        input  wire [4:0] ex0_rd,
        output wire slot0_blocked,
        output wire slot1_blocked
    );

    wire slot0_use_rs1 = slot0_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire slot0_use_rs2 = slot0_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire [4:0] slot0_rs1 = slot0_uop[`ISSUE_UOP_RS1_MSB:`ISSUE_UOP_RS1_LSB];
    wire [4:0] slot0_rs2 = slot0_uop[`ISSUE_UOP_RS2_MSB:`ISSUE_UOP_RS2_LSB];
    wire slot1_use_rs1 = slot1_uop[`ISSUE_UOP_USE_RS1_BIT];
    wire slot1_use_rs2 = slot1_uop[`ISSUE_UOP_USE_RS2_BIT];
    wire [4:0] slot1_rs1 = slot1_uop[`ISSUE_UOP_RS1_MSB:`ISSUE_UOP_RS1_LSB];
    wire [4:0] slot1_rs2 = slot1_uop[`ISSUE_UOP_RS2_MSB:`ISSUE_UOP_RS2_LSB];

    wire load_wait_slot0 = slot0_valid &&
                           ex0_valid &&
                           ex0_is_load &&
                           ex0_writes_rd &&
                           (ex0_rd != 5'h0) &&
                           ( (slot0_use_rs1 && (slot0_rs1 == ex0_rd)) ||
                             (slot0_use_rs2 && (slot0_rs2 == ex0_rd)) );

    wire load_wait_slot1 = slot1_valid &&
                           ex0_valid &&
                           ex0_is_load &&
                           ex0_writes_rd &&
                           (ex0_rd != 5'h0) &&
                           ( (slot1_use_rs1 && (slot1_rs1 == ex0_rd)) ||
                             (slot1_use_rs2 && (slot1_rs2 == ex0_rd)) );

    assign slot0_blocked = load_wait_slot0;
    assign slot1_blocked = load_wait_slot1;
endmodule
