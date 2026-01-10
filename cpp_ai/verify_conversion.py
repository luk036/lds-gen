#!/usr/bin/env python3
"""
Verify that the C++ implementation matches the Python implementation.
This script runs the Python lds_gen library and compares expected outputs.
"""

import sys
import os

# Add the Python lds_gen to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from lds_gen.lds import (
    vdc,
    VdCorput,
    Halton,
    Circle,
    Disk,
    Sphere,
    Sphere3Hopf,
    HaltonN,
)


def test_vdc():
    """Test vdc function"""
    print("Testing vdc function...")
    result = vdc(11, 2)
    expected = 0.8125
    assert abs(result - expected) < 1e-10, f"vdc(11, 2) = {result}, expected {expected}"
    print(f"  ✓ vdc(11, 2) = {result}")


def test_vdcorput():
    """Test VdCorput class"""
    print("Testing VdCorput class...")
    vgen = VdCorput(2)
    vgen.reseed(0)

    expected_values = [0.5, 0.25, 0.75, 0.125, 0.625]
    for i, expected in enumerate(expected_values):
        result = vgen.pop()
        assert (
            abs(result - expected) < 1e-10
        ), f"VdCorput[{i}] = {result}, expected {expected}"
        print(f"  ✓ VdCorput[{i}] = {result}")


def test_halton():
    """Test Halton class"""
    print("Testing Halton class...")
    hgen = Halton([2, 3])
    hgen.reseed(0)

    result = hgen.pop()
    expected = [0.5, 1 / 3]
    for i in range(2):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"Halton[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ Halton[0] = {result}")


def test_circle():
    """Test Circle class"""
    print("Testing Circle class...")
    cgen = Circle(2)
    cgen.reseed(0)

    result = cgen.pop()
    expected = [-1.0, 0.0]
    for i in range(2):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"Circle[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ Circle[0] = {result}")


def test_disk():
    """Test Disk class"""
    print("Testing Disk class...")
    dgen = Disk([2, 3])
    dgen.reseed(0)

    result = dgen.pop()
    expected = [-0.5773502691896257, 0.0]
    for i in range(2):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"Disk[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ Disk[0] = {result}")


def test_sphere():
    """Test Sphere class"""
    print("Testing Sphere class...")
    sgen = Sphere([2, 3])
    sgen.reseed(0)

    result = sgen.pop()
    expected = [-0.5, 0.8660254037844387, 0.0]
    for i in range(3):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"Sphere[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ Sphere[0] = {result}")


def test_sphere3hopf():
    """Test Sphere3Hopf class"""
    print("Testing Sphere3Hopf class...")
    sp3hgen = Sphere3Hopf([2, 3, 5])
    sp3hgen.reseed(0)

    result = sp3hgen.pop()
    expected = [
        -0.22360679774997885,
        0.3872983346207417,
        0.4472135954999573,
        -0.7745966692414837,
    ]
    for i in range(4):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"Sphere3Hopf[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ Sphere3Hopf[0] = {result}")


def test_haltonn():
    """Test HaltonN class"""
    print("Testing HaltonN class...")
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)

    result = hgen.pop()
    expected = [0.5, 1 / 3, 0.2]
    for i in range(3):
        assert (
            abs(result[i] - expected[i]) < 1e-10
        ), f"HaltonN[0][{i}] = {result[i]}, expected {expected[i]}"
    print(f"  ✓ HaltonN[0] = {result}")


def main():
    """Run all tests"""
    print("Verifying Python lds_gen implementation...")
    print("=" * 50)

    try:
        test_vdc()
        test_vdcorput()
        test_halton()
        test_circle()
        test_disk()
        test_sphere()
        test_sphere3hopf()
        test_haltonn()

        print("=" * 50)
        print("All Python tests passed! ✓")
        print("\nThe C++ implementation in ./cpp_ai should produce the same results.")
        print("To verify the C++ implementation:")
        print(
            "1. Build with CMake: mkdir build && cd build && cmake .. && cmake --build ."
        )
        print("2. Run tests: ctest")
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
