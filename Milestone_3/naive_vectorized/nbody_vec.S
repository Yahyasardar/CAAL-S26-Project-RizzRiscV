.equ N, 300

.section .data
.align 2
dt_val:       .float 10000.0
dt_half_val:  .float 5000.0
eps_sq_val:   .float 1.0e18
G_val:        .float 6.67430e-11
one_val:      .float 1.0

filename: .string "shared.mem"
.include "mydata.S"

.section .bss
.align 4
stack_bottom:
    .space 8192
stack_top:

.section .text
.globl _start

_start:
    la sp, stack_top

    # Shared Memory Setup
    li a7, 56
    li a0, -100
    la a1, filename
    li a2, 578
    li a3, 0644
    ecall
    mv s0, a0

    li a7, 46
    mv a0, s0
    li a1, 3608
    ecall

    li a7, 222
    li a0, 0
    li a1, 3608
    li a2, 3
    li a3, 1
    mv a4, s0
    li a5, 0
    ecall
    mv s1, a0

    # Benchmark: Run exactly 1 step for comparison [cite: 314]
    li s10, 1
    call calc_acc

main_loop:
    beqz s10, exit_sim
    call calc_kick
    call calc_drift
    call calc_acc
    call calc_kick

    # Sync to GUI
    li t0, 1
    sd t0, 0(s1)
    la t1, p_x ; addi t2, s1, 8 ; call write_array
    la t1, p_y ; li t2, 1208 ; add t2, s1, t2 ; call write_array
    la t1, p_z ; li t2, 2408 ; add t2, s1, t2 ; call write_array
    sd zero, 0(s1)

    addi s10, s10, -1
    j main_loop

exit_sim:
    li a7, 93
    li a0, 0
    ecall

write_array:
    li t3, 0
wa_loop:
    li t4, N ; bge t3, t4, wa_done
    slli t5, t3, 2 ; add t6, t1, t5 ; flw fa0, 0(t6)
    add t6, t2, t5 ; fsw fa0, 0(t6)
    addi t3, t3, 1 ; j wa_loop
wa_done:
    ret

calc_kick:
    la t0, dt_half_val ; flw fa0, 0(t0)
    li t1, N
    la t2, a_x ; la t3, v_x ; la t4, a_y ; la t5, v_y ; la t6, a_z ; la a1, v_z
kick_vec_loop:
    vsetvli t0, t1, e32, m1, ta, ma # Strip-mining [cite: 26, 72]
    vle32.v v1, (t2) ; vle32.v v2, (t3) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (t3)
    vle32.v v1, (t4) ; vle32.v v2, (t5) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (t5)
    vle32.v v1, (t6) ; vle32.v v2, (a1) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (a1)
    slli a2, t0, 2 ; add t2, t2, a2 ; add t3, t3, a2 ; add t4, t4, a2
    add t5, t5, a2 ; add t6, t6, a2 ; add a1, a1, a2 ; sub t1, t1, t0
    bnez t1, kick_vec_loop
    ret

calc_drift:
    la t0, dt_val ; flw fa0, 0(t0)
    li t1, N
    la t2, v_x ; la t3, p_x ; la t4, v_y ; la t5, p_y ; la t6, v_z ; la a1, p_z
drift_vec_loop:
    vsetvli t0, t1, e32, m1, ta, ma # Strip-mining [cite: 26, 73]
    vle32.v v1, (t2) ; vle32.v v2, (t3) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (t3)
    vle32.v v1, (t4) ; vle32.v v2, (t5) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (t5)
    vle32.v v1, (t6) ; vle32.v v2, (a1) ; vfmacc.vf v2, fa0, v1 ; vse32.v v2, (a1)
    slli a2, t0, 2 ; add t2, t2, a2 ; add t3, t3, a2 ; add t4, t4, a2
    add t5, t5, a2 ; add t6, t6, a2 ; add a1, a1, a2 ; sub t1, t1, t0
    bnez t1, drift_vec_loop
    ret

