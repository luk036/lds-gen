#!/usr/bin/env python3
"""
Verify Circle module calculations with 1024-entry LUT
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


def fixed_point_16_16(value):
    """Convert float to 16.16 fixed-point"""
    return int(value * 65536)


def fixed_to_float(value):
    """Convert 16.16 fixed-point to float"""
    return value / 65536.0


def calculate_circle_point_1024(k, base):
    """Calculate Circle point using fixed-point arithmetic with 1024-entry LUT"""
    # 1. VdCorput result
    vdc_val = vdc(k, base)
    vdc_fp = fixed_point_16_16(vdc_val)

    # 2. Angle = vdc * 2π
    fp_two_pi = fixed_point_16_16(2 * math.pi)  # 0x0006487f
    angle_fp = (vdc_fp * fp_two_pi) >> 16

    # 3. Convert angle to LUT index (0-65535 for 0-2π)
    fp_one_div_2pi = fixed_point_16_16(1.0 / (2 * math.pi))  # 0x000028be
    lut_index = (angle_fp * fp_one_div_2pi) >> 16

    # 4. 1024-entry LUT uses upper 10 bits
    lut_entry = lut_index >> 6  # 16-10 = 6 bits to shift

    # 5. LUT calculation with 1024 entries
    angle_rad = 2 * math.pi * lut_entry / 1024.0
    x = math.cos(angle_rad)
    y = math.sin(angle_rad)

    # Convert to fixed-point
    x_fp = fixed_point_16_16(x)
    y_fp = fixed_point_16_16(y)

    return {
        "k": k,
        "base": base,
        "vdc": vdc_val,
        "vdc_fp": f"0x{vdc_fp:08x}",
        "angle_rad": angle_rad,
        "angle_fp": f"0x{angle_fp:08x}",
        "lut_index": lut_index,
        "lut_index_hex": f"0x{lut_index:04x}",
        "lut_entry": lut_entry,
        "lut_entry_hex": f"0x{lut_entry:03x}",
        "x": x,
        "y": y,
        "x_fp": f"0x{x_fp:08x}",
        "y_fp": f"0x{y_fp:08x}",
    }


def main():
    print("Verifying Circle module calculations with 1024-entry LUT")
    print("=" * 60)

    test_cases = [
        (1, 2),  # π
        (2, 2),  # π/2
        (3, 2),  # 3π/2
        (4, 2),  # π/4
        (5, 2),  # 5π/4
    ]

    for k, base in test_cases:
        result = calculate_circle_point_1024(k, base)
        print(f"\nk={k}, base={base}:")
        print(f"  VdCorput: {result['vdc']:.6f} ({result['vdc_fp']})")
        print(f"  Angle: {result['angle_rad']:.6f} rad ({result['angle_fp']})")
        print(f"  LUT index: {result['lut_index']} ({result['lut_index_hex']})")
        print(f"  LUT entry: {result['lut_entry']} ({result['lut_entry_hex']})")
        print(f"  Result: x={result['x']:.6f}, y={result['y']:.6f}")
        print(f"  Fixed-point: x={result['x_fp']}, y={result['y_fp']}")

    print("\n\nExpected values from Python direct calculation:")
    print("=" * 60)
    for k, base in test_cases:
        vdc_val = vdc(k, base)
        angle = vdc_val * 2 * math.pi
        x = math.cos(angle)
        y = math.sin(angle)
        x_fp = fixed_point_16_16(x)
        y_fp = fixed_point_16_16(y)
        print(f"\nk={k}, base={base}:")
        print(f"  VdCorput: {vdc_val:.6f}")
        print(f"  Angle: {angle:.6f} rad")
        print(f"  Result: x={x:.6f}, y={y:.6f}")
        print(f"  Fixed-point: x=0x{x_fp:08x}, y=0x{y_fp:08x}")

    print("\n\nError analysis:")
    print("=" * 60)
    for k, base in test_cases:
        result = calculate_circle_point_1024(k, base)
        vdc_val = vdc(k, base)
        angle = vdc_val * 2 * math.pi
        x_expected = math.cos(angle)
        y_expected = math.sin(angle)
        x_actual = result["x"]
        y_actual = result["y"]

        x_error = abs(x_expected - x_actual)
        y_error = abs(y_expected - y_actual)

        print(f"\nk={k}, base={base}:")
        print(f"  x error: {x_error:.6f} ({x_error*100:.2f}%)")
        print(f"  y error: {y_error:.6f} ({y_error*100:.2f}%)")


if __name__ == "__main__":
    main()
