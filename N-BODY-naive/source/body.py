# src/body.py

class Body:
    """
    Represents a single particle in the N-body simulation.
    Stores physical state: mass, position, velocity, and acceleration.
    """
    def __init__(self, mass, x, y, z, vx, vy, vz):
        # 1. Mass attribute 
        self.mass = float(mass)
        
        # 2. Position vectors (x, y, z) 
        self.x = float(x)
        self.y = float(y)
        self.z = float(z)
        
        # 3. Velocity vectors (vx, vy, vz) 
        self.vx = float(vx)
        self.vy = float(vy)
        self.vz = float(vz)
        
        # 4. Acceleration vectors (ax, ay, az) 
        # Initialized to zero; updated during each force calculation step.
        self.ax = 0.0
        self.ay = 0.0
        self.az = 0.0

    def update_position(self, dt):
        """
        Leapfrog 'Drift' step[cite: 74]: Updates position using current velocity.
        Formula: r = r + v * dt [cite: 57]
        """
        self.x += self.vx * dt
        self.y += self.vy * dt
        self.z += self.vz * dt

    def update_velocity(self, dt_half):
        """
        Leapfrog 'Kick' step[cite: 73]: Updates velocity using current acceleration.
        Formula: v = v + a * (dt/2) [cite: 54]
        Note: This is used for both the initial and final half-kicks.
        """
        self.vx += self.ax * dt_half
        self.vy += self.ay * dt_half
        self.vz += self.az * dt_half

    def reset_acceleration(self):
        """
        Clears previous acceleration before a new force calculation round.
        """
        self.ax = 0.0
        self.ay = 0.0
        self.az = 0.0