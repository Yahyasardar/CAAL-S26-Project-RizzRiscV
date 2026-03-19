# N-Body Simulation - RISC-V 64-bit Assembly
# Leapfrog KDK integrator with naive O(N^2) force calculation

.equ N, 300

# Reserve stack space in BSS
.section .bss
.align 4
stack_mem: .space 65536
stack_top:

# Constants and shared memory filename
.section .data
.align 3
dt:      .double 1000.0
dt_half: .double 500.0
eps:     .double 1.0e9
G_const: .double 6.67430e-11
one:     .double 1.0
fname:   .string "shared.mem"

# Particle data generated from CSV
.include "mydata.S"

.section .text
.globl _start

_start:
    la sp, stack_top

    # Open the shared memory file so Python GUI can read positions
    li a7, 56 ; li a0, -100 ; la a1, fname ; li a2, 578 ; li a3, 0644 ; ecall ; mv s0, a0

    # Set file size: 8 byte flag + 3 arrays * N * 8 bytes = 7208
    li a7, 46 ; mv a0, s0 ; li a1, 7208 ; ecall

    # Map the file into memory, s1 holds the base address
    li a7, 222 ; li a0, 0 ; li a1, 7208 ; li a2, 3 ; li a3, 1 ; mv a4, s0 ; li a5, 0 ; ecall ; mv s1, a0

    # Calculate initial forces before entering the loop
    addi sp, sp, -16 ; sd s0, 0(sp) ; sd s1, 8(sp)
    call calc_acc
    ld s0, 0(sp) ; ld s1, 8(sp) ; addi sp, sp, 16

main_loop:
    # Save file descriptor and mmap pointer before calling functions
    addi sp, sp, -16 ; sd s0, 0(sp) ; sd s1, 8(sp)

    # Leapfrog KDK: half kick, drift, recalculate forces, half kick
    call calc_kick
    call calc_drift
    call calc_acc
    call calc_kick

    ld s0, 0(sp) ; ld s1, 8(sp) ; addi sp, sp, 16

    # Set flag to 1 so Python knows we are writing
    li t0, 1 ; sd t0, 0(s1)

    # Write positions to mmap: p_x at offset 8, p_y at 2408, p_z at 4808
    la t1, p_x ; addi t2, s1, 8 ; call write_array
    la t1, p_y ; li t2, 2408 ; add t2, s1, t2 ; call write_array
    la t1, p_z ; li t2, 4808 ; add t2, s1, t2 ; call write_array

    # Clear flag so Python knows writing is done
    sd zero, 0(s1)

    # Uncomment below line when running QEMU profiling plugin
    # j exit_gracefully
    j main_loop


# Copies N doubles from src (t1) to dst (t2)
write_array:
    li t3, 0
wa_loop:
    li t4, N ; bge t3, t4, wa_done
    slli t5, t3, 3
    add t6, t1, t5 ; fld fa0, 0(t6)
    add t6, t2, t5 ; fsd fa0, 0(t6)
    addi t3, t3, 1 ; j wa_loop
wa_done:
    ret


# Half-step velocity update: v = v + a * dt_half
calc_kick:
    addi sp, sp, -8 ; sd ra, 0(sp)
    la t0, dt_half ; fld fa0, 0(t0)
    li t0, 0
kick_loop:
    li t1, N ; bge t0, t1, kick_done
    slli t2, t0, 3
    la t3, a_x ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, v_x ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    la t3, a_y ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, v_y ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    la t3, a_z ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, v_z ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    addi t0, t0, 1 ; j kick_loop
kick_done:
    ld ra, 0(sp) ; addi sp, sp, 8 ; ret


# Full-step position update: p = p + v * dt
calc_drift:
    addi sp, sp, -8 ; sd ra, 0(sp)
    la t0, dt ; fld fa0, 0(t0)
    li t0, 0
drift_loop:
    li t1, N ; bge t0, t1, drift_done
    slli t2, t0, 3
    la t3, v_x ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, p_x ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    la t3, v_y ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, p_y ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    la t3, v_z ; add t3, t3, t2 ; fld fa1, 0(t3)
    la t3, p_z ; add t3, t3, t2 ; fld fa2, 0(t3) ; fmadd.d fa2, fa1, fa0, fa2 ; fsd fa2, 0(t3)
    addi t0, t0, 1 ; j drift_loop
drift_done:
    ld ra, 0(sp) ; addi sp, sp, 8 ; ret


# Naive O(N^2) pairwise force calculation
# For each pair (i,j) compute gravitational acceleration and apply Newton's 3rd law
calc_acc:
    addi sp, sp, -96
    sd ra, 0(sp) ; sd s0, 8(sp) ; sd s1, 16(sp) ; sd s2, 24(sp) ; sd s3, 32(sp)
    sd s4, 40(sp) ; sd s5, 48(sp) ; sd s6, 56(sp) ; sd s7, 64(sp)
    fsd fs0, 72(sp) ; fsd fs1, 80(sp) ; fsd fs2, 88(sp)

    # Load G, epsilon, and 1.0 into saved float registers
    la t0, G_const ; fld fs0, 0(t0)
    la t0, eps     ; fld fs1, 0(t0)
    la t0, one     ; fld fs2, 0(t0)

    # Zero out all accelerations before computing new ones
    fmv.d.x fa0, zero
    li t0, 0
