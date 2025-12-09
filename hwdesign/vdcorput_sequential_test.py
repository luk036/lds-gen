#!/usr/bin/env python3
"""
Test sequential VdCorput generation similar to hardware FSM
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


def test_sequential():
    """Test sequential generation like hardware FSM"""
    print("Sequential VdCorput Generation Test")
    print("=" * 60)

    # Test like hardware: generate sequence for k=1 to 10
    for base in [2, 3, 7]:
        print(f"\nBase {base}:")
        print("-" * 40)
        for k in range(1, 11):
            result = vdc(k, base)
            fixed = float_to_fixed16_16(result)
            print(f"  k={k:2d}: {result:.6f} (0x{fixed:08x})")

    # Test reseed functionality
    print("\n\nReseed Test (like VdCorput class):")
    print("=" * 60)

    for base in [2, 3, 7]:
        print(f"\nBase {base} - First 5 values after reseed(0):")
        print("-" * 40)
        for k in range(1, 6):
            result = vdc(k, base)
            fixed = float_to_fixed16_16(result)
            print(f"  pop {k}: {result:.6f} (0x{fixed:08x})")


if __name__ == "__main__":
    test_sequential()
