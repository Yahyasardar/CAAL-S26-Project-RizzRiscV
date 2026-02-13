# src/main.py
import csv
import os
from body import Body
from GUI import draw_gui
from octree import OctreeNode
from bh_physics import calculate_force
import physics

script_dir = os.path.dirname(os.path.abspath(__file__))
data_path = os.path.join(script_dir, "data", "stable_random_system500.csv")

def load_initial_conditions(file_path):
    bodies = []
    with open(file_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            bodies.append(
                Body(
                    row['mass'],
                    row['distanceX'],
                    row['distanceY'],
                    row['distanceZ'],
                    row['velocityX'],
                    row['velocityY'],
                    row['velocityZ']
                )
            )
    return bodies


def main():
    G = 6.67430e-11
    epsilon = 1e9
    dt = 10000
    theta = 0.7

    bodies = load_initial_conditions(data_path)

    px = [b.x for b in bodies]
    py = [b.y for b in bodies]
    pz = [b.z for b in bodies]

    physics.calculate_forces(bodies, G, epsilon)

    while draw_gui(px, py, pz):

        physics.kick_half_step(bodies, dt)
        physics.drift(bodies, dt)

        # --- Barnes–Hut Force Calculation ---
        for b in bodies:
            b.ax = b.ay = b.az = 0.0

        # DYNAMIC BOUNDING BOX (CRITICAL FIX)
        all_x = [b.x for b in bodies]
        all_y = [b.y for b in bodies]
        all_z = [b.z for b in bodies]
        
        min_x, max_x = min(all_x), max(all_x)
        min_y, max_y = min(all_y), max(all_y)
        min_z, max_z = min(all_z), max(all_z)
        
        center = ((min_x + max_x)/2, (min_y + max_y)/2, (min_z + max_z)/2)
        # Size should be the largest dimension to keep the octree cubic
        size = max(max_x - min_x, max_y - min_y, max_z - min_z) * 1.1 # 10% padding

        root = OctreeNode(center=(0, 0, 0), size=1e13)
        for b in bodies:
            root.insert(b)

        for b in bodies:
            calculate_force(b, root, G, theta, epsilon)

        physics.kick_half_step(bodies, dt)

        for i, b in enumerate(bodies):
            px[i] = b.x
            py[i] = b.y
            pz[i] = b.z


if __name__ == "__main__":
    main()
