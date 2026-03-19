# main_refactored.py
# Runs the N-body simulation using flat arrays (no Body class)
# Two modes:
#   python3 main_refactored.py            -> Python physics mode
#   python3 main_refactored.py assembly   -> reads from assembly via mmap

import csv
import os
import sys
import mmap
import struct
import math
import time
import physics_refactored as physics
from GUI import draw_gui, _gui_state

# Simulation constants
G       = 6.67430e-11
epsilon = 1e9
dt      = 1000

# mmap settings -- must match nbody.S values
N         = 300
MMAP_FILE = "shared.mem"
FILE_SIZE = 8 + N * 8 * 3
FLAG_OFF  = 0
PX_OFF    = 8
PY_OFF    = 8 + N * 8
PZ_OFF    = 8 + N * 8 * 2


def load_initial_conditions(file_path):
    # Count rows first so arrays are fixed size (no append)
    with open(file_path, mode='r') as f:
        N = sum(1 for _ in csv.DictReader(f))

    mass  = [0.0] * N
    pos_x = [0.0] * N
    pos_y = [0.0] * N
    pos_z = [0.0] * N
    vel_x = [0.0] * N
    vel_y = [0.0] * N
    vel_z = [0.0] * N
    acc_x = [0.0] * N
    acc_y = [0.0] * N
    acc_z = [0.0] * N

    with open(file_path, mode='r') as f:
        for i, row in enumerate(csv.DictReader(f)):
            mass[i]  = float(row['mass'])
            pos_x[i] = float(row['distanceX'])
            pos_y[i] = float(row['distanceY'])
            pos_z[i] = float(row['distanceZ'])
            vel_x[i] = float(row['velocityX'])
            vel_y[i] = float(row['velocityY'])
            vel_z[i] = float(row['velocityZ'])

    return N, mass, pos_x, pos_y, pos_z, vel_x, vel_y, vel_z, acc_x, acc_y, acc_z


def read_from_mmap(mm):
    # Wait for flag=0 then double check after read to ensure clean data
    for _ in range(2000):
        mm.seek(FLAG_OFF)
        if struct.unpack('q', mm.read(8))[0] != 0:
            time.sleep(0.001)
            continue

        mm.seek(PX_OFF); raw_x = mm.read(N * 8)
        mm.seek(PY_OFF); raw_y = mm.read(N * 8)
        mm.seek(PZ_OFF); raw_z = mm.read(N * 8)

        mm.seek(FLAG_OFF)
        if struct.unpack('q', mm.read(8))[0] != 0:
            time.sleep(0.001)
            continue

        nx = list(struct.unpack(f'{N}d', raw_x))
        ny = list(struct.unpack(f'{N}d', raw_y))
        nz = list(struct.unpack(f'{N}d', raw_z))

        if all(math.isfinite(v) for v in nx[:5]):
            return nx, ny, nz

    return None, None, None


def run_python_mode():
    # Pure Python simulation using flat array physics
    current_dir = os.path.dirname(os.path.abspath(__file__))
    data_file   = os.path.join(current_dir, "data", "solar300.csv")

    N, mass, pos_x, pos_y, pos_z, \
    vel_x, vel_y, vel_z, \
    acc_x, acc_y, acc_z = load_initial_conditions(data_file)

    print(f"Loaded {N} bodies. Running Python simulation...")

    physics.calculate_forces(N, pos_x, pos_y, pos_z, mass,
                             acc_x, acc_y, acc_z, G, epsilon)

    while draw_gui(pos_x, pos_y, pos_z):
        physics.kick_half_step(N, vel_x, vel_y, vel_z, acc_x, acc_y, acc_z, dt)
        physics.drift(N, pos_x, pos_y, pos_z, vel_x, vel_y, vel_z, dt)
        physics.calculate_forces(N, pos_x, pos_y, pos_z, mass,
                                 acc_x, acc_y, acc_z, G, epsilon)
        physics.kick_half_step(N, vel_x, vel_y, vel_z, acc_x, acc_y, acc_z, dt)


def run_assembly_mode():
    # Read positions from assembly simulation via shared memory file
    print("Waiting for assembly simulation to start...")

    while not os.path.exists(MMAP_FILE):
        time.sleep(0.5)

    with open(MMAP_FILE, 'r+b') as f:
        mm = mmap.mmap(f.fileno(), FILE_SIZE)

    # Wait for the first valid frame BEFORE opening GUI
    print("Waiting for first frame from assembly...")
    pos_x, pos_y, pos_z = None, None, None
    while pos_x is None:
        pos_x, pos_y, pos_z = read_from_mmap(mm)
        time.sleep(0.1)

    print("Got first frame. Opening GUI...")

    while draw_gui(pos_x, pos_y, pos_z):
        nx, ny, nz = read_from_mmap(mm)
        if nx is not None:
            pos_x = nx
            pos_y = ny
            pos_z = nz

    mm.close()


def main():
    if len(sys.argv) > 1 and sys.argv[1] == 'assembly':
        run_assembly_mode()
    else:
        run_python_mode()


if __name__ == "__main__":
    main()
