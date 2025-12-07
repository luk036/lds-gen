#!/usr/bin/env python3
"""
Verification script for Sphere3 SystemVerilog implementation
Compares SystemVerilog output with Python reference implementation
"""

import sys
sys.path.append('../src')

from lds_gen.sphere_n import Sphere3
import subprocess
import re
import numpy as np

def python_sphere3(base, seed=0, count=10):
    """Generate Sphere3 sequence using Python reference implementation"""
    sgen = Sphere3(base)
    sgen.reseed(seed)
    points = []
    for _ in range(count):
        points.append(sgen.pop())
    return points

def run_systemverilog_simulation(base, count=10):
    """Run SystemVerilog simulation and extract output"""
    # Convert base tuple to string for filename
    base_str = "_".join(map(str, base))
    
    # Run simulation
    cmd = "vvp sphere3_32bit_sim"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=".")
    
    if result.returncode != 0:
        print(f"Simulation failed: {result.stderr}")
        return None
    
    # Extract points from output
    points = []
    pattern = r"Point \d+: \[([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\]"
    matches = re.findall(pattern, result.stdout)
    
    for match in matches[:count]:
        point = [float(x) for x in match]
        points.append(point)
    
    return points

def main():
    print("=== Sphere3 SystemVerilog Verification ===")
    
    # Test parameters
    bases = [[2, 3, 7], [2, 7, 3], [3, 2, 7]]
    seed = 0
    count = 5
    
    for base in bases:
        print(f"\n--- Testing bases {base} ---")
        
        # Generate Python reference
        py_points = python_sphere3(base, seed, count)
        print("Python reference:")
        for i, point in enumerate(py_points):
            print(f"  Point {i+1}: {point}")
        
        # Run SystemVerilog simulation
        print("\nSystemVerilog output:")
        sv_points = run_systemverilog_simulation(base, count)
        if sv_points:
            for i, point in enumerate(sv_points):
                print(f"  Point {i+1}: {point}")
            
            # Compare results (allowing for some tolerance due to fixed-point arithmetic)
            print("\nComparison:")
            for i, (py, sv) in enumerate(zip(py_points, sv_points)):
                diff = np.array(py) - np.array(sv)
                max_diff = np.max(np.abs(diff))
                if max_diff < 0.1:  # Allow 10% tolerance
                    status = "PASS"
                else:
                    status = "FAIL"
                print(f"  Point {i+1}: max_diff={max_diff:.6f} {status}")

if __name__ == "__main__":
    main()