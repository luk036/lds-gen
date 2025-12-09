#!/usr/bin/env python3
"""
Python reference implementation for Halton sequence
to verify hardware implementation results.
"""


def vdc(k: int, base: int = 2) -> float:
    """Van der Corput sequence"""
    res = 0.0
    denom = 1.0
    while k != 0:
        denom *= base
        k, remainder = divmod(k, base)
        res += remainder / denom
    return res


def float_to_fixed16_16(value: float) -> int:
    """Convert float to 16.16 fixed-point representation"""
    return int(value * (1 << 16))


class Halton:
    """Halton sequence generator (Python reference)"""

    def __init__(self, base):
        self.vdc0 = lambda k: vdc(k, base[0])
        self.vdc1 = lambda k: vdc(k, base[1])

    def pop(self, k):
        return [self.vdc0(k), self.vdc1(k)]


def test_halton_values():
    """Test Halton values for different base combinations"""

    print("Python Halton Reference Values (16.16 fixed-point):")
    print("=" * 70)

    # Test different base combinations
    base_combinations = [
        ([2, 3], "00,01"),
        ([2, 7], "00,10"),
        ([3, 7], "01,10"),
    ]

    for bases, base_codes in base_combinations:
        print(f"\nBase {bases} (sel={base_codes}):")
        print("-" * 40)

        halton = Halton(bases)
        num_tests = 10 if bases == [2, 3] else 5

        for k in range(1, num_tests + 1):
            x, y = halton.pop(k)
            x_fixed = float_to_fixed16_16(x)
            y_fixed = float_to_fixed16_16(y)

            print(f"k={k:2d}: [{x:.10f}, {y:.10f}]")
            print(f"      x=0x{x_fixed:08x}, y=0x{y_fixed:08x}")

    # Compare with hardware test vectors
    print("\n\nHardware Test Vector Comparison:")
    print("=" * 70)

    # Base [2,3] specific values from testbench
    print("\nBase [2,3] - First 5 values:")
    halton = Halton([2, 3])
    for k in [1, 2, 3, 4, 5]:
        x, y = halton.pop(k)
        x_fixed = float_to_fixed16_16(x)
        y_fixed = float_to_fixed16_16(y)
        print(f"k={k}: x=0x{x_fixed:08x}, y=0x{y_fixed:08x}")


if __name__ == "__main__":
    test_halton_values()
