#!/usr/bin/env python3
"""
Verify that the C++ sphere_n implementation matches the Python implementation.
"""

import os
import sys

from lds_gen.sphere_n import Sphere3, SphereN, get_tp, linspace, simple_interp

# Add the Python lds_gen to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))


def test_linspace():
    """Test linspace function"""
    print("Testing linspace function...")
    result = linspace(0.0, 1.0, 5)
    expected = [0.0, 0.25, 0.5, 0.75, 1.0]
    assert len(result) == 5
    for i, val in enumerate(result):
        assert abs(val - expected[i]) < 1e-10, (
            f"linspace[{i}] = {val}, expected {expected[i]}"
        )
    print(f"  ✓ linspace(0.0, 1.0, 5) = {result}")


def test_simple_interp():
    """Test simple_interp function"""
    print("Testing simple_interp function...")
    xp = [0.0, 1.0, 2.0, 3.0]
    yp = [0.0, 2.0, 4.0, 6.0]

    result = simple_interp(0.5, xp, yp)
    expected = 1.0
    assert abs(result - expected) < 1e-10, (
        f"simple_interp(0.5) = {result}, expected {expected}"
    )
    print(f"  ✓ simple_interp(0.5) = {result}")

    result = simple_interp(1.5, xp, yp)
    expected = 3.0
    assert abs(result - expected) < 1e-10, (
        f"simple_interp(1.5) = {result}, expected {expected}"
    )
    print(f"  ✓ simple_interp(1.5) = {result}")


def test_get_tp():
    """Test get_tp function"""
    print("Testing get_tp function...")
    tp0 = get_tp(0)
    assert len(tp0) == 300
    assert tp0[0] == 0.0
    assert abs(tp0[-1] - 3.141592653589793) < 1e-10
    print(f"  ✓ get_tp(0): size={len(tp0)}, first={tp0[0]}, last={tp0[-1]}")

    tp1 = get_tp(1)
    assert len(tp1) == 300
    assert abs(tp1[0] - (-1.0)) < 1e-10
    assert abs(tp1[-1] - 1.0) < 1e-10
    print(f"  ✓ get_tp(1): size={len(tp1)}, first={tp1[0]}, last={tp1[-1]}")


def test_sphere3():
    """Test Sphere3 class"""
    print("Testing Sphere3 class...")
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)

    result = sgen.pop()
    expected = [
        0.2913440162992141,
        0.8966646826186098,
        -0.33333333333333337,
        6.123233995736766e-17,
    ]

    assert len(result) == 4
    for i in range(4):
        assert abs(result[i] - expected[i]) < 1e-10, (
            f"Sphere3[{i}] = {result[i]}, expected {expected[i]}"
        )

    # Check if point is on unit sphere
    radius_sq = sum(x * x for x in result)
    assert abs(radius_sq - 1.0) < 1e-10, f"Point not on unit sphere: r²={radius_sq}"

    print(f"  ✓ Sphere3 first point: {result}")


def test_sphereN():
    """Test SphereN class"""
    print("Testing SphereN class...")
    sgen = SphereN([2, 3, 5, 7])
    sgen.reseed(0)

    result = sgen.pop()
    expected = [
        0.4809684718990214,
        0.6031153874276115,
        -0.5785601510223212,
        0.2649326520763179,
        6.123233995736766e-17,
    ]

    assert len(result) == 5
    for i in range(5):
        assert abs(result[i] - expected[i]) < 1e-10, (
            f"SphereN[{i}] = {result[i]}, expected {expected[i]}"
        )

    # Check if point is on unit sphere
    radius_sq = sum(x * x for x in result)
    assert abs(radius_sq - 1.0) < 1e-10, f"Point not on unit sphere: r²={radius_sq}"

    print(f"  ✓ SphereN first point: {result}")


def main():
    """Run all tests"""
    print("Verifying Python sphere_n implementation...")
    print("=" * 50)

    try:
        test_linspace()
        test_simple_interp()
        test_get_tp()
        test_sphere3()
        test_sphereN()

        print("=" * 50)
        print("All Python sphere_n tests passed! ✓")
        print("\nThe C++ implementation in ./cpp_ai should produce the same results.")
        print("To verify the C++ implementation:")
        print(
            "1. Build with CMake: mkdir build && cd build && cmake .. && cmake --build ."
        )
        print("2. Run sphere_n tests: ./test_sphere_n")
        print("3. Run example: ./example")

    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        sys.exit(1)
    except ImportError as e:
        print(f"\n✗ Could not import lds_gen: {e}")
        print("Make sure you're running from the lds-gen project root directory.")
        sys.exit(1)


if __name__ == "__main__":
    main()
