#!/usr/bin/env python3
"""
Python script to verify Disk SystemVerilog implementation
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

def disk_sequence(k: int, base_0: int, base_1: int) -> list:
    """Generate Disk sequence point for given k and bases"""
    theta = vdc(k, base_0) * 2 * math.pi
    radius = math.sqrt(vdc(k, base_1))
    return [radius * math.cos(theta), radius * math.sin(theta)]

def generate_disk_reference():
    """Generate reference values for Disk sequence bases [2,3], [2,7], [3,7]"""
    base_pairs = [(2, 3), (2, 7), (3, 7)]
    
    print(f"Disk Sequence Reference Values")
    print("=" * 50)
    
    for base_0, base_1 in base_pairs:
        print(f"\nBases [{base_0},{base_1}] Disk sequence (first 5 points):")
        for i in range(1, 6):
            point = disk_sequence(i, base_0, base_1)
            print(f"k={i:2d}: [{point[0]:10.6f}, {point[1]:10.6f}]")
    
    print("\n" + "=" * 50)
    print("Verification against SystemVerilog output:")
    print("=" * 50)
    
    # Test values from simulation (bases [2,3])
    # Convert from Q32 fixed point to float
    sim_values_raw = [
        [0, 0],          # k=1
        [0, 2147483648], # k=2
        [2147483648, 0], # k=3
        [2147483648, 0], # k=4
        [2147483648, 0], # k=5
    ]
    
    print(f"\nComparing simulation results (bases [2,3]):")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point
        sim_float = [sim_raw[0] / 2147483648.0, sim_raw[1] / 2147483648.0]
        expected = disk_sequence(k, 2, 3)
        
        # Calculate error
        error_x = abs(sim_float[0] - expected[0])
        error_y = abs(sim_float[1] - expected[1])
        
        print(f"k={k}: Sim=[{sim_float[0]:10.6f}, {sim_float[1]:10.6f}] "
              f"Exp=[{expected[0]:10.6f}, {expected[1]:10.6f}] "
              f"Err=[{error_x:.6f}, {error_y:.6f}]")
        
        # Check if within reasonable tolerance (coarse approximation)
        if error_x < 0.5 and error_y < 0.5:
            print(f"  Status: PASS (within tolerance)")
        else:
            print(f"  Status: FAIL (outside tolerance)")
    
    # Test reseed functionality
    print(f"\nReseed test (k=6 after reseed to 5):")
    sim_reseed_raw = [0, 0]
    sim_reseed_float = [sim_reseed_raw[0] / 2147483648.0, sim_reseed_raw[1] / 2147483648.0]
    expected_reseed = disk_sequence(6, 2, 3)
    
    error_x = abs(sim_reseed_float[0] - expected_reseed[0])
    error_y = abs(sim_reseed_float[1] - expected_reseed[1])
    
    print(f"Sim=[{sim_reseed_float[0]:10.6f}, {sim_reseed_float[1]:10.6f}] "
          f"Exp=[{expected_reseed[0]:10.6f}, {expected_reseed[1]:10.6f}] "
          f"Err=[{error_x:.6f}, {error_y:.6f}]")
    
    if error_x < 0.5 and error_y < 0.5:
        print(f"  Status: PASS (within tolerance)")
    else:
        print(f"  Status: FAIL (outside tolerance)")
    
    # Check if points are within unit disk
    print(f"\nUnit disk validation:")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        sim_float = [sim_raw[0] / 2147483648.0, sim_raw[1] / 2147483648.0]
        radius_sq = sim_float[0]**2 + sim_float[1]**2
        
        if radius_sq <= 1.0:
            print(f"k={k}: r²={radius_sq:.6f} - INSIDE unit disk")
        else:
            print(f"k={k}: r²={radius_sq:.6f} - OUTSIDE unit disk")

if __name__ == "__main__":
    generate_disk_reference()