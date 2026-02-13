import math

def calculate_force(body, node, G, theta, epsilon):
    """
    Replaces Naive O(N^2) double-loop with O(N log N) recursive tree traversal.
    """
    if node is None or node.mass == 0 or (node.is_leaf() and node.body == body):
        return

    dx = node.com_x - body.x
    dy = node.com_y - body.y
    dz = node.com_z - body.z
    dist = math.sqrt(dx**2 + dy**2 + dz**2 + epsilon**2)

    # Barnes-Hut Criterion: If node is far enough, treat it as a single point mass
    if node.is_leaf() or (node.size / dist) < theta:
        inv_dist3 = 1.0 / (dist ** 3)
        factor = G * node.mass * inv_dist3
        body.ax += dx * factor
        body.ay += dy * factor
        body.az += dz * factor
    else:
        # Otherwise, resolve internal details by traversing children
        for child in node.children:
            calculate_force(body, child, G, theta, epsilon)
