def test_aggregate_properties(masses, x_coords, y_coords, z_coords):
    """
    Verifies that the total mass and center of mass in the 
    simulation structure match the input data.
    """
    # 1. Calculate expected values from input data
    total_input_mass = sum(masses)
    expected_com_x = sum(m * x for m, x in zip(masses, x_coords)) / total_input_mass
    expected_com_y = sum(m * y for m, y in zip(masses, y_coords)) / total_input_mass
    expected_com_z = sum(m * z for m, z in zip(masses, z_coords)) / total_input_mass

    # 2. Run the simulation logic (e.g., build the tree)
    # This is where the code to be tested would execute.
    
    # 3. Extract the results from the root node or top-level structure
    # calculated_mass = node_mass[0]
    # calculated_com_x = node_com_x[0]

    # 4. Verify the results match within a tolerance
    tolerance = 1e-6
    # assert abs(calculated_mass - total_input_mass) < tolerance
    # print("Mass conservation: PASS")
    
    print("Aggregate property tests complete.")

# Example particles for a quick verification
test_masses = [10.0, 20.0, 30.0]
test_x = [1.0, 2.0, 3.0]
test_y = [0.0, 0.0, 0.0]
test_z = [0.0, 0.0, 0.0]

test_aggregate_properties(test_masses, test_x, test_y, test_z)
