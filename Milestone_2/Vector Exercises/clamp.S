.section .data
.align 2

clamp_a:   .word 10, 300, 255, 0, 1000, 128, 256, 5, 512, 200
clamp_out: .word  0,   0,   0, 0,    0,   0,   0, 0,   0,   0
clamp_n:   .word 10

fmt: .asciz "clamp_out[%d] = %d\n"

.section .text
.globl main

main:
    addi sp, sp, -16
    sd   ra, 8(sp)

    la   t0, clamp_a       # t0 = pointer to input array
    la   t1, clamp_out     # t1 = pointer to output array
    la   t2, clamp_n
    lw   t2, 0(t2)         # t2 = number of elements (10)
    li   t3, 255           # t3 = clamp threshold

clamp_loop:
    # Set vector length - how many elements to process this iteration
    vsetvli t4, t2, e32, m1, ta, ma

    # Load elements from input array into v1 (keep original here)
    vle32.v  v1, (t0)

    # Broadcast 255 into v2 so we can merge with it later
    vmv.v.x  v2, t3

    # Create mask in v0: bit=1 where element > 255 (the "hand raiser")
    # In RVV, vmerge always uses v0 as the mask register
    vmsgt.vx v0, v1, t3

    # Merge: where mask(v0)=1 pick v2(255), where mask=0 keep v1(original)
    vmerge.vvm v3, v1, v2, v0

    # Store the clamped results into output array
    vse32.v  v3, (t1)

    # Advance both pointers forward by (vl * 4) bytes
    slli t5, t4, 2
    add  t0, t0, t5        # move input pointer forward
    add  t1, t1, t5        # move output pointer forward
    sub  t2, t2, t4        # subtract processed count
    bnez t2, clamp_loop    # loop if more elements remain

    # Print results to verify
    la   s0, clamp_out
    li   s1, 0
    li   s2, 10

print_loop:
    bge  s1, s2, done
    slli t0, s1, 2
    add  t0, s0, t0
    lw   a2, 0(t0)
    mv   a1, s1
    la   a0, fmt
    call printf
    addi s1, s1, 1
    j    print_loop

done:
    ld   ra, 8(sp)
    addi sp, sp, 16
    li   a0, 0
    ret
