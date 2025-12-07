#!/usr/bin/env python3
"""
Python script to verify Van der Corput SystemVerilog implementation
This script generates reference values and compares them with the expected values
used in the testbenches.
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

def generate_reference_values():
    """Generate reference values for bases 2, 3, and 7"""
    scale = 10  # Using scale 10 for easy verification
    
    print(f"Van der Corput Reference Values (scale={scale})")
    print("=" * 50)
    
    print("\nBase 2:")
    for i in range(1, 11):
        val = vdc_i(i, 2, scale)
        print(f"k={i:2d}: {val}")
    
    print("\nBase 3:")
    for i in range(1, 11):
        val = vdc_i(i, 3, scale)
        print(f"k={i:2d}: {val}")
    
    print("\nBase 7:")
    for i in range(1, 11):
        val = vdc_i(i, 7, scale)
        print(f"k={i:2d}: {val}")
    
    # Test specific values mentioned in testbench
    print("\n" + "=" * 50)
    print("Testbench Verification Values:")
    print("=" * 50)
    
    # Test case: k=6 after reseed to 5
    k = 6
    print(f"\nAfter reseed to 5 (k={k}):")
    print(f"Base 2: {vdc_i(k, 2, scale)}")
    print(f"Base 3: {vdc_i(k, 3, scale)}")
    print(f"Base 7: {vdc_i(k, 7, scale)}")
    
    # Scale 8 values for multi-base test
    scale_8 = 8
    print("\nScale 8 values (for multi-base test):")
    for i in range(1, 11):
        val2 = vdc_i(i, 2, scale_8)
        val3 = vdc_i(i, 3, scale_8)
        val7 = vdc_i(i, 7, scale_8)
        print(f"k={i:2d}: Base2={val2:4d}, Base3={val3:4d}, Base7={val7:4d}")

if __name__ == "__main__":
    generate_reference_values()