module Forwarding_unit_fastcomp_dual(
        input  wire slot0_use_rs1,
        input  wire slot0_use_rs2,
        input  wire [4:0] slot0_rs1,
        input  wire [4:0] slot0_rs2,
        input  wire [31:0] slot0_rf_rs1,
        input  wire [31:0] slot0_rf_rs2,
        input  wire slot1_use_rs1,
        input  wire slot1_use_rs2,
        input  wire [4:0] slot1_rs1,
        input  wire [4:0] slot1_rs2,
        input  wire [31:0] slot1_rf_rs1,
        input  wire [31:0] slot1_rf_rs2,

        input  wire ex0_valid,
        input  wire [4:0] ex0_rd,
        input  wire [31:0] ex0_value,
        input  wire ex1_valid,
        input  wire [4:0] ex1_rd,
        input  wire [31:0] ex1_value,
        input  wire mem0_valid,
        input  wire [4:0] mem0_rd,
        input  wire [31:0] mem0_value,
        input  wire mem1_valid,
        input  wire [4:0] mem1_rd,
        input  wire [31:0] mem1_value,
        input  wire wb0_valid,
        input  wire [4:0] wb0_rd,
        input  wire [31:0] wb0_value,
        input  wire wb1_valid,
        input  wire [4:0] wb1_rd,
        input  wire [31:0] wb1_value,

        output wire [31:0] slot0_rs1_eff,
        output wire [31:0] slot0_rs2_eff,
        output wire [31:0] slot1_rs1_eff,
        output wire [31:0] slot1_rs2_eff
    );

    assign slot0_rs1_eff =
        (!slot0_use_rs1 || (slot0_rs1 == 5'h0)) ? 32'h0 :
        (ex1_valid  && (slot0_rs1 == ex1_rd)  && (ex1_rd  != 5'h0)) ? ex1_value  :
        (ex0_valid  && (slot0_rs1 == ex0_rd)  && (ex0_rd  != 5'h0)) ? ex0_value  :
        (mem1_valid && (slot0_rs1 == mem1_rd) && (mem1_rd != 5'h0)) ? mem1_value :
        (mem0_valid && (slot0_rs1 == mem0_rd) && (mem0_rd != 5'h0)) ? mem0_value :
        (wb1_valid  && (slot0_rs1 == wb1_rd)  && (wb1_rd  != 5'h0)) ? wb1_value  :
        (wb0_valid  && (slot0_rs1 == wb0_rd)  && (wb0_rd  != 5'h0)) ? wb0_value  :
        slot0_rf_rs1;

    assign slot0_rs2_eff =
        (!slot0_use_rs2 || (slot0_rs2 == 5'h0)) ? 32'h0 :
        (ex1_valid  && (slot0_rs2 == ex1_rd)  && (ex1_rd  != 5'h0)) ? ex1_value  :
        (ex0_valid  && (slot0_rs2 == ex0_rd)  && (ex0_rd  != 5'h0)) ? ex0_value  :
        (mem1_valid && (slot0_rs2 == mem1_rd) && (mem1_rd != 5'h0)) ? mem1_value :
        (mem0_valid && (slot0_rs2 == mem0_rd) && (mem0_rd != 5'h0)) ? mem0_value :
        (wb1_valid  && (slot0_rs2 == wb1_rd)  && (wb1_rd  != 5'h0)) ? wb1_value  :
        (wb0_valid  && (slot0_rs2 == wb0_rd)  && (wb0_rd  != 5'h0)) ? wb0_value  :
        slot0_rf_rs2;

    assign slot1_rs1_eff =
        (!slot1_use_rs1 || (slot1_rs1 == 5'h0)) ? 32'h0 :
        (ex1_valid  && (slot1_rs1 == ex1_rd)  && (ex1_rd  != 5'h0)) ? ex1_value  :
        (ex0_valid  && (slot1_rs1 == ex0_rd)  && (ex0_rd  != 5'h0)) ? ex0_value  :
        (mem1_valid && (slot1_rs1 == mem1_rd) && (mem1_rd != 5'h0)) ? mem1_value :
        (mem0_valid && (slot1_rs1 == mem0_rd) && (mem0_rd != 5'h0)) ? mem0_value :
        (wb1_valid  && (slot1_rs1 == wb1_rd)  && (wb1_rd  != 5'h0)) ? wb1_value  :
        (wb0_valid  && (slot1_rs1 == wb0_rd)  && (wb0_rd  != 5'h0)) ? wb0_value  :
        slot1_rf_rs1;

    assign slot1_rs2_eff =
        (!slot1_use_rs2 || (slot1_rs2 == 5'h0)) ? 32'h0 :
        (ex1_valid  && (slot1_rs2 == ex1_rd)  && (ex1_rd  != 5'h0)) ? ex1_value  :
        (ex0_valid  && (slot1_rs2 == ex0_rd)  && (ex0_rd  != 5'h0)) ? ex0_value  :
        (mem1_valid && (slot1_rs2 == mem1_rd) && (mem1_rd != 5'h0)) ? mem1_value :
        (mem0_valid && (slot1_rs2 == mem0_rd) && (mem0_rd != 5'h0)) ? mem0_value :
        (wb1_valid  && (slot1_rs2 == wb1_rd)  && (wb1_rd  != 5'h0)) ? wb1_value  :
        (wb0_valid  && (slot1_rs2 == wb0_rd)  && (wb0_rd  != 5'h0)) ? wb0_value  :
        slot1_rf_rs2;
endmodule
