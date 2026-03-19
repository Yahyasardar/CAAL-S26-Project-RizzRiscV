.section .data
.align 2

dot_a:     .word 1, 2, 3, 4,  5,  6,  7,  8,  9, 10
dot_b:     .word 10, 9, 8, 7, 6,  5,  4,  3,  2,  1
dot_n:     .word 10
dot_result:.word 0
fmt: .asciz "Dot product = %d\n"

.section .text
.globl main

main:
    addi sp, sp, -16
    sd   ra, 8(sp)

    la   t0, dot_a         # t0 = pointer to array a
    la   t1, dot_b         # t1 = pointer to array b
    la   t2, dot_n
    lw   t2, 0(t2)         # t2 = n = 10

    # initialize accumulator vector v3 to zero
    vsetvli t4, t2, e32, m1, ta, ma
    vmv.v.i  v3, 0         # v3 = [0, 0, 0, ...]

dot_loop:
    vsetvli t4, t2, e32, m1, ta, ma   # set vector length
    vle32.v  v0, (t0)      # load elements from a[]
    vle32.v  v1, (t1)      # load elements from b[]
    vmul.vv  v2, v0, v1    # v2[k] = a[k] * b[k]
    vredsum.vs v3, v2, v3  # v3[0] += sum of all v2 elements
    slli t5, t4, 2         # t5 = vl * 4
    add  t0, t0, t5        # advance a pointer
    add  t1, t1, t5        # advance b pointer
    sub  t2, t2, t4        # remaining -= vl
    bnez t2, dot_loop      # loop if remaining > 0

    # extract scalar result from v3[0]
    vmv.x.s  t0, v3        # t0 = final dot product

    # store and print result
    la   t1, dot_result
    sw   t0, 0(t1)
    lw   a1, 0(t1)
    la   a0, fmt
    call printf

    ld   ra, 8(sp)
    addi sp, sp, 16
    li   a0, 0
    ret
