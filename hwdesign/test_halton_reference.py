#!/usr/bin/env python3
"""
Python reference implementation for Halton sequence
to verify hardware implementation results.
"""


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


class Halton:
    """Halton sequence generator (Python reference)"""

    def __init__(self, base):
        self.vdc0 = lambda count: vdc(count, base[0])
        self.vdc1 = lambda count: vdc(count, base[1])

    def pop(self, count):
        return [self.vdc0(count), self.vdc1(count)]


def test_halton_values() -> None:
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

        for count in range(1, num_tests + 1):
            x, y = halton.pop(count)
            x_fixed = float_to_fixed16_16(x)
            y_fixed = float_to_fixed16_16(y)

            print(f"count={count:2d}: [{x:.10f}, {y:.10f}]")
            print(f"      x=0x{x_fixed:08x}, y=0x{y_fixed:08x}")

    # Compare with hardware test vectors
    print("\n\nHardware Test Vector Comparison:")
    print("=" * 70)

    # Base [2,3] specific values from testbench
    print("\nBase [2,3] - First 5 values:")
    halton = Halton([2, 3])
    for count in [1, 2, 3, 4, 5]:
        x, y = halton.pop(count)
        x_fixed = float_to_fixed16_16(x)
        y_fixed = float_to_fixed16_16(y)
        print(f"count={count}: x=0x{x_fixed:08x}, y=0x{y_fixed:08x}")


if __name__ == "__main__":
    test_halton_values()
