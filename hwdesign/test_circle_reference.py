#!/usr/bin/env python3
"""
Python reference implementation for Circle sequence
to verify hardware implementation results.
"""

import math


def vdc(count: int, base: int = 2) -> float:
    """Van der Corput sequence"""
    res = 0.0
    denom = 1.0
    while count != 0:
        denom *= base
        count, remainder = divmod(count, base)
        res += remainder / denom
    return res


def float_to_fixed16_16(value: float) -> int:
    """Convert float to 16.16 fixed-point representation"""
    return int(value * (1 << 16))


class Circle:
    """Circle sequence generator (Python reference)"""

    def __init__(self, base):
        self.vdc = lambda count: vdc(count, base)

    def pop(self, count):
        theta = self.vdc(count) * 2 * math.pi
        return [math.cos(theta), math.sin(theta)]


def test_circle_values() -> None:
    """Test Circle values for different bases"""

    print("Python Circle Reference Values (16.16 fixed-point):")
    print("=" * 70)

    # Test different bases
    bases = [2, 3, 7]

    for base in bases:
        print(f"\nBase {base}:")
        print("-" * 40)

        circle = Circle(base)

        # Test first 5 values
        for count in range(1, 6):
            x, y = circle.pop(count)
            x_fixed = float_to_fixed16_16(x)
            y_fixed = float_to_fixed16_16(y)

            print(f"count={count}: [{x:.10f}, {y:.10f}]")
            print(f"      x=0x{x_fixed:08x}, y=0x{y_fixed:08x}")

    # Special test cases from Python examples
    print("\n\nSpecial Test Cases (from Python examples):")
    print("=" * 70)

    circle2 = Circle(2)
    print("\nBase 2, count=1 (from example):")
    x, y = circle2.pop(1)
    print("  Expected: [-1.0, 1.2246467991473532e-16]")
    print(f"  Got:      [{x:.10f}, {y:.10f}]")
    print(
        f"  Fixed:    x=0x{float_to_fixed16_16(x):08x}, y=0x{float_to_fixed16_16(y):08x}"
    )

    print("\nBase 2, count=2 (from example):")
    x, y = circle2.pop(2)
    print("  Expected: [6.123233995736766e-17, 1.0]")
    print(f"  Got:      [{x:.10f}, {y:.10f}]")
    print(
        f"  Fixed:    x=0x{float_to_fixed16_16(x):08x}, y=0x{float_to_fixed16_16(y):08x}"
    )


if __name__ == "__main__":
    test_circle_values()
