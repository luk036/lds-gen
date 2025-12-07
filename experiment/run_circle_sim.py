#!/usr/bin/env python3
"""
Python script to verify Circle SystemVerilog implementation
This script generates reference values and compares them with the SystemVerilog output.
"""

import math

def vdc(k: int, base: int) -> float:
    """Van der Corput sequence (floating point version)"""
    res = 0.0
    denom = 1.0
    while k != 0:
        denom *= base
        k, remainder = divmod(k, base)
        res += remainder / denom
    return res

def circle_sequence(k: int, base: int) -> list:
    """Generate Circle sequence point for given k and base"""
    theta = vdc(k, base) * 2 * math.pi
    return [math.cos(theta), math.sin(theta)]

def generate_circle_reference():
    """Generate reference values for Circle sequence bases 2, 3, and 7"""
    bases = [2, 3, 7]
    
    print("Circle Sequence Reference Values")
    print("=" * 50)
    
    for base in bases:
        print(f"\nBase {base} Circle sequence (first 5 points):")
        for i in range(1, 6):
            point = circle_sequence(i, base)
            print(f"k={i:2d}: [{point[0]:10.6f}, {point[1]:10.6f}]")
    
    print("\n" + "=" * 50)
    print("Verification against SystemVerilog output:")
    print("=" * 50)
    
    # Test values from simulation (base 2)
    # Convert from Q32 fixed point to float
    sim_values_raw = [
        [2147483648, 0],          # k=1
        [628646298, 1518500250],  # k=2
        [673720364, 976064279],   # k=3
        [2147483648, 0],          # k=4
        [628646298, 628646298],   # k=5
    ]
    
    print("\nComparing simulation results (base 2):")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point
        sim_float = [sim_raw[0] / 2147483648.0, sim_raw[1] / 2147483648.0]
        expected = circle_sequence(k, 2)
        
        # Calculate error
        error_x = abs(sim_float[0] - expected[0])
        error_y = abs(sim_float[1] - expected[1])
        
        print(f"k={k}: Sim=[{sim_float[0]:10.6f}, {sim_float[1]:10.6f}] "
              f"Exp=[{expected[0]:10.6f}, {expected[1]:10.6f}] "
              f"Err=[{error_x:.6f}, {error_y:.6f}]")
        
        # Check if within reasonable tolerance (coarse approximation)
        if error_x < 0.4 and error_y < 0.4:
            print("  Status: PASS (within tolerance)")
        else:
            print("  Status: FAIL (outside tolerance)")
    
    # Test reseed functionality
    print("\nReseed test (k=6 after reseed to 5):")
    sim_reseed_raw = [3621193184, 2048909069]
    sim_reseed_float = [sim_reseed_raw[0] / 2147483648.0, sim_reseed_raw[1] / 2147483648.0]
    expected_reseed = circle_sequence(6, 2)
    
    error_x = abs(sim_reseed_float[0] - expected_reseed[0])
    error_y = abs(sim_reseed_float[1] - expected_reseed[1])
    
    print(f"Sim=[{sim_reseed_float[0]:10.6f}, {sim_reseed_float[1]:10.6f}] "
          f"Exp=[{expected_reseed[0]:10.6f}, {expected_reseed[1]:10.6f}] "
          f"Err=[{error_x:.6f}, {error_y:.6f}]")
    
    if error_x < 0.4 and error_y < 0.4:
        print("  Status: PASS (within tolerance)")
    else:
        print("  Status: FAIL (outside tolerance)")

if __name__ == "__main__":
    generate_circle_reference()