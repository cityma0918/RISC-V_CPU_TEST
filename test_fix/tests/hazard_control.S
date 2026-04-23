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
    addi x1, x0, 0

    beq  x1, x0, taken0
    addi x2, x0, 99
taken0:
    addi x2, x0, 5
    li   t2, 5
    bne  x2, t2, fail

    bne  x1, x0, target1
    addi x3, x0, 7
    jal  x0, after1
target1:
    addi x3, x0, 99
after1:
    li   t2, 7
    bne  x3, t2, fail

    jal  x0, jal_target
    addi x4, x0, 99
jal_target:
    addi x4, x0, 11
    li   t2, 11
    bne  x4, t2, fail

    la   x5, jalr_target
    jalr x0, x5, 0
    addi x6, x0, 99
jalr_target:
    addi x6, x0, 13
    li   t2, 13
    bne  x6, t2, fail

    PASS

fail:
    FAIL

.section .signature,"aw"
.align 4
signature:
    .word 0
