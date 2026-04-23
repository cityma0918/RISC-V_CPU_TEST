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

    addi t0, x0, 5
    sw   t0, 0(s0)

    lw   t1, 0(s0)
    addi t2, x0, 7
    add  t3, t1, t2
    li   t4, 12
    bne  t3, t4, fail

    sw   t3, 4(s0)
    addi t6, x0, 1
    lw   s1, 4(s0)
    bne  s1, t3, fail
    addi t5, x0, 9
    add  s3, t5, t6
    li   t4, 10
    bne  s3, t4, fail

    PASS

fail:
    FAIL

.section .data
.align 4
mem_area:
    .word 0, 0

.section .signature,"aw"
.align 4
signature:
    .word 0
