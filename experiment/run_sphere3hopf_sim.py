#!/usr/bin/env python3
"""
Python script to verify Sphere3Hopf SystemVerilog implementation
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


def sphere3hopf_sequence(k: int, base_0: int, base_1: int, base_2: int) -> list:
    """Generate Sphere3Hopf sequence point for given k and bases"""
    phi = vdc(k, base_0) * 2 * math.pi
    psy = vdc(k, base_1) * 2 * math.pi
    vdc_val = vdc(k, base_2)
    cos_eta = math.sqrt(vdc_val)
    sin_eta = math.sqrt(1.0 - vdc_val)

    return [
        cos_eta * math.cos(psy),
        cos_eta * math.sin(psy),
        sin_eta * math.cos(phi + psy),
        sin_eta * math.sin(phi + psy),
    ]


def generate_sphere3hopf_reference():
    """Generate reference values for Sphere3Hopf sequence bases [2,3,7]"""
    base_triples = [(2, 3, 7), (2, 7, 3), (3, 2, 7)]

    print("Sphere3Hopf Sequence Reference Values")
    print("=" * 60)

    for base_0, base_1, base_2 in base_triples:
        print(
            f"\nBases [{base_0},{base_1},{base_2}] Sphere3Hopf sequence (first 5 points):"
        )
        for i in range(1, 6):
            point = sphere3hopf_sequence(i, base_0, base_1, base_2)
            print(
                f"k={i:2d}: [{point[0]:10.6f}, {point[1]:10.6f}, {point[2]:10.6f}, {point[3]:10.6f}]"
            )

    print("\n" + "=" * 60)
    print("Verification against SystemVerilog output:")
    print("=" * 60)

    # Test values from simulation (bases [2,3,7])
    # Convert from Q32 fixed point to float (handle signed values)
    sim_values_raw = [
        [0, 0, 0, 0],  # k=1
        [0, 0, 0, 0],  # k=2
        [0, 0, 0, 0],  # k=3
        [0, 0, 0, 0],  # k=4
        [0, 0, 0, 0],  # k=5
    ]

    print("\nComparing simulation results (bases [2,3,7]):")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point (handle signed values)
        sim_float = []
        for val in sim_raw:
            if val >= 2147483648:  # Negative value in two's complement
                sim_float.append((val - 4294967296) / 2147483648.0)
            else:
                sim_float.append(val / 2147483648.0)

        expected = sphere3hopf_sequence(k, 2, 3, 7)

        # Calculate error
        error_x = abs(sim_float[0] - expected[0])
        error_y = abs(sim_float[1] - expected[1])
        error_z = abs(sim_float[2] - expected[2])
        error_w = abs(sim_float[3] - expected[3])

        print(
            f"k={k}: Sim=[{sim_float[0]:10.6f}, {sim_float[1]:10.6f}, {sim_float[2]:10.6f}, {sim_float[3]:10.6f}]"
        )
        print(
            f"    Exp=[{expected[0]:10.6f}, {expected[1]:10.6f}, {expected[2]:10.6f}, {expected[3]:10.6f}]"
        )
        print(f"    Err=[{error_x:.6f}, {error_y:.6f}, {error_z:.6f}, {error_w:.6f}]")

        # Check if within reasonable tolerance
        if error_x < 0.5 and error_y < 0.5 and error_z < 0.5 and error_w < 0.5:
            print("    Status: PASS (within tolerance)")
        else:
            print("    Status: FAIL (outside tolerance)")

    # Test reseed functionality
    print("\nReseed test (k=6 after reseed to 5):")
    sim_reseed_raw = [0, 0, 0, 0]
    sim_reseed_float = []
    for val in sim_reseed_raw:
        if val >= 2147483648:  # Negative value in two's complement
            sim_reseed_float.append((val - 4294967296) / 2147483648.0)
        else:
            sim_reseed_float.append(val / 2147483648.0)

    expected_reseed = sphere3hopf_sequence(6, 2, 3, 7)

    error_x = abs(sim_reseed_float[0] - expected_reseed[0])
    error_y = abs(sim_reseed_float[1] - expected_reseed[1])
    error_z = abs(sim_reseed_float[2] - expected_reseed[2])
    error_w = abs(sim_reseed_float[3] - expected_reseed[3])

    print(
        f"Sim=[{sim_reseed_float[0]:10.6f}, {sim_reseed_float[1]:10.6f}, {sim_reseed_float[2]:10.6f}, {sim_reseed_float[3]:10.6f}]"
    )
    print(
        f"Exp=[{expected_reseed[0]:10.6f}, {expected_reseed[1]:10.6f}, {expected_reseed[2]:10.6f}, {expected_reseed[3]:10.6f}]"
    )
    print(f"Err=[{error_x:.6f}, {error_y:.6f}, {error_z:.6f}, {error_w:.6f}]")

    if error_x < 0.5 and error_y < 0.5 and error_z < 0.5 and error_w < 0.5:
        print("Status: PASS (within tolerance)")
    else:
        print("Status: FAIL (outside tolerance)")

    # Check if points are on unit 3-sphere
    print("\nUnit 3-sphere validation:")
    for i, sim_raw in enumerate(sim_values_raw):
        k = i + 1
        # Convert from Q32 fixed point (handle signed values)
        sim_float = []
        for val in sim_raw:
            if val >= 2147483648:  # Negative value in two's complement
                sim_float.append((val - 4294967296) / 2147483648.0)
            else:
                sim_float.append(val / 2147483648.0)

        radius_sq = (
            sim_float[0] ** 2
            + sim_float[1] ** 2
            + sim_float[2] ** 2
            + sim_float[3] ** 2
        )

        if 0.8 <= radius_sq <= 1.2:
            print(f"k={k}: r²={radius_sq:.6f} - ON unit 3-sphere")
        else:
            print(f"k={k}: r²={radius_sq:.6f} - OFF unit 3-sphere")


if __name__ == "__main__":
    generate_sphere3hopf_reference()
