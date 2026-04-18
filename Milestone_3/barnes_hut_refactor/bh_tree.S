# Barnes-Hut Scalar Tree Implementation (Milestone 3)
# Contains array-based tree memory and recursive build logic.

.equ MAX_NODES, 2500
.equ N, 300

.section .data
.align 2
node_count: .word 0
root_size:  .float 1000000000.0  # Large bounding box for N-body systems

# 0-initialized arrays (2500 * 4 bytes = 10000 bytes each)
node_cx:    .space 10000
node_cy:    .space 10000
node_cz:    .space 10000
node_size:  .space 10000
node_mass:  .space 10000
node_com_x: .space 10000
node_com_y: .space 10000
node_com_z: .space 10000

# Arrays requiring specific initial values
node_is_leaf:
    .rept MAX_NODES
    .word 1
    .endr

node_particle:
    .rept MAX_NODES
    .word -1
    .endr

node_child:
    .rept MAX_NODES * 8
    .word -1
    .endr


.section .text
.globl reset_pool
.globl allocate_node
.globl get_octant
.globl create_child
.globl insert_particle
.globl build_tree

# --- reset_pool ---
reset_pool:
    la t0, node_count
    sw zero, 0(t0)
    ret

# --- allocate_node ---
# Input: fa0 = cx, fa1 = cy, fa2 = cz, fa3 = size
# Output: a0 = node index
allocate_node:
    la t0, node_count
    lw t1, 0(t0)          
    addi t2, t1, 1
    sw t2, 0(t0)          

    slli t3, t1, 2

    la t4, node_cx ; add t4, t4, t3 ; fsw fa0, 0(t4)
    la t4, node_cy ; add t4, t4, t3 ; fsw fa1, 0(t4)
    la t4, node_cz ; add t4, t4, t3 ; fsw fa2, 0(t4)
    la t4, node_size ; add t4, t4, t3 ; fsw fa3, 0(t4)

    fmv.w.x ft0, zero
    la t4, node_mass ; add t4, t4, t3 ; fsw ft0, 0(t4)

    li t5, 1
    la t4, node_is_leaf ; add t4, t4, t3 ; sw t5, 0(t4)
    
    li t5, -1
    la t4, node_particle ; add t4, t4, t3 ; sw t5, 0(t4)

    slli t6, t1, 5
    la t4, node_child ; add t4, t4, t6
    sw t5, 0(t4) ; sw t5, 4(t4) ; sw t5, 8(t4) ; sw t5, 12(t4)
    sw t5, 16(t4) ; sw t5, 20(t4) ; sw t5, 24(t4) ; sw t5, 28(t4)

    mv a0, t1             
    ret

# --- get_octant ---
# Input: a0 = node_idx, fa0 = px, fa1 = py, fa2 = pz
# Output: a0 = octant index (0-7)
get_octant:
    slli t0, a0, 2          
    li t1, 0                

    la t2, node_cx ; add t2, t2, t0 ; flw ft0, 0(t2)
    flt.s t3, ft0, fa0      
    or t1, t1, t3

    la t2, node_cy ; add t2, t2, t0 ; flw ft0, 0(t2)
    flt.s t3, ft0, fa1      
    slli t3, t3, 1          
    or t1, t1, t3

    la t2, node_cz ; add t2, t2, t0 ; flw ft0, 0(t2)
    flt.s t3, ft0, fa2      
    slli t3, t3, 2          
    or t1, t1, t3

    mv a0, t1
    ret

# --- create_child ---
# Input: a0 = node_idx, a1 = k (octant index)
# Output: a0 = child_idx
create_child:
    addi sp, sp, -32
    sd ra, 0(sp) ; sd s0, 8(sp) ; sd s1, 16(sp) ; fsw fs0, 24(sp)

    mv s0, a0
    mv s1, a1
    slli t0, s0, 2  

    la t1, node_size ; add t1, t1, t0 ; flw ft0, 0(t1)
    li t2, 0x40000000 
    fmv.w.x ft1, t2
    fdiv.s fs0, ft0, ft1 

    andi t3, s1, 1 ; bnez t3, pos_dx ; fneg.s ft2, fs0 ; j calc_cx
pos_dx: fmv.s ft2, fs0
calc_cx: la t1, node_cx ; add t1, t1, t0 ; flw ft3, 0(t1) ; fadd.s fa0, ft3, ft2 

    andi t3, s1, 2 ; bnez t3, pos_dy ; fneg.s ft2, fs0 ; j calc_cy
pos_dy: fmv.s ft2, fs0
calc_cy: la t1, node_cy ; add t1, t1, t0 ; flw ft3, 0(t1) ; fadd.s fa1, ft3, ft2 

    andi t3, s1, 4 ; bnez t3, pos_dz ; fneg.s ft2, fs0 ; j calc_cz
pos_dz: fmv.s ft2, fs0
calc_cz: la t1, node_cz ; add t1, t1, t0 ; flw ft3, 0(t1) ; fadd.s fa2, ft3, ft2 

    fmv.s fa3, fs0
    call allocate_node

    slli t0, s0, 5 ; slli t1, s1, 2 ; add t2, t0, t1      
    la t3, node_child ; add t3, t3, t2 ; sw a0, 0(t3)

    ld ra, 0(sp) ; ld s0, 8(sp) ; ld s1, 16(sp) ; flw fs0, 24(sp)
    addi sp, sp, 32
    ret

