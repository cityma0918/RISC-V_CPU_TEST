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
    la s2, mem_area

    addi x1,  x0, 11
    addi x2,  x0, 22
    addi x3,  x0, 33
    addi x4,  x0, 44
    add  x5,  x1, x2
    add  x6,  x3, x4
    xor  x7,  x4, x1
    or   x8,  x2, x3
    li   t2, 33
    bne  x5, t2, fail
    li   t2, 77
    bne  x6, t2, fail
    li   t2, 39
    bne  x7, t2, fail
    li   t2, 55
    bne  x8, t2, fail

    add  x9,  x1, x1
    add  x10, x9, x2
    li   t2, 44
    bne  x10, t2, fail

    addi x11, x0, 1
    addi x11, x11, 2
    li   t2, 3
    bne  x11, t2, fail

    sw   x6, 0(s2)
    lw   x12, 0(s2)
    addi x13, x12, -7
    li   t2, 70
    bne  x13, t2, fail

    beq  x13, x13, branch_ok
    addi x14, x0, 99
branch_ok:
    addi x14, x0, 5
    li   t2, 5
    bne  x14, t2, fail

    lw   x20, 0(s2)
    addi x21, x0, 4
    add  x22, x21, x21
    addi x23, x22, -8
    bne  x23, x0, fail
    li   t2, 77
    bne  x20, t2, fail

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
