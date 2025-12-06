#!/usr/bin/env python3
"""
Python script to verify Halton SystemVerilog implementation
This script generates reference values and compares them with the SystemVerilog output.
"""

def vdc_i(k: int, base: int, scale: int) -> int:
    """Python implementation of Van der Corput sequence (integer version)"""
    vdc = 0
    factor = base ** scale
    
    while k != 0:
        factor //= base
        remainder = k % base
        k //= base
        vdc += remainder * factor
    
    return vdc

def halton_sequence(k: int, bases: list, scales: list) -> list:
    """Generate Halton sequence point for given k"""
    return [vdc_i(k, bases[0], scales[0]), vdc_i(k, bases[1], scales[1])]

def generate_halton_reference():
    """Generate reference values for Halton sequence bases [2,3] with scales [11,7]"""
    bases = [2, 3]
    scales = [11, 7]
    
    print(f"Halton Sequence Reference Values (bases={bases}, scales={scales})")
    print("=" * 60)
    
    print("\nFirst 10 Halton sequence points:")
    for i in range(1, 11):
        point = halton_sequence(i, bases, scales)
        print(f"k={i:2d}: [{point[0]:6d}, {point[1]:6d}]")
    
    print("\nVerification against SystemVerilog output:")
    print("=" * 60)
    
    # Test values from simulation (latest run)
    sim_values = [
        [1024, 729],   # k=1
        [512, 243],    # k=2  
        [1536, 1701],  # k=3
        [256, 1215],   # k=4
        [1280, 81],    # k=5
    ]
    
    print("\nComparing simulation results:")
    for i, sim_val in enumerate(sim_values):
        k = i + 1
        expected = halton_sequence(k, bases, scales)
        match = (sim_val[0] == expected[0] and sim_val[1] == expected[1])
        status = "PASS" if match else "FAIL"
        print(f"k={k}: Sim=[{sim_val[0]:6d}, {sim_val[1]:6d}] Exp=[{expected[0]:6d}, {expected[1]:6d}] {status}")
    
    # Test reseed functionality
    print(f"\nReseed test (k=6 after reseed to 5):")
    expected_reseed = halton_sequence(6, bases, scales)
    sim_reseed = [768, 1539]  # From simulation
    match_reseed = (sim_reseed[0] == expected_reseed[0] and sim_reseed[1] == expected_reseed[1])
    status_reseed = "PASS" if match_reseed else "FAIL"
    print(f"Sim=[{sim_reseed[0]:6d}, {sim_reseed[1]:6d}] Exp=[{expected_reseed[0]:6d}, {expected_reseed[1]:6d}] {status_reseed}")

if __name__ == "__main__":
    generate_halton_reference()