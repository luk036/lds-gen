#!/usr/bin/env python3
"""
Verify Circle module calculations
"""

import math


def vdc(count, base=2):
    """Van der Corput sequence"""
    res = 0.0
    denom = 1.0
    while count != 0:
        denom *= base
        count, remainder = divmod(count, base)
        res += remainder / denom
    return res


def fixed_point_16_16(value):
    """Convert float to 16.16 fixed-point"""
    return int(value * 65536)


def fixed_to_float(value):
    """Convert 16.16 fixed-point to float"""
    return value / 65536.0


def calculate_circle_point(count, base):
    """Calculate Circle point using fixed-point arithmetic"""
    # 1. VdCorput result
    vdc_val = vdc(count, base)
    vdc_fp = fixed_point_16_16(vdc_val)

    # 2. Angle = vdc * 2π
    fp_two_pi = fixed_point_16_16(2 * math.pi)  # 0x0006487f
    angle_fp = (vdc_fp * fp_two_pi) >> 16

    # 3. Convert angle to LUT index (0-65535 for 0-2π)
    fp_one_div_2pi = fixed_point_16_16(1.0 / (2 * math.pi))  # 0x000028be
    lut_index = (angle_fp * fp_one_div_2pi) >> 16

    # 4. LUT uses upper 8 bits
    lut_entry = lut_index >> 8

    # 5. Simple LUT calculation
    angle_rad = 2 * math.pi * lut_entry / 256.0
    x = math.cos(angle_rad)
    y = math.sin(angle_rad)

    # Convert to fixed-point
    x_fp = fixed_point_16_16(x)
    y_fp = fixed_point_16_16(y)

    return {
        "count": count,
        "base": base,
        "vdc": vdc_val,
        "vdc_fp": f"0x{vdc_fp:08x}",
        "angle_rad": angle_rad,
        "angle_fp": f"0x{angle_fp:08x}",
        "lut_index": lut_index,
        "lut_index_hex": f"0x{lut_index:04x}",
        "lut_entry": lut_entry,
        "lut_entry_hex": f"0x{lut_entry:02x}",
        "x": x,
        "y": y,
        "x_fp": f"0x{x_fp:08x}",
        "y_fp": f"0x{y_fp:08x}",
    }


def main():
    print("Verifying Circle module calculations")
    print("=" * 50)

    test_cases = [
        (1, 2),  # π
        (2, 2),  # π/2
        (3, 2),  # 3π/2
        (4, 2),  # π/4
        (5, 2),  # 5π/4
    ]

    for count, base in test_cases:
        result = calculate_circle_point(count, base)
        print(f"\nk={count}, base={base}:")
        print(f"  VdCorput: {result['vdc']:.6f} ({result['vdc_fp']})")
        print(f"  Angle: {result['angle_rad']:.6f} rad ({result['angle_fp']})")
        print(f"  LUT index: {result['lut_index']} ({result['lut_index_hex']})")
        print(f"  LUT entry: {result['lut_entry']} ({result['lut_entry_hex']})")
        print(f"  Result: x={result['x']:.6f}, y={result['y']:.6f}")
        print(f"  Fixed-point: x={result['x_fp']}, y={result['y_fp']}")

    print("\n\nExpected values from Python direct calculation:")
    print("=" * 50)
    for count, base in test_cases:
        vdc_val = vdc(count, base)
        angle = vdc_val * 2 * math.pi
        x = math.cos(angle)
        y = math.sin(angle)
        x_fp = fixed_point_16_16(x)
        y_fp = fixed_point_16_16(y)
        print(f"\nk={count}, base={base}:")
        print(f"  VdCorput: {vdc_val:.6f}")
        print(f"  Angle: {angle:.6f} rad")
        print(f"  Result: x={x:.6f}, y={y:.6f}")
        print(f"  Fixed-point: x=0x{x_fp:08x}, y=0x{y_fp:08x}")


if __name__ == "__main__":
    main()
