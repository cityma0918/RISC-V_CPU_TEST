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

_start:
    la s0, mem_area

    li s1, 1
    li s2, 2
    li s3, 3
    li s4, 4
    li s5, 5
    li s6, 6
    li s7, 7
    li s8, 8
    li s9, 9
    li s10, 10
    li s11, 11

    li t0, 0x00000011
    sw t0, 0(s0)
    li t0, 0x00000022
    sw t0, 4(s0)
    li t0, 0x00000033
    sw t0, 8(s0)
    li t0, 0x0000ff80
    sw t0, 12(s0)
    li t0, 0x13572468
    sw t0, 16(s0)

    # Positive LS -> X pair candidates
    lw t1, 0(s0)
    add a0, s1, s2

    lw t2, 4(s0)
    sub a1, s5, s2

    lb t3, 12(s0)
    xor a2, s7, s8

    lbu t4, 12(s0)
    or a3, s3, s4

    lh t5, 16(s0)
    and a4, s9, s10

    lhu a5, 16(s0)
    sll a6, s2, s1

    # Store + X pair candidates
    sw a0, 20(s0)
    addi a7, s11, 5

    sh a1, 24(s0)
    slti t0, a7, 20

    sb a2, 26(s0)
    sltu t6, s1, s8

    sw a3, 28(s0)
    xori s1, a4, 0x1f

    sh a6, 32(s0)
    ori s2, a7, 0x20

    sb t4, 34(s0)
    andi s3, s2, 0x2f

    # Negative patterns mixed in, should stay single-issue in v1
    add s4, s3, s1
    lw s5, 8(s0)

    add s6, s5, s4
    add s7, s6, s3

    lw s8, 20(s0)
    lw s9, 28(s0)

    # Check loaded values
    CHECK t1, 0x11
    CHECK t2, 0x22
    CHECK t3, -128
    CHECK t4, 128
    CHECK t5, 0x2468
    CHECK a5, 0x2468

    # Check X-lane results
    CHECK a0, 3
    CHECK a1, 3
    CHECK a2, 15
    CHECK a3, 7
    CHECK a4, 8
    CHECK a6, 4
    CHECK a7, 16
    CHECK t0, 1
    addi a4, t6, 0
    CHECK a4, 1
    CHECK s1, 23
    CHECK s2, 48
    CHECK s3, 32

    # Check store results
    lw s10, 20(s0)
    CHECK s10, 3

    lhu s11, 24(s0)
    CHECK s11, 3

    lbu a0, 26(s0)
    CHECK a0, 15

    lw a1, 28(s0)
    CHECK a1, 7

    lhu a2, 32(s0)
    CHECK a2, 4

    lbu a3, 34(s0)
    CHECK a3, 128

    # Final checksum across loaded and ALU results
    add a4, t1, t2
    add a4, a4, t4
    add a4, a4, a0
    add a4, a4, a1
    add a4, a4, a2
    add a4, a4, a3
    CHECK a4, 333

    PASS

fail:
    FAIL

.section .data
.align 4
mem_area:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.section .signature,"aw"
.align 4
signature:
    .word 0
