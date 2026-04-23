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

_start:
    la s0, mem_area

    addi x1, x0, 3
    add  x2, x1, x1
    add  x3, x2, x1
    add  x4, x3, x2
    li t2, 15
    bne x4, t2, fail

    addi x5, x0, 11
    addi x6, x0, 2
    add  x7, x5, x6
    li t2, 13
    bne x7, t2, fail

    sw   x4, 0(s0)
    lw   x15, 0(s0)
    add  x9, x15, x1
    li t2, 18
    bne x9, t2, fail

    addi x10, x0, 20
    sw   x10, 4(s0)
    lw   x11, 4(s0)
    addi x12, x11, -5
    bne  x12, x4, fail

    addi x13, x0, 0x55
    sb   x13, 8(s0)
    lbu  x14, 8(s0)
    bne  x14, x13, fail

    PASS

fail:
    FAIL

.section .data
.align 4
mem_area:
    .word 0, 0, 0, 0

.section .signature,"aw"
.align 4
signature:
    .word 0
