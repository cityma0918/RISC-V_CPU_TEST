.section .text.init
.globl _start

.macro PASS
    li t0, 0x1000
    addi t1, x0, 1
    sw t1, 0(t0)
1:
    jal x0, 1b
.endm

.macro FAIL
    li t0, 0x1000
    addi t1, x0, 2
    sw t1, 0(t0)
1:
    jal x0, 1b
.endm

.macro CHECK reg, imm
    li t6, \imm
    bne \reg, t6, fail
.endm

.macro CHECK_REG reg_l, reg_r
    bne \reg_l, \reg_r, fail
.endm

_start:
    la s0, mem_area

    # U-type
    lui t0, 0x12345
    CHECK t0, 0x12345000

    auipc t1, 0
    addi t2, t1, 8
    sub t3, t2, t1
    CHECK t3, 8

    # I-type arithmetic and logic
    li t0, -5
    addi t1, t0, 17
    CHECK t1, 12

    slti t2, t0, -3
    CHECK t2, 1

    sltiu t3, t0, 4
    CHECK t3, 0

    xori t4, t1, 0x3f
    CHECK t4, 51

    ori t5, t1, 0x40
    CHECK t5, 76

    andi t6, t5, 0x4c
    addi a6, t6, 0
    CHECK a6, 76

    slli a0, t1, 2
    CHECK a0, 48

    srli a1, a0, 3
    CHECK a1, 6

    li a2, -32
    srai a3, a2, 2
    CHECK a3, -8

    # R-type arithmetic and logic
    li s1, 144
    li s2, 3

    add s3, s1, s2
    CHECK s3, 147

    sub s4, s1, s2
    CHECK s4, 141

    sll s5, s2, s2
    CHECK s5, 24

    slt s6, s2, s1
    CHECK s6, 1

    sltu s7, s1, s2
    CHECK s7, 0

    xor s8, s1, s2
    CHECK s8, 147

    srl s9, s1, s2
    CHECK s9, 18

    li s10, -64
    sra s11, s10, s2
    CHECK s11, -8

    or a4, s1, s2
    CHECK a4, 147

    and a5, s1, s2
    CHECK a5, 0

    # Additional signed/unsigned comparisons
    li a6, -1
    li a7, 1
    slt t0, a6, a7
    CHECK t0, 1
    sltu t1, a6, a7
    CHECK t1, 0

    # Memory operations
    li t2, 0x11223344
    sw t2, 0(s0)
    lw t3, 0(s0)
    CHECK t3, 0x11223344

    li t2, 0xaa
    sb t2, 4(s0)
    lbu t3, 4(s0)
    CHECK t3, 0xaa
    lb t4, 4(s0)
    CHECK t4, -86

    li t2, 0x55
    sb t2, 5(s0)
    lbu t3, 5(s0)
    CHECK t3, 0x55

    li t2, 0x7788
    sh t2, 6(s0)
    lhu t3, 6(s0)
    CHECK t3, 0x7788
    lh t4, 6(s0)
    CHECK t4, 0x7788

    li t2, 0xf188
    sh t2, 8(s0)
    lhu t3, 8(s0)
    CHECK t3, 0xf188
    lh t4, 8(s0)
    CHECK t4, -3704

    li t2, 0x7f
    sb t2, 10(s0)
    lb t3, 10(s0)
    CHECK t3, 127

    # Branch behavior: taken and not-taken
    li t0, 5
    li t1, 5
    beq t0, t1, 1f
    jal x0, fail
1:
    bne t0, t1, fail

    li t1, 6
    bne t0, t1, 2f
    jal x0, fail
2:
    beq t0, t1, fail

    li t0, -1
    li t1, 1
    blt t0, t1, 3f
    jal x0, fail
3:
    bge t0, t1, fail

    bltu t0, t1, fail
    bgeu t0, t1, 4f
    jal x0, fail
4:

    li t0, 9
    li t1, 3
    bge t0, t1, 5f
    jal x0, fail
5:
    blt t0, t1, fail

    bgeu t0, t1, 6f
    jal x0, fail
6:
    bltu t0, t1, fail

    # Counted loop to stress addi + branch + shifts
    li s1, 0
    li s2, 6
    li s3, 1
7:
    add s1, s1, s3
    slli s3, s3, 1
    addi s2, s2, -1
    bne s2, x0, 7b
    CHECK s1, 63

    srli s4, s1, 1
    CHECK s4, 31

    srai s5, s10, 4
    CHECK s5, -4

    # JAL
    jal s6, jal_target
jal_return:
    jal x0, fail
jal_target:
    la s7, jal_return
    CHECK_REG s6, s7

    # JALR
    la s8, jalr_target
    jalr s9, s8, 0
jalr_return:
    jal x0, fail
jalr_target:
    la s10, jalr_return
    CHECK_REG s9, s10

    # Mix load/store and ALU after control flow
    sw s1, 12(s0)
    lw s11, 12(s0)
    CHECK s11, 63

    add a0, s11, s4
    CHECK a0, 94

    xor a1, a0, s3
    CHECK a1, 30

    andi a2, a1, 0x1f
    CHECK a2, 30

    ori a3, a2, 0x40
    CHECK a3, 94

    PASS

fail:
    FAIL

.section .data
.align 4
mem_area:
    .word 0, 0, 0, 0, 0, 0, 0, 0

.section .signature,"aw"
.align 4
signature:
    .word 0