# --- insert_particle ---
# Input: a0 = node_idx, a1 = p_idx
insert_particle:
    addi sp, sp, -64
    sd ra, 0(sp) ; sd s0, 8(sp) ; sd s1, 16(sp) ; sd s2, 24(sp)
    fsw fs0, 32(sp) ; fsw fs1, 36(sp) ; fsw fs2, 40(sp) ; fsw fs3, 44(sp)

    mv s0, a0
    mv s1, a1

    slli t1, s1, 2
    la t2, p_x ; add t2, t2, t1 ; flw fs0, 0(t2)
    la t2, p_y ; add t2, t2, t1 ; flw fs1, 0(t2)
    la t2, p_z ; add t2, t2, t1 ; flw fs2, 0(t2)
    la t2, mass_grid ; add t2, t2, t1 ; flw fs3, 0(t2)

    slli t0, s0, 2

    la t2, node_is_leaf ; add t2, t2, t0 ; lw t3, 0(t2)
    beqz t3, not_leaf

is_leaf:
    la t2, node_particle ; add t2, t2, t0 ; lw s2, 0(t2)
    li t4, -1
    bne s2, t4, subdivide

empty_leaf:
    la t2, node_particle ; add t2, t2, t0 ; sw s1, 0(t2)
    la t2, node_mass ; add t2, t2, t0 ; fsw fs3, 0(t2)
    la t2, node_com_x ; add t2, t2, t0 ; fsw fs0, 0(t2)
    la t2, node_com_y ; add t2, t2, t0 ; fsw fs1, 0(t2)
    la t2, node_com_z ; add t2, t2, t0 ; fsw fs2, 0(t2)
    j insert_done

subdivide:
    la t2, node_is_leaf ; add t2, t2, t0 ; sw zero, 0(t2)
    li t4, -1
    la t2, node_particle ; add t2, t2, t0 ; sw t4, 0(t2)

    slli t5, s2, 2
    la t2, p_x ; add t2, t2, t5 ; flw fa0, 0(t2)
    la t2, p_y ; add t2, t2, t5 ; flw fa1, 0(t2)
    la t2, p_z ; add t2, t2, t5 ; flw fa2, 0(t2)
    
    mv a0, s0
    call get_octant
    mv a1, a0       
    mv a0, s0       
    call create_child
    
    mv a1, s2       
    call insert_particle 

not_leaf:
    mv a0, s0
    fmv.s fa0, fs0 ; fmv.s fa1, fs1 ; fmv.s fa2, fs2
    call get_octant
    mv t6, a0       

    slli t0, s0, 5  
    slli t1, t6, 2  
    add t2, t0, t1
    la t3, node_child ; add t3, t3, t2 ; lw a0, 0(t3) 

    li t4, -1
    bne a0, t4, traverse_insert

    mv a0, s0
    mv a1, t6
    call create_child 

traverse_insert:
    mv a1, s1       
    call insert_particle 

    slli t0, s0, 2
    la t2, node_mass ; add t2, t2, t0 ; flw ft0, 0(t2) 
    fadd.s ft1, ft0, fs3 
    fsw ft1, 0(t2) 

    la t2, node_com_x ; add t2, t2, t0 ; flw ft2, 0(t2)
    fmul.s ft3, ft2, ft0 ; fmul.s ft4, fs0, fs3 ; fadd.s ft5, ft3, ft4 ; fdiv.s ft6, ft5, ft1 ; fsw ft6, 0(t2)

    la t2, node_com_y ; add t2, t2, t0 ; flw ft2, 0(t2)
    fmul.s ft3, ft2, ft0 ; fmul.s ft4, fs1, fs3 ; fadd.s ft5, ft3, ft4 ; fdiv.s ft6, ft5, ft1 ; fsw ft6, 0(t2)

    la t2, node_com_z ; add t2, t2, t0 ; flw ft2, 0(t2)
    fmul.s ft3, ft2, ft0 ; fmul.s ft4, fs2, fs3 ; fadd.s ft5, ft3, ft4 ; fdiv.s ft6, ft5, ft1 ; fsw ft6, 0(t2)

insert_done:
    ld ra, 0(sp) ; ld s0, 8(sp) ; ld s1, 16(sp) ; ld s2, 24(sp)
    flw fs0, 32(sp) ; flw fs1, 36(sp) ; flw fs2, 40(sp) ; flw fs3, 44(sp)
    addi sp, sp, 64
    ret

# --- build_tree ---
# Iterates over all N particles and constructs the octree
build_tree:
    addi sp, sp, -32
    sd ra, 0(sp)
    sd s0, 8(sp)
    sd s1, 16(sp)

    call reset_pool

    # Allocate Root Node (0, 0, 0) with root_size
    fmv.w.x fa0, zero
    fmv.w.x fa1, zero
    fmv.w.x fa2, zero
    la t0, root_size
    flw fa3, 0(t0)
    call allocate_node
    # a0 = 0 (root node index)

    li s0, 0          # Particle index i
    li s1, N          # Limit N

build_tree_loop:
    bge s0, s1, build_tree_done
    
    li a0, 0          # Root node index is always 0
    mv a1, s0         # Pass current particle index
    call insert_particle
    
    addi s0, s0, 1
    j build_tree_loop

build_tree_done:
    ld ra, 0(sp)
    ld s0, 8(sp)
    ld s1, 16(sp)
    addi sp, sp, 32
    ret
