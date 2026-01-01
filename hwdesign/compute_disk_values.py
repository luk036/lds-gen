#!/usr/bin/env python3
"""
Compute expected Disk sequence values for testbench
"""

import math


def vdc(k, base=2):
    """Van der Corput sequence"""
    res = 0.0
    denom = 1.0
    while k != 0:
        denom *= base
        k, remainder = divmod(k, base)
        res += remainder / denom
    return res


def disk_point(k, base0, base1):
    """Compute Disk point"""
    theta = vdc(k, base0) * 2 * math.pi
    radius = math.sqrt(vdc(k, base1))
    x = radius * math.cos(theta)
    y = radius * math.sin(theta)
    return x, y


def main():
    print("Disk sequence expected values")
    print("=" * 60)

    # Test cases from Python documentation
    print("\nBase combination [2, 3]:")
    print("-" * 40)
    for k in range(1, 11):
        x, y = disk_point(k, 2, 3)
        print(f"k={k}: ({x:.10f}, {y:.10f})")

    print("\n\nBase combination [2, 7]:")
    print("-" * 40)
    for k in range(1, 6):
        x, y = disk_point(k, 2, 7)
        print(f"k={k}: ({x:.10f}, {y:.10f})")

    print("\n\nBase combination [3, 7]:")
    print("-" * 40)
    for k in range(1, 6):
        x, y = disk_point(k, 3, 7)
        print(f"k={k}: ({x:.10f}, {y:.10f})")

    print("\n\nFixed-point conversion (16.16):")
    print("-" * 40)
    # Test k=1, base=[2,3]
    x, y = disk_point(1, 2, 3)
    x_fp = int(x * 65536)
    y_fp = int(y * 65536)
    print("k=1, base=[2,3]:")
    print(f"  Float: x={x:.10f}, y={y:.10f}")
    print(f"  Fixed-point: x=0x{x_fp:08x} ({x_fp}), y=0x{y_fp:08x} ({y_fp})")
    print(f"  Converted back: x={x_fp / 65536.0:.10f}, y={y_fp / 65536.0:.10f}")


if __name__ == "__main__":
    main()
