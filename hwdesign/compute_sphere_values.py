#!/usr/bin/env python3
"""
Compute expected Sphere sequence values for verification
"""

import sys

sys.path.append("../src")
from lds_gen.lds import Sphere


def compute_sphere_values():
    print("Sphere sequence expected values (Python reference)")
    print("==================================================")

    # Test base combinations
    test_cases = [
        ([2, 3], "Base [2, 3]"),
        ([2, 7], "Base [2, 7]"),
        ([3, 7], "Base [3, 7]"),
    ]

    for bases, desc in test_cases:
        print(f"\n{desc}:")
        sgen = Sphere(bases)
        sgen.reseed(0)

        for count in range(1, 6):  # count = 1 to 5
            result = sgen.pop()
            # Convert to 16.16 fixed-point
            x_fp = int(result[0] * 65536)
            y_fp = int(result[1] * 65536)
            z_fp = int(result[2] * 65536)

            print(
                f"  count={count}: [{result[0]:.6f}, {result[1]:.6f}, {result[2]:.6f}]"
            )
            print(f"       x={x_fp:08x}, y={y_fp:08x}, z={z_fp:08x}")


if __name__ == "__main__":
    compute_sphere_values()
