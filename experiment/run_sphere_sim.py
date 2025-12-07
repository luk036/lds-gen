#!/usr/bin/env python3
"""
Python script to verify Sphere SystemVerilog implementation
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

def sphere_sequence(k: int, base_0: int, base_1: int) -> list:
    """Generate Sphere sequence point for given k and bases"""
    cosphi = 2.0 * vdc(k, base_0) - 1.0  # map to [-1, 1]
    sinphi = math.sqrt(1.0 - cosphi * cosphi)  # cylindrical mapping
    [c, s] = circle_sequence(k, base_1)
    return [sinphi * c, sinphi * s, cosphi]

def generate_sphere_reference():
    """Generate reference values for Sphere sequence bases [2,3], [2,7], [3,7]"""
    base_pairs = [(2, 3), (2, 7), (3, 7)]
    
    print("Sphere Sequence Reference Values")
    print("=" * 50)
    
    for base_0, base_1 in base_pairs:
        print(f"\nBases [{base_0},{base_1}] Sphere sequence (first 5 points):")
        for i in range(1, 6):
            point = sphere_sequence(i, base_0, base_1)
            print(f"k={i:2d}: [{point[0]:10.6f}, {point[1]:10.6f}, {point[2]:10.6f}]")
    
    print("\n" + "=" * 50)
    print("Verification against SystemVerilog output:")
    print("=" * 50)
    
    # Test values from simulation (bases [2,3])
    # Convert from Q32 fixed point to float (handle signed values)
    sim_values_raw = [
        [1, 1, 4294955008],      # k=1 (z is negative)
        [1, 1, 43008],          # k=2 (z is small positive)
        [1, 0, 4294902784],     # k=3 (z is negative)
        [1, 0, 21504],          # k=4 (z is small positive)
        [1, 1, 4294945792],     # k=5 (z is negative)
    ]
    
    print("\nComparing simulation results (bases [2,3]):")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point (handle signed values)
        sim_float = []
        for val in sim_raw:
            if val >= 2147483648:  # Negative value in two's complement
                sim_float.append((val - 4294967296) / 2147483648.0)
            else:
                sim_float.append(val / 2147483648.0)
        
        expected = sphere_sequence(k, 2, 3)
        
        # Calculate error
        error_x = abs(sim_float[0] - expected[0])
        error_y = abs(sim_float[1] - expected[1])
        error_z = abs(sim_float[2] - expected[2])
        
        print(f"k={k}: Sim=[{sim_float[0]:10.6f}, {sim_float[1]:10.6f}, {sim_float[2]:10.6f}] "
              f"Exp=[{expected[0]:10.6f}, {expected[1]:10.6f}, {expected[2]:10.6f}] "
              f"Err=[{error_x:.6f}, {error_y:.6f}, {error_z:.6f}]")
        
        # Check if within reasonable tolerance (coarse approximation)
        if error_x < 0.5 and error_y < 0.5 and error_z < 0.5:
            print("  Status: PASS (within tolerance)")
        else:
            print("  Status: FAIL (outside tolerance)")
    
    # Test reseed functionality
    print("\nReseed test (k=6 after reseed to 5):")
    sim_reseed_raw = [0, 0, 31744]
    sim_reseed_float = []
    for val in sim_reseed_raw:
        if val >= 2147483648:  # Negative value in two's complement
            sim_reseed_float.append((val - 4294967296) / 2147483648.0)
        else:
            sim_reseed_float.append(val / 2147483648.0)
    
    expected_reseed = sphere_sequence(6, 2, 3)
    
    error_x = abs(sim_reseed_float[0] - expected_reseed[0])
    error_y = abs(sim_reseed_float[1] - expected_reseed[1])
    error_z = abs(sim_reseed_float[2] - expected_reseed[2])
    
    print(f"Sim=[{sim_reseed_float[0]:10.6f}, {sim_reseed_float[1]:10.6f}, {sim_reseed_float[2]:10.6f}] "
          f"Exp=[{expected_reseed[0]:10.6f}, {expected_reseed[1]:10.6f}, {expected_reseed[2]:10.6f}] "
          f"Err=[{error_x:.6f}, {error_y:.6f}, {error_z:.6f}]")
    
    if error_x < 0.5 and error_y < 0.5 and error_z < 0.5:
        print("  Status: PASS (within tolerance)")
    else:
        print("  Status: FAIL (outside tolerance)")
    
    # Check if points are on unit sphere
    print("\nUnit sphere validation:")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point (handle signed values)
        sim_float = []
        for val in sim_raw:
            if val >= 2147483648:  # Negative value in two's complement
                sim_float.append((val - 4294967296) / 2147483648.0)
            else:
                sim_float.append(val / 2147483648.0)
        
        radius_sq = sim_float[0]**2 + sim_float[1]**2 + sim_float[2]**2
        
        if 0.8 <= radius_sq <= 1.2:
            print(f"k={k}: r²={radius_sq:.6f} - ON unit sphere")
        else:
            print(f"k={k}: r²={radius_sq:.6f} - OFF unit sphere")

if __name__ == "__main__":
    generate_sphere_reference()