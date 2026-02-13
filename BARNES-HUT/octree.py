class OctreeNode:
    def __init__(self, center, size):
        self.cx, self.cy, self.cz = center
        self.size = size # Half-width of the spatial bounding box

        # Hierarchical mass properties used for multipole approximation
        self.mass = 0.0
        self.com_x = self.com_y = self.com_z = 0.0

        self.body = None
        self.children = [None] * 8

    def is_leaf(self):
        return all(child is None for child in self.children)

    def _octant_index(self, body):
        # Maps 3D position to one of 8 child indices using bitmasking
        idx = 0
        if body.x > self.cx: idx |= 1
        if body.y > self.cy: idx |= 2
        if body.z > self.cz: idx |= 4
        return idx

    def _create_child(self, idx):
        offset = self.size / 2
        dx = offset if idx & 1 else -offset
        dy = offset if idx & 2 else -offset
        dz = offset if idx & 4 else -offset

        self.children[idx] = OctreeNode(
            (self.cx + dx, self.cy + dy, self.cz + dz),
            offset
        )

    def insert(self, body):
        # If node is empty leaf, store body and stop
        if self.body is None and self.is_leaf():
            self.body = body
            self.mass, self.com_x, self.com_y, self.com_z = body.mass, body.x, body.y, body.z
            return

        # If occupied leaf, subdivide to maintain one body per leaf
        if self.is_leaf():
            existing = self.body
            self.body = None
            idx_old = self._octant_index(existing)
            self._create_child(idx_old)
            self.children[idx_old].insert(existing)

        # Recurse into appropriate octant
        idx_new = self._octant_index(body)
        if self.children[idx_new] is None:
            self._create_child(idx_new)
        self.children[idx_new].insert(body)

        # Update node's aggregate center of mass (essential for BH approximation)
        total_mass = self.mass + body.mass
        self.com_x = (self.com_x * self.mass + body.x * body.mass) / total_mass
        self.com_y = (self.com_y * self.mass + body.y * body.mass) / total_mass
        self.com_z = (self.com_z * self.mass + body.z * body.mass) / total_mass
        self.mass = total_mass
