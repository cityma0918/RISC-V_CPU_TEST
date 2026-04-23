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
    addi x1,  x0, 1
    addi x2,  x0, 2
    addi x3,  x0, 3
    addi x4,  x0, 4
    addi x5,  x0, 5
    addi x6,  x0, 6
    addi x7,  x0, 7
    addi x8,  x0, 8

    add  x9,  x1, x2
    add  x10, x3, x4
    add  x11, x5, x6
    add  x12, x7, x8
    li   t2, 3
    bne  x9, t2, fail
    li   t2, 7
    bne  x10, t2, fail
    li   t2, 11
    bne  x11, t2, fail
    li   t2, 15
    bne  x12, t2, fail

    add  x13, x9, x10
    add  x13, x13, x11
    add  x13, x13, x12
    li   t2, 36
    bne  x13, t2, fail

    PASS

fail:
    FAIL

.section .signature,"aw"
.align 4
signature:
    .word 0
