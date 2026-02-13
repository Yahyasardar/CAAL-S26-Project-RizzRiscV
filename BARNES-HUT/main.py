# src/main.py
import csv
import os
from body import Body
import physics
from GUI import draw_gui

def load_initial_conditions(file_path):
    """
    Loads mass, position, and velocity data from the provided CSV files.
    
    """
    bodies = []
    # Using the standard csv module for compatibility
    with open(file_path, mode='r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            b = Body(
                mass=row['mass'],
                x=row['distanceX'],
                y=row['distanceY'],
                z=row['distanceZ'],
                vx=row['velocityX'],
                vy=row['velocityY'],
                vz=row['velocityZ']
            )
            bodies.append(b)
    return bodies

def main():
    # --- 1. Simulation Constants ---
    # Adjust G and epsilon based on the specific scale of your data files
    G = 6.67430e-11 
    epsilon = 1e9    # Softening parameter [cite: 69]
    dt = 10000       # Timestep size
    
    # --- 2. Load Data ---
    # Path to one of your downloaded CSV files
    # Gets the directory where main.py is located (source/)
    current_dir = os.path.dirname(os.path.abspath(__file__))

# Moves up one level to the project root, then into the data folder
# Change this in your load_initial_conditions call
    data_file = os.path.join(current_dir, "data", "solar300.csv") 

    bodies = load_initial_conditions(data_file)
    
    # --- 3. Initialize GUI Position Lists ---
    # The GUI requires separate lists for x, y, and z
    p_x = [b.x for b in bodies]
    p_y = [b.y for b in bodies]
    p_z = [b.z for b in bodies]

    # Pre-calculate initial forces to have starting accelerations for the first 'Kick'
    physics.calculate_forces(bodies, G, epsilon)

    print(f"Starting simulation with {len(bodies)} bodies...")

    # --- 4. Main Simulation Loop ---
    # The loop runs as long as the GUI window is open [cite: 77, 80]
    while draw_gui(p_x, p_y, p_z):
        
        # Step 1: Kick (half-step velocity) [cite: 73, 79]
        physics.kick_half_step(bodies, dt)
        
        # Step 2: Drift (full-step position) [cite: 74, 79]
        physics.drift(bodies, dt)
        
        # Step 3: Calculate new forces and accelerations [cite: 75, 79]
        physics.calculate_forces(bodies, G, epsilon)
        
        # Step 4: Kick (remaining half-step velocity) [cite: 76, 80]
        physics.kick_half_step(bodies, dt)
        
        # --- 5. Sync Data with GUI ---
        # Update the lists used by draw_gui() so the visualization moves
        for i in range(len(bodies)):
            p_x[i] = bodies[i].x
            p_y[i] = bodies[i].y
            p_z[i] = bodies[i].z

if __name__ == "__main__":
    main()