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

    addi x1, x0, 1
    addi x2, x0, 2
    addi x3, x0, 3

    sw   x1, 0(s0)
    sh   x2, 4(s0)
    sb   x3, 8(s0)
    lw   x4, 0(s0)
    lh   x5, 4(s0)
    lbu  x6, 8(s0)

    bne  x4, x1, fail
    bne  x5, x2, fail
    bne  x6, x3, fail

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
