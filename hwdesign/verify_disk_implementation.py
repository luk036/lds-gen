#!/usr/bin/env python3
"""
Verify Disk implementation calculations
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


def sqrt_approx(x):
    """Approximate sqrt(x) for x in [0, 1) using piecewise linear approximation"""
    if x < 0.25:
        return 0.5 * x + 0.5
    elif x < 0.5:
        return 0.4142 * x + 0.2929
    elif x < 0.75:
        return 0.3178 * x + 0.4393
    else:
        return 0.2679 * x + 0.5490


def cordic_rotation(angle, iterations=16):
    """Simplified CORDIC for testing"""
    # For testing, just use math.cos and math.sin
    # In real hardware, this would be CORDIC
    return math.cos(angle), math.sin(angle)


def disk_point_hw(k, base0, base1):
    """Simulate hardware Disk implementation"""
    # 1. VdCorput for angle
    vdc0 = vdc(k, base0)

    # 2. VdCorput for radius^2
    vdc1 = vdc(k, base1)

    # 3. Angle = vdc0 * 2π
    angle = vdc0 * 2 * math.pi

    # 4. Radius = sqrt(vdc1) using approximation
    radius = sqrt_approx(vdc1)

    # 5. cos/sin using CORDIC (simulated)
    cos_theta, sin_theta = cordic_rotation(angle)

    # 6. Final result
    x = radius * cos_theta
    y = radius * sin_theta

    return x, y, vdc0, vdc1, angle, radius


def main():
    print("Verifying Disk implementation")
    print("=" * 60)

    test_cases = [
        (1, 2, 3),
        (2, 2, 3),
        (3, 2, 3),
        (4, 2, 3),
        (5, 2, 3),
    ]

    print("\nComparison of exact vs hardware approximation:")
    print("-" * 60)

    for k, base0, base1 in test_cases:
        # Exact calculation
        theta_exact = vdc(k, base0) * 2 * math.pi
        radius_exact = math.sqrt(vdc(k, base1))
        x_exact = radius_exact * math.cos(theta_exact)
        y_exact = radius_exact * math.sin(theta_exact)

        # Hardware approximation
        x_hw, y_hw, vdc0, vdc1, angle, radius = disk_point_hw(k, base0, base1)

        x_error = abs(x_exact - x_hw)
        y_error = abs(y_exact - y_hw)

        print(f"\nk={k}, base=[{base0},{base1}]:")
        print(f"  VdCorput: angle={vdc0:.6f}, radius^2={vdc1:.6f}")
        print(f"  Angle: {angle:.6f} rad ({angle*180/math.pi:.1f}°)")
        print(f"  Radius: exact={radius_exact:.6f}, approx={radius:.6f}")
        print(f"  Result: exact=({x_exact:.6f}, {y_exact:.6f})")
        print(f"           hw=({x_hw:.6f}, {y_hw:.6f})")
        print(f"  Error: x={x_error:.6f}, y={y_error:.6f}")

    print("\n\nSquare root approximation error:")
    print("-" * 60)

    # Test sqrt approximation
    test_values = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 0.99]
    for x in test_values:
        exact = math.sqrt(x)
        approx = sqrt_approx(x)
        error = abs(exact - approx)
        print(
            f"sqrt({x:.2f}): exact={exact:.6f}, approx={approx:.6f}, error={error:.6f}"
        )


if __name__ == "__main__":
    main()
