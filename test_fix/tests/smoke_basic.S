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
    addi x1, x0, 5
    addi x2, x0, 7
    add x3, x1, x2
    li t2, 12
    bne x3, t2, fail

    lui x4, 0x1
    auipc x5, 0
    addi x5, x5, 8

    la x6, mem_area
    sw x3, 0(x6)
    lw x7, 0(x6)
    bne x7, x3, fail

    beq x7, x3, pass
    jal x0, fail

pass:
    PASS

fail:
    FAIL

.section .data
.align 4
mem_area:
    .word 0

.section .signature,"aw"
.align 4
signature:
    .word 0
