# Array-based Octree for Barnes-Hut (Milestone 3)
MAX_NODES = 8 * 300 + 100 

# Pre-allocated Node Pool
node_cx = [0.0] * MAX_NODES
node_cy = [0.0] * MAX_NODES
node_cz = [0.0] * MAX_NODES
node_size = [0.0] * MAX_NODES
node_mass = [0.0] * MAX_NODES
node_com_x = [0.0] * MAX_NODES
node_com_y = [0.0] * MAX_NODES
node_com_z = [0.0] * MAX_NODES
node_child = [-1] * (MAX_NODES * 8)
node_particle = [-1] * MAX_NODES
node_is_leaf = [1] * MAX_NODES
node_count = [0] 

def reset_pool():
    node_count[0] = 0

def allocate_node(cx, cy, cz, size):
    idx = node_count[0]
    node_count[0] += 1
    node_cx[idx], node_cy[idx], node_cz[idx], node_size[idx] = cx, cy, cz, size
    node_mass[idx] = 0.0
    node_particle[idx], node_is_leaf[idx] = -1, 1
    for k in range(8):
        node_child[idx * 8 + k] = -1
    return idx

def get_octant(idx, px, py, pz):
    k = 0
    if px > node_cx[idx]: k |= 1
    if py > node_cy[idx]: k |= 2
    if pz > node_cz[idx]: k |= 4
    return k

def create_child(idx, k):
    offset = node_size[idx] / 2.0
    dx = offset if (k & 1) else -offset
    dy = offset if (k & 2) else -offset
    dz = offset if (k & 4) else -offset
    child_idx = allocate_node(node_cx[idx] + dx, node_cy[idx] + dy, node_cz[idx] + dz, offset)
    node_child[idx * 8 + k] = child_idx
    return child_idx

def insert_particle(node_idx, p_idx, p_x, p_y, p_z, p_mass):
    # 1. Empty leaf
    if node_is_leaf[node_idx] == 1 and node_particle[node_idx] == -1:
        node_particle[node_idx] = p_idx
        node_mass[node_idx], node_com_x[node_idx] = p_mass[p_idx], p_x[p_idx]
        node_com_y[node_idx], node_com_z[node_idx] = p_y[p_idx], p_z[p_idx]
        return

    # 2. Occupied leaf -> Subdivide
    if node_is_leaf[node_idx] == 1:
        existing_p = node_particle[node_idx]
        node_particle[node_idx], node_is_leaf[node_idx] = -1, 0
        k_old = get_octant(node_idx, p_x[existing_p], p_y[existing_p], p_z[existing_p])
        child_old = create_child(node_idx, k_old)
        insert_particle(child_old, existing_p, p_x, p_y, p_z, p_mass)

    # 3. Traverse down
    k_new = get_octant(node_idx, p_x[p_idx], p_y[p_idx], p_z[p_idx])
    child_new = node_child[node_idx * 8 + k_new]
    if child_new == -1:
        child_new = create_child(node_idx, k_new)
    
    insert_particle(child_new, p_idx, p_x, p_y, p_z, p_mass)
    
    # 4. Update Node Aggregate
    total_m = node_mass[node_idx] + p_mass[p_idx]
    node_com_x[node_idx] = (node_com_x[node_idx] * node_mass[node_idx] + p_x[p_idx] * p_mass[p_idx]) / total_m
    node_com_y[node_idx] = (node_com_y[node_idx] * node_mass[node_idx] + p_y[p_idx] * p_mass[p_idx]) / total_m
    node_com_z[node_idx] = (node_com_z[node_idx] * node_mass[node_idx] + p_z[p_idx] * p_mass[p_idx]) / total_m
    node_mass[node_idx] = total_m
