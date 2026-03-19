.section .data
.align 2

neg_a:     .word -1, 5, -3, 0, -100, 42, -7, 8, -9, 10
neg_n:     .word 10
neg_result:.word 0
fmt: .asciz "Negative count = %d\n"

.section .text
.globl main

main:
    addi sp, sp, -16
    sd   ra, 8(sp)

    la   t0, neg_a         # t0 = pointer to array
    la   t1, neg_n
    lw   t1, 0(t1)         # t1 = n = 10
    li   t2, 0             # t2 = running total count
    li   t3, 0             # t3 = 0 (threshold for < 0)

neg_loop:
    vsetvli t4, t1, e32, m1, ta, ma   # set vector length
    vle32.v  v0, (t0)      # load elements into v0
    vmslt.vx v1, v0, t3    # mask: bit=1 where element < 0
    vcpop.m  t5, v1        # count the 1-bits in mask
    add  t2, t2, t5        # total_count += t5
    slli t6, t4, 2         # t6 = vl * 4
    add  t0, t0, t6        # advance pointer
    sub  t1, t1, t4        # remaining -= vl
    bnez t1, neg_loop      # loop if remaining > 0

    la   t0, neg_result
    sw   t2, 0(t0)         # store final count

    lw   a1, 0(t0)         # a1 = result
    la   a0, fmt           # a0 = format string
    call printf            # print result

    ld   ra, 8(sp)
    addi sp, sp, 16
    li   a0, 0
    ret
