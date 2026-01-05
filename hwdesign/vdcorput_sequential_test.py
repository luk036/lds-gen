#!/usr/bin/env python3
"""
Test sequential VdCorput generation similar to hardware FSM
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


def test_sequential() -> None:
    """Test sequential generation like hardware FSM"""
    print("Sequential VdCorput Generation Test")
    print("=" * 60)

    # Test like hardware: generate sequence for count=1 to 10
    for base in [2, 3, 7]:
        print(f"\nBase {base}:")
        print("-" * 40)
        for count in range(1, 11):
            result = vdc(count, base)
            fixed = float_to_fixed16_16(result)
            print(f"  count={count:2d}: {result:.6f} (0x{fixed:08x})")

    # Test reseed functionality
    print("\n\nReseed Test (like VdCorput class):")
    print("=" * 60)

    for base in [2, 3, 7]:
        print(f"\nBase {base} - First 5 values after reseed(0):")
        print("-" * 40)
        for count in range(1, 6):
            result = vdc(count, base)
            fixed = float_to_fixed16_16(result)
            print(f"  pop {count}: {result:.6f} (0x{fixed:08x})")


if __name__ == "__main__":
    test_sequential()
