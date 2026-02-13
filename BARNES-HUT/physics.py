# src/physics.py
import math

def calculate_forces(bodies, G, epsilon):
    """
    Naive N-body force calculation as per Task 3[cite: 41, 66].
    Calculates forces between all pairs of bodies[cite: 67].
    """
    # Initialize/Reset all accelerations to zero [cite: 64, 71]
    for b in bodies:
        b.ax = 0.0
        b.ay = 0.0
        b.az = 0.0

    num_bodies = len(bodies)
    for i in range(num_bodies):
        b1 = bodies[i]
        for j in range(i + 1, num_bodies):
            b2 = bodies[j]

            # Calculate distance components (x2 - x1) [cite: 68]
            dx = b2.x - b1.x
            dy = b2.y - b1.y
            dz = b2.z - b1.z

            # Calculate distance squared 
            r_squared = dx**2 + dy**2 + dz**2
            
            # Apply softening: r_soft = sqrt(r^2 + eps^2) 
            # We use r_soft^3 in the denominator to find acceleration directly
            dist_soft = math.sqrt(r_squared + epsilon**2)
            inv_dist_cube = 1.0 / (dist_soft**3)

            # Calculate Force: F = G * m1 * m2 / r_soft^3 [cite: 70]
            # Since a = F/m, we can skip the mass of the body being accelerated
            # Accel_on_1 = (G * m2 * vector_dist) / r_soft^3 
            f_common = G * inv_dist_cube
            
            # Update accelerations for body 1 
            b1.ax += b2.mass * dx * f_common
            b1.ay += b2.mass * dy * f_common
            b1.az += b2.mass * dz * f_common

            # Update accelerations for body 2 (Equal and opposite) 
            b2.ax -= b1.mass * dx * f_common
            b2.ay -= b1.mass * dy * f_common
            b2.az -= b1.mass * dz * f_common

def kick_half_step(bodies, dt):
    """
    Step 1 & 4: Update velocities by half timestep using current accelerations[cite: 73, 76].
    Formula: v = v + a * (0.5 * dt)[cite: 54, 61].
    """
    dt_half = 0.5 * dt
    for b in bodies:
        b.vx += b.ax * dt_half
        b.vy += b.ay * dt_half
        b.vz += b.az * dt_half

def drift(bodies, dt):
    """
    Step 2: Update positions using the half-stepped velocities[cite: 74].
    Formula: r = r + v * dt[cite: 57].
    """
    for b in bodies:
        b.x += b.vx * dt
        b.y += b.vy * dt
        b.z += b.vz * dt