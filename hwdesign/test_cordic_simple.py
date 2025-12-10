#!/usr/bin/env python3
"""
Test CORDIC calculations
"""

import math


def cordic_rotation(angle, iterations=16):
    """CORDIC rotation mode algorithm in Python"""
    # CORDIC gain K ≈ 0.607253
    K = 0.6072529350088814

    # Initialize
    x = K
    y = 0.0
    z = angle  # Angle in radians

    # Arctan table (atan(2^-i))
    atan_table = [math.atan(2**-i) for i in range(iterations)]

    # CORDIC iterations
    for i in range(iterations):
        if z >= 0:
            # Rotate negative
            x_next = x - y * (2**-i)
            y_next = y + x * (2**-i)
            z_next = z - atan_table[i]
        else:
            # Rotate positive
            x_next = x + y * (2**-i)
            y_next = y - x * (2**-i)
            z_next = z + atan_table[i]

        x, y, z = x_next, y_next, z_next

    return x, y


def test_cordic() -> None:
    print("Testing CORDIC algorithm")
    print("=" * 50)

    # Test angles (in radians)
    test_angles = [
        0.0,  # 0°
        math.pi / 4,  # 45°
        math.pi / 2,  # 90°
        math.pi,  # 180°
        3 * math.pi / 2,  # 270°
        2 * math.pi,  # 360°
    ]

    for angle in test_angles:
        x_cordic, y_cordic = cordic_rotation(angle)
        x_expected = math.cos(angle)
        y_expected = math.sin(angle)

        x_error = abs(x_cordic - x_expected)
        y_error = abs(y_cordic - y_expected)

        print(f"\nAngle: {angle:.6f} rad ({angle*180/math.pi:.1f}°)")
        print(f"  CORDIC: cos={x_cordic:.6f}, sin={y_cordic:.6f}")
        print(f"  Expected: cos={x_expected:.6f}, sin={y_expected:.6f}")
        print(f"  Error: cos={x_error:.6f}, sin={y_error:.6f}")

    print("\n\nTesting fixed-point conversion")
    print("=" * 50)

    # Test angle conversion
    angle_deg = 45
    angle_rad = math.radians(angle_deg)

    # In hardware: 0-65535 maps to 0-2π
    angle_hw = int(angle_rad * 65535 / (2 * math.pi))

    print(f"\n{angle_deg}° = {angle_rad:.6f} rad")
    print(f"Hardware angle (0-65535): {angle_hw} (0x{angle_hw:04x})")

    # Convert back
    angle_recon = angle_hw * (2 * math.pi) / 65535
    print(f"Reconstructed: {angle_recon:.6f} rad ({math.degrees(angle_recon):.2f}°)")

    # Test CORDIC with hardware angle
    # First convert to radians
    angle_rad_hw = angle_hw * (2 * math.pi) / 65535
    x_cordic, y_cordic = cordic_rotation(angle_rad_hw)

    print("\nCORDIC with hardware angle:")
    print(f"  cos(45°): {x_cordic:.6f} (expected: {math.cos(angle_rad):.6f})")
    print(f"  sin(45°): {y_cordic:.6f} (expected: {math.sin(angle_rad):.6f})")


if __name__ == "__main__":
    test_cordic()
