#!/usr/bin/env python3
"""
Python reference implementation for VdCorput sequence
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


def test_vdc_values() -> None:
    """Test VdCorput values for bases 2, 3, and 7"""

    test_cases = [
        (1, 2, 0.5),
        (2, 2, 0.25),
        (3, 2, 0.75),
        (4, 2, 0.125),
        (5, 2, 0.625),
        (11, 2, 0.8125),
        (1, 3, 1 / 3),
        (2, 3, 2 / 3),
        (3, 3, 1 / 9),
        (4, 3, 4 / 9),
        (5, 3, 7 / 9),
        (11, 3, 11 / 27),
        (1, 7, 1 / 7),
        (2, 7, 2 / 7),
        (3, 7, 3 / 7),
        (4, 7, 4 / 7),
        (5, 7, 5 / 7),
        (11, 7, 11 / 49),
    ]

    print("Python VdCorput Reference Values (16.16 fixed-point):")
    print("=" * 60)

    for count, base, expected in test_cases:
        result = vdc(count, base)
        fixed_result = float_to_fixed16_16(result)
        fixed_expected = float_to_fixed16_16(expected)

        print(f"vdc({count}, {base}) = {result:.10f}")
        print(f"  Float: {result:.10f}")
        print(f"  Fixed (16.16): 0x{fixed_result:08x}")
        print(f"  Expected fixed: 0x{fixed_expected:08x}")
        print(f"  Match: {'YES' if fixed_result == fixed_expected else 'NO'}")
        print()


if __name__ == "__main__":
    test_vdc_values()
