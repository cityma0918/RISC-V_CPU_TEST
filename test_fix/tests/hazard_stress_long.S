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

    # Seed memory for load-use and store-data chains
    li t0, 7
    sw t0, 0(s0)
    li t0, 21
    sw t0, 4(s0)
    li t0, 0x80
    sb t0, 8(s0)
    li t0, 0x8123
    sh t0, 10(s0)

    # Word load-use chain
    lw t1, 0(s0)
    add t2, t1, t1
    CHECK t2, 14

    sub t3, t2, t1
    CHECK t3, 7

    addi t4, t3, 9
    CHECK t4, 16

    sw t4, 12(s0)
    lw t5, 12(s0)
    CHECK t5, 16

    add t6, t5, t2
    addi s6, t6, 0
    CHECK s6, 30

    # Store-data forwarding style chain
    xor a0, t6, t1
    CHECK a0, 25

    sw a0, 16(s0)
    lw a1, 16(s0)
    CHECK a1, 25

    add a2, a1, t5
    CHECK a2, 41

    sw a2, 20(s0)
    lw a3, 20(s0)
    CHECK a3, 41

    # Signed/unsigned byte load hazards
    lb a4, 8(s0)
    CHECK a4, -128

    lbu a5, 8(s0)
    CHECK a5, 128

    add a6, a4, a5
    CHECK a6, 0

    # Signed/unsigned halfword load hazards
    lh a7, 10(s0)
    CHECK a7, -32477

    lhu s1, 10(s0)
    CHECK s1, 0x8123

    li s2, 32477
    add s2, a7, s2
    CHECK s2, 0

    sub s3, s1, a5
    CHECK s3, 32931

    sh s3, 24(s0)
    lhu s4, 24(s0)
    CHECK s4, 32931

    # Branch compare immediately after producing values
    add s5, a3, t1
    CHECK s5, 48

    addi s6, s5, -48
    CHECK s6, 0

    beq s6, x0, 1f
    jal x0, fail
1:
    bne s6, x0, fail

    slti s7, s5, 64
    CHECK s7, 1

    bne s7, x0, 2f
    jal x0, fail
2:

    li s8, -5
    li s9, 2
    blt s8, s9, 3f
    jal x0, fail
3:
    bge s8, s9, fail

    li s10, -1
    li s11, 1
    bgeu s10, s11, 4f
    jal x0, fail
4:
    bltu s10, s11, fail

    # JAL dependency and control redirection
    jal a0, jal_block
after_jal:
    jal x0, fail
jal_block:
    la a1, after_jal
    CHECK_REG a0, a1
    addi a2, a0, 4
    la a3, jal_block
    CHECK_REG a2, a3
fail_after_jal:

    # JALR dependency and redirection
    la a4, jalr_block
    jalr a5, a4, 0
after_jalr:
    jal x0, fail
jalr_block:
    la a6, after_jalr
    CHECK_REG a5, a6
    addi a7, a5, 4
    la s1, jalr_block
    CHECK_REG a7, s1

    # A short counted loop to stress repeated load-use and branch
    li s2, 3
    li s3, 0
5:
    lw s4, 4(s0)
    add s3, s3, s4
    addi s2, s2, -1
    bne s2, x0, 5b
    CHECK s3, 63

    sw s3, 28(s0)
    lw s5, 28(s0)
    CHECK s5, 63

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