reset_loop:
    li t1, N ; bge t0, t1, reset_done
    slli t2, t0, 3
    la t3, a_x ; add t3, t3, t2 ; fsd fa0, 0(t3)
    la t3, a_y ; add t3, t3, t2 ; fsd fa0, 0(t3)
    la t3, a_z ; add t3, t3, t2 ; fsd fa0, 0(t3)
    addi t0, t0, 1 ; j reset_loop
reset_done:

    li s6, 0
outer_loop:
    li t0, N ; bge s6, t0, acc_done
    slli s0, s6, 3

    # Load position, mass and current acceleration of body i
    la t1, p_x ; add t1, t1, s0 ; fld ft0, 0(t1)
    la t1, p_y ; add t1, t1, s0 ; fld ft1, 0(t1)
    la t1, p_z ; add t1, t1, s0 ; fld ft2, 0(t1)
    la t1, mass_grid ; add t1, t1, s0 ; fld ft3, 0(t1)
    la t1, a_x ; add t1, t1, s0 ; fld ft4, 0(t1)
    la t1, a_y ; add t1, t1, s0 ; fld ft5, 0(t1)
    la t1, a_z ; add t1, t1, s0 ; fld ft6, 0(t1)

    addi s7, s6, 1
inner_loop:
    li t0, N ; bge s7, t0, inner_done
    slli s1, s7, 3

    # Compute displacement vector from i to j
    la t1, p_x ; add t1, t1, s1 ; fld fa0, 0(t1) ; fsub.d fa0, fa0, ft0
    la t1, p_y ; add t1, t1, s1 ; fld fa1, 0(t1) ; fsub.d fa1, fa1, ft1
    la t1, p_z ; add t1, t1, s1 ; fld fa2, 0(t1) ; fsub.d fa2, fa2, ft2

    # r = sqrt(dx^2 + dy^2 + dz^2 + eps^2) then compute G/r^3
    fmul.d fa3, fa0, fa0 ; fmul.d fa4, fa1, fa1 ; fadd.d fa3, fa3, fa4
    fmul.d fa4, fa2, fa2 ; fadd.d fa3, fa3, fa4
    fmul.d fa4, fs1, fs1 ; fadd.d fa3, fa3, fa4
    fsqrt.d fa3, fa3
    fmul.d fa4, fa3, fa3 ; fmul.d fa4, fa4, fa3
    fdiv.d fa4, fs2, fa4 ; fmul.d fa4, fs0, fa4

    la t1, mass_grid ; add t1, t1, s1 ; fld fa5, 0(t1)

    # Accumulate acceleration on body i using mass of j
    fmul.d fa6, fa0, fa4 ; fmul.d fa6, fa6, fa5 ; fadd.d ft4, ft4, fa6
    fmul.d fa6, fa1, fa4 ; fmul.d fa6, fa6, fa5 ; fadd.d ft5, ft5, fa6
    fmul.d fa6, fa2, fa4 ; fmul.d fa6, fa6, fa5 ; fadd.d ft6, ft6, fa6

    # Apply equal and opposite force on body j using mass of i
    la t1, a_x ; add t1, t1, s1 ; fld fa6, 0(t1)
    fmul.d fa7, fa0, fa4 ; fmul.d fa7, fa7, ft3 ; fsub.d fa6, fa6, fa7 ; fsd fa6, 0(t1)
    la t1, a_y ; add t1, t1, s1 ; fld fa6, 0(t1)
    fmul.d fa7, fa1, fa4 ; fmul.d fa7, fa7, ft3 ; fsub.d fa6, fa6, fa7 ; fsd fa6, 0(t1)
    la t1, a_z ; add t1, t1, s1 ; fld fa6, 0(t1)
    fmul.d fa7, fa2, fa4 ; fmul.d fa7, fa7, ft3 ; fsub.d fa6, fa6, fa7 ; fsd fa6, 0(t1)

    addi s7, s7, 1 ; j inner_loop

inner_done:
    # Write back accumulated acceleration for body i
    la t1, a_x ; add t1, t1, s0 ; fsd ft4, 0(t1)
    la t1, a_y ; add t1, t1, s0 ; fsd ft5, 0(t1)
    la t1, a_z ; add t1, t1, s0 ; fsd ft6, 0(t1)
    addi s6, s6, 1 ; j outer_loop

acc_done:
    ld ra, 0(sp) ; ld s0, 8(sp) ; ld s1, 16(sp) ; ld s2, 24(sp) ; ld s3, 32(sp)
    ld s4, 40(sp) ; ld s5, 48(sp) ; ld s6, 56(sp) ; ld s7, 64(sp)
    fld fs0, 72(sp) ; fld fs1, 80(sp) ; fld fs2, 88(sp)
    addi sp, sp, 96 ; ret

exit_gracefully:
    li a7, 93 ; li a0, 0 ; ecall
