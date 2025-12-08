#!/usr/bin/env python3
"""
Final test of Circle implementation with CORDIC
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

def cordic_rotation(angle, iterations=16):
    """CORDIC rotation mode with quadrant reduction"""
    # CORDIC gain K ≈ 0.607253
    K = 0.6072529350088814
    
    # Quadrant reduction
    if angle < math.pi/2:
        # 0-90°
        reduced_angle = angle
        x = K
        y = 0.0
        quadrant = 0
    elif angle < math.pi:
        # 90-180°
        reduced_angle = angle - math.pi/2
        x = 0.0
        y = K
        quadrant = 1
    elif angle < 3*math.pi/2:
        # 180-270°
        reduced_angle = angle - math.pi
        x = -K
        y = 0.0
        quadrant = 2
    else:
        # 270-360°
        reduced_angle = angle - 3*math.pi/2
        x = 0.0
        y = -K
        quadrant = 3
    
    z = reduced_angle
    
    # Arctan table (atan(2^-i))
    atan_table = [
        math.atan(2**-i) for i in range(iterations)
    ]
    
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
    
    # Quadrant correction
    if quadrant == 0:
        cos_val = x
        sin_val = y
    elif quadrant == 1:
        cos_val = -y
        sin_val = x
    elif quadrant == 2:
        cos_val = -x
        sin_val = -y
    else:  # quadrant == 3
        cos_val = y
        sin_val = -x
    
    # Scale to ±1.0
    scale = 1.0 / K
    cos_val *= scale
    sin_val *= scale
    
    return cos_val, sin_val

def calculate_circle_point_cordic(k, base):
    """Calculate Circle point using CORDIC"""
    # 1. VdCorput result
    vdc_val = vdc(k, base)
    
    # 2. Angle = vdc * 2π
    angle = vdc_val * 2 * math.pi
    
    # 3. CORDIC computation
    x, y = cordic_rotation(angle)
    
    return {
        'k': k,
        'base': base,
        'vdc': vdc_val,
        'angle': angle,
        'x': x,
        'y': y,
    }

def main():
    print("Final test of Circle implementation with CORDIC")
    print("=" * 60)
    
    test_cases = [
        (1, 2),  # π
        (2, 2),  # π/2
        (3, 2),  # 3π/2
        (4, 2),  # π/4
        (5, 2),  # 5π/4
        (6, 2),  # 3π/4
        (7, 2),  # 7π/4
        (8, 2),  # π/8
    ]
    
    print("\nTest results:")
    print("-" * 60)
    
    max_x_error = 0
    max_y_error = 0
    
    for k, base in test_cases:
        result = calculate_circle_point_cordic(k, base)
        
        # Expected values
        vdc_val = vdc(k, base)
        angle = vdc_val * 2 * math.pi
        x_expected = math.cos(angle)
        y_expected = math.sin(angle)
        
        x_error = abs(result['x'] - x_expected)
        y_error = abs(result['y'] - y_expected)
        
        max_x_error = max(max_x_error, x_error)
        max_y_error = max(max_y_error, y_error)
        
        print(f"\nk={k}, base={base}:")
        print(f"  VdCorput: {result['vdc']:.6f}")
        print(f"  Angle: {result['angle']:.6f} rad ({result['angle']*180/math.pi:.1f}°)")
        print(f"  Result: x={result['x']:.6f}, y={result['y']:.6f}")
        print(f"  Expected: x={x_expected:.6f}, y={y_expected:.6f}")
        print(f"  Error: x={x_error:.6f}, y={y_error:.6f}")
    
    print("\n" + "=" * 60)
    print(f"Maximum error: x={max_x_error:.6f}, y={max_y_error:.6f}")
    print(f"Maximum error percentage: x={max_x_error*100:.2f}%, y={max_y_error*100:.2f}%")
    
    print("\n\nFixed-point conversion test:")
    print("=" * 60)
    
    # Test fixed-point calculations
    angle_rad = math.pi  # 180°
    
    # In hardware: 0-65535 maps to 0-2π
    angle_hw = int(angle_rad * 65535 / (2 * math.pi))
    
    # Convert back
    angle_recon = angle_hw * (2 * math.pi) / 65535
    
    print(f"\nπ ({angle_rad:.6f} rad):")
    print(f"  Hardware angle: {angle_hw} (0x{angle_hw:04x})")
    print(f"  Reconstructed: {angle_recon:.6f} rad")
    print(f"  Error: {abs(angle_rad - angle_recon):.6f} rad")
    
    # Test with CORDIC
    x_cordic, y_cordic = cordic_rotation(angle_recon)
    print(f"  CORDIC result: cos={x_cordic:.6f}, sin={y_cordic:.6f}")
    print(f"  Expected: cos={math.cos(angle_rad):.6f}, sin={math.sin(angle_rad):.6f}")

if __name__ == "__main__":
    main()
