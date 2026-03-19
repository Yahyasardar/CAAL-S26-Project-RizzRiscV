# physics_refactored.py
# Flat-array physics engine for the N-body simulation
# Replaces the Body class from milestone 1 with indexed arrays
# All functions take N (number of bodies) and separate arrays for each quantity

import math

def calculate_forces(N, pos_x, pos_y, pos_z, mass, acc_x, acc_y, acc_z, G, epsilon):
    # Reset all accelerations to zero before recalculating
    for i in range(N):
        acc_x[i] = 0.0
        acc_y[i] = 0.0
        acc_z[i] = 0.0

    # Loop over all unique pairs (i, j) -- O(N^2) naive implementation
    for i in range(N):
        for j in range(i + 1, N):

            # Displacement vector from body i to body j
            dx = pos_x[j] - pos_x[i]
            dy = pos_y[j] - pos_y[i]
            dz = pos_z[j] - pos_z[i]

            # Softened distance: eps prevents singularity when bodies get too close
            r_sq = dx*dx + dy*dy + dz*dz
            dist_soft = math.sqrt(r_sq + epsilon*epsilon)
            inv_dist_cube = 1.0 / (dist_soft**3)

            # Gravitational force factor: G / dist^3
            f = G * inv_dist_cube

            # Accumulate acceleration on body i due to body j
            acc_x[i] += mass[j] * dx * f
            acc_y[i] += mass[j] * dy * f
            acc_z[i] += mass[j] * dz * f

            # Apply equal and opposite force on body j (Newton's 3rd law)
            acc_x[j] -= mass[i] * dx * f
            acc_y[j] -= mass[i] * dy * f
            acc_z[j] -= mass[i] * dz * f


def kick_half_step(N, vel_x, vel_y, vel_z, acc_x, acc_y, acc_z, dt):
    # Leapfrog KICK: update velocities by half a timestep
    # Called twice per iteration -- once before drift, once after new forces
    dt_half = 0.5 * dt
    for i in range(N):
        vel_x[i] += acc_x[i] * dt_half
        vel_y[i] += acc_y[i] * dt_half
        vel_z[i] += acc_z[i] * dt_half


def drift(N, pos_x, pos_y, pos_z, vel_x, vel_y, vel_z, dt):
    # Leapfrog DRIFT: update positions by a full timestep using current velocities
    for i in range(N):
        pos_x[i] += vel_x[i] * dt
        pos_y[i] += vel_y[i] * dt
        pos_z[i] += vel_z[i] * dt