calc_acc:
    addi sp, sp, -96 # Stack preservation [cite: 303]
    sd ra, 0(sp) ; sd s0, 8(sp) ; sd s1, 16(sp) ; sd s6, 56(sp) ; sd s7, 64(sp)
    fsw fs0, 72(sp) ; fsw fs1, 76(sp) ; fsw fs2, 80(sp)
    la t0, G_val ; flw fs0, 0(t0)
    la t0, eps_sq_val ; flw fs1, 0(t0)
    la t0, one_val ; flw fs2, 0(t0)
    fmv.w.x fa0, zero 
    li t0, 0
reset_loop:
    li t1, N ; bge t0, t1, reset_done
    slli t2, t0, 2
    la t3, a_x ; add t3, t3, t2 ; fsw fa0, 0(t3)
    la t3, a_y ; add t3, t3, t2 ; fsw fa0, 0(t3)
    la t3, a_z ; add t3, t3, t2 ; fsw fa0, 0(t3)
    addi t0, t0, 1 ; j reset_loop
reset_done:
    li s6, 0
outer_loop:
    li t0, N ; bge s6, t0, acc_done
    slli s0, s6, 2
    la t1, p_x ; add t1, t1, s0 ; flw ft0, 0(t1)
    la t1, p_y ; add t1, t1, s0 ; flw ft1, 0(t1)
    la t1, p_z ; add t1, t1, s0 ; flw ft2, 0(t1)
    fmv.w.x ft4, zero ; fmv.w.x ft5, zero ; fmv.w.x ft6, zero
    li s7, 0 ; li t1, N
    la t2, p_x ; la t3, p_y ; la t4, p_z ; la t5, mass_grid
inner_vec_loop:
    vsetvli t0, t1, e32, m1, ta, ma # Strip-mining [cite: 26]
    vfmv.s.f v28, fa0 ; vfmv.s.f v29, fa0 ; vfmv.s.f v30, fa0
    vle32.v v4, (t2) ; vfsub.vf v4, v4, ft0
    vle32.v v5, (t3) ; vfsub.vf v5, v5, ft1
    vle32.v v6, (t4) ; vfsub.vf v6, v6, ft2
    vfmul.vv v7, v4, v4 ; vfmacc.vv v7, v5, v5 ; vfmacc.vv v7, v6, v6 ; vfadd.vf v7, v7, fs1 
    vfsqrt.v v8, v7 ; vfmv.v.f v9, fs2 ; vfdiv.vv v8, v9, v8   
    vfmul.vv v9, v8, v8 ; vfmul.vv v9, v9, v8
    vle32.v v10, (t5) ; vfmul.vv v11, v10, v9 
    vid.v v12 ; vadd.vx v12, v12, s7
    vmsne.vx v0, v12, s6 # Masking for i != j [cite: 13, 116]
    vfmv.v.f v13, fa0 ; vmerge.vvm v11, v13, v11, v0
    vfmul.vv v14, v4, v11 ; vfmul.vv v15, v5, v11 ; vfmul.vv v16, v6, v11
    vredsum.vs v28, v14, v28 ; vredsum.vs v29, v15, v29 ; vredsum.vs v30, v16, v30
    vfmv.f.s fa1, v28 ; vfmv.f.s fa2, v29 ; vfmv.f.s fa3, v30
    fadd.s ft4, ft4, fa1 ; fadd.s ft5, ft5, fa2 ; fadd.s ft6, ft6, fa3
    slli a2, t0, 2
    add t2, t2, a2 ; add t3, t3, a2 ; add t4, t4, a2 ; add t5, t5, a2
    add s7, s7, t0 ; sub t1, t1, t0
    bnez t1, inner_vec_loop
    fmul.s ft4, ft4, fs0 ; fmul.s ft5, ft5, fs0 ; fmul.s ft6, ft6, fs0
    la t1, a_x ; add t1, t1, s0 ; fsw ft4, 0(t1)
    la t1, a_y ; add t1, t1, s0 ; fsw ft5, 0(t1)
    la t1, a_z ; add t1, t1, s0 ; fsw ft6, 0(t1)
    addi s6, s6, 1 ; j outer_loop
acc_done:
    ld ra, 0(sp) ; ld s0, 8(sp) ; ld s1, 16(sp) ; ld s6, 56(sp) ; ld s7, 64(sp)
    flw fs0, 72(sp) ; flw fs1, 76(sp) ; flw fs2, 80(sp)
    addi sp, sp, 96 ; ret
