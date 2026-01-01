"""Unit tests for sphere_n.py module (NumPy-free version)."""

import math
import sys
import os
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from lds_gen.sphere_n import Sphere3, SphereN, linspace, simple_interp, get_tp


def test_linspace() -> None:
    """Test the linspace function."""
    # Test basic functionality
    result = linspace(0.0, 1.0, 5)
    expected = [0.0, 0.25, 0.5, 0.75, 1.0]
    assert len(result) == 5
    for i, val in enumerate(result):
        assert abs(val - expected[i]) < 1e-10

    # Test single point
    result = linspace(0.0, 1.0, 1)
    assert result == [0.0]

    # Test negative values
    result = linspace(-1.0, 1.0, 3)
    expected = [-1.0, 0.0, 1.0]
    for i, val in enumerate(result):
        assert abs(val - expected[i]) < 1e-10


def test_simple_interp() -> None:
    """Test the simple_interp function."""
    xp = [0.0, 1.0, 2.0, 3.0]
    yp = [0.0, 2.0, 4.0, 6.0]  # Linear function y = 2x

    # Test interpolation within range
    result = simple_interp(0.5, xp, yp)
    assert abs(result - 1.0) < 1e-10  # Should be 2 * 0.5

    result = simple_interp(1.5, xp, yp)
    assert abs(result - 3.0) < 1e-10  # Should be 2 * 1.5

    # Test extrapolation (clamping)
    result = simple_interp(-0.5, xp, yp)
    assert result == 0.0  # Should clamp to first value

    result = simple_interp(3.5, xp, yp)
    assert result == 6.0  # Should clamp to last value

    # Test exact points
    result = simple_interp(2.0, xp, yp)
    assert result == 4.0


def test_get_tp() -> None:
    """Test the get_tp function."""
    # Test for n=0
    tp0 = get_tp(0)
    assert len(tp0) == 300
    assert tp0[0] == 0.0
    assert abs(tp0[-1] - math.pi) < 1e-10

    # Test for n=1
    tp1 = get_tp(1)
    assert len(tp1) == 300
    assert abs(tp1[0] - (-math.cos(0.0))) < 1e-10
    assert abs(tp1[-1] - (-math.cos(math.pi))) < 1e-10

    # Test for n=2
    tp2 = get_tp(2)
    assert len(tp2) == 300


def test_sphere3_basic() -> None:
    """Test basic Sphere3 functionality."""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)

    # Test first point
    point = sgen.pop()
    assert len(point) == 4
    assert isinstance(point, list)

    # Check if point is on unit 3-sphere (approximately)
    radius_sq = sum(x * x for x in point)
    assert abs(radius_sq - 1.0) < 1e-10, (
        f"Point {point} not on unit sphere: r²={radius_sq}"
    )

    # Test that values are reasonable
    for coord in point:
        assert -1.0 <= coord <= 1.0


def test_sphere3_consistency() -> None:
    """Test Sphere3 sequence consistency."""
    bases = [[2, 3, 5], [2, 5, 3], [3, 2, 7]]

    for base in bases:
        sgen = Sphere3(base)
        sgen.reseed(0)

        # Generate multiple points
        points = [sgen.pop() for _ in range(5)]

        # Check all points are on unit 3-sphere
        for i, point in enumerate(points):
            radius_sq = sum(x * x for x in point)
            assert abs(radius_sq - 1.0) < 1e-10, (
                f"Base {base}, Point {i}: {point}, r²={radius_sq}"
            )


def test_sphere3_reseed() -> None:
    """Test Sphere3 reseed functionality."""
    sgen = Sphere3([2, 3, 5])

    # Generate sequence with seed 0
    sgen.reseed(0)
    seq1 = [sgen.pop() for _ in range(3)]

    # Generate sequence with seed 0 again
    sgen.reseed(0)
    seq2 = [sgen.pop() for _ in range(3)]

    # Should be identical
    for i in range(3):
        for j in range(4):
            assert abs(seq1[i][j] - seq2[i][j]) < 1e-10

    # Different seed should give different sequence
    sgen.reseed(1)
    seq3 = [sgen.pop() for _ in range(3)]

    # Should be different from seed 0
    different = False
    for i in range(3):
        for j in range(4):
            if abs(seq1[i][j] - seq3[i][j]) > 1e-10:
                different = True
                break
        if different:
            break
    assert different


def test_spheren_basic() -> None:
    """Test basic SphereN functionality."""
    # Test 4-sphere (5D)
    sgen = SphereN([2, 3, 5, 7])
    sgen.reseed(0)

    point = sgen.pop()
    assert len(point) == 5  # 4 bases produce 5D point
    assert isinstance(point, list)

    # Check if point is on unit 4-sphere (approximately)
    radius_sq = sum(x * x for x in point)
    assert abs(radius_sq - 1.0) < 1e-10, (
        f"Point {point} not on unit sphere: r²={radius_sq}"
    )


def test_spheren_higher_dimensions() -> None:
    """Test SphereN with higher dimensions."""
    # Test 5-sphere (6D)
    sgen = SphereN([2, 3, 5, 7, 11])
    sgen.reseed(0)

    point = sgen.pop()
    assert len(point) == 6  # 5 bases produce 6D point

    # Check if point is on unit 5-sphere (approximately)
    radius_sq = sum(x * x for x in point)
    assert abs(radius_sq - 1.0) < 1e-10, (
        f"Point {point} not on unit sphere: r²={radius_sq}"
    )


def test_spheren_reseed() -> None:
    """Test SphereN reseed functionality."""
    sgen = SphereN([2, 3, 5, 7])

    # Generate sequence with seed 0
    sgen.reseed(0)
    seq1 = [sgen.pop() for _ in range(3)]

    # Generate sequence with seed 0 again
    sgen.reseed(0)
    seq2 = [sgen.pop() for _ in range(3)]

    # Should be identical
    for i in range(3):
        for j in range(4):
            assert abs(seq1[i][j] - seq2[i][j]) < 1e-10


def test_comparison_with_original() -> None:
    """Test that results match the original implementation."""
    # Expected values from doctest examples
    expected_sphere3 = [
        0.2913440162992141,
        0.8966646826186098,
        -0.33333333333333337,
        6.123233995736766e-17,
    ]
    expected_spheren = [
        0.4809684718990214,
        0.6031153874276115,
        -0.5785601510223212,
        0.2649326520763179,
        6.123233995736766e-17,
    ]

    # Test Sphere3
    sgen3 = Sphere3([2, 3, 5])
    sgen3.reseed(0)
    result3 = sgen3.pop()

    for i in range(4):
        assert abs(result3[i] - expected_sphere3[i]) < 1e-10

    # Test SphereN
    sgenN = SphereN([2, 3, 5, 7])
    sgenN.reseed(0)
    resultN = sgenN.pop()

    for i in range(5):
        assert abs(resultN[i] - expected_spheren[i]) < 1e-10


def test_uniformity() -> None:
    """Test that points are reasonably uniformly distributed."""
    sgen = Sphere3([2, 3, 7])
    sgen.reseed(0)

    # Generate many points
    points = [sgen.pop() for _ in range(1000)]

    # Check that points are on unit sphere
    for point in points:
        radius_sq = sum(x * x for x in point)
        assert abs(radius_sq - 1.0) < 1e-10

    # Simple uniformity check: count points in each octant
    octants = [0] * 16  # 16 octants in 4D

    for point in points:
        octant = 0
        for i, coord in enumerate(point):
            if coord >= 0:
                octant |= 1 << i
        octants[octant] += 1

    # Each octant should have approximately equal number of points
    expected_per_octant = 1000 / 16
    for count in octants:
        # Allow for some variation (±30%)
        assert expected_per_octant * 0.7 <= count <= expected_per_octant * 1.3


def test_sphere3_thread_safety() -> None:
    """Test that Sphere3 class is thread-safe."""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)
    results = []
    errors = []

    def worker(num_iterations: int) -> None:
        try:
            for _ in range(num_iterations):
                point = sgen.pop()
                results.append(point)
                # Verify point is on unit 3-sphere
                radius_sq = sum(x * x for x in point)
                assert abs(radius_sq - 1.0) < 1e-10
        except Exception as e:
            errors.append(e)

    # Create multiple threads that call pop() concurrently
    threads = []
    num_threads = 8
    iterations_per_thread = 30

    for _ in range(num_threads):
        thread = threading.Thread(target=worker, args=(iterations_per_thread,))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread

    # Verify all results are unique (no duplicates from race conditions)
    result_tuples = [tuple(point) for point in results]
    assert len(set(result_tuples)) == len(result_tuples), (
        "Duplicate values found - possible race condition"
    )


def test_sphere3_concurrent_reseed() -> None:
    """Test that Sphere3 handles concurrent reseed() calls safely."""
    sgen = Sphere3([3, 5, 7])
    results = []
    errors = []

    def worker(seed: int, num_iterations: int) -> None:
        try:
            sgen.reseed(seed)
            for _ in range(num_iterations):
                results.append((seed, sgen.pop()))
        except Exception as e:
            errors.append(e)

    # Create multiple threads that reseed and pop concurrently
    threads = []
    num_threads = 5
    iterations_per_thread = 20

    for i in range(num_threads):
        thread = threading.Thread(target=worker, args=(i * 10, iterations_per_thread))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread


def test_spheren_thread_safety() -> None:
    """Test that SphereN class is thread-safe."""
    # Test with 4-sphere (5D)
    sgen = SphereN([2, 3, 5, 7])
    sgen.reseed(0)
    results = []
    errors = []

    def worker(num_iterations: int) -> None:
        try:
            for _ in range(num_iterations):
                point = sgen.pop()
                results.append(point)
                # Verify point is on unit 4-sphere
                radius_sq = sum(x * x for x in point)
                assert abs(radius_sq - 1.0) < 1e-10
        except Exception as e:
            errors.append(e)

    # Create multiple threads that call pop() concurrently
    threads = []
    num_threads = 6
    iterations_per_thread = 25

    for _ in range(num_threads):
        thread = threading.Thread(target=worker, args=(iterations_per_thread,))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread

    # Verify all results are unique (no duplicates from race conditions)
    result_tuples = [tuple(point) for point in results]
    assert len(set(result_tuples)) == len(result_tuples), (
        "Duplicate values found - possible race condition"
    )


def test_spheren_higher_dimension_thread_safety() -> None:
    """Test SphereN thread safety with higher dimensions."""
    # Test with 6-sphere (7D)
    sgen = SphereN([2, 3, 5, 7, 11, 13])
    sgen.reseed(0)
    results = []
    errors = []

    def worker(num_iterations: int) -> None:
        try:
            for _ in range(num_iterations):
                point = sgen.pop()
                results.append(point)
                # Verify point is on unit 6-sphere
                radius_sq = sum(x * x for x in point)
                assert abs(radius_sq - 1.0) < 1e-10
        except Exception as e:
            errors.append(e)

    # Create multiple threads that call pop() concurrently
    threads = []
    num_threads = 4
    iterations_per_thread = 20

    for _ in range(num_threads):
        thread = threading.Thread(target=worker, args=(iterations_per_thread,))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread

    # Verify all results are unique (no duplicates from race conditions)
    result_tuples = [tuple(point) for point in results]
    assert len(set(result_tuples)) == len(result_tuples), (
        "Duplicate values found - possible race condition"
    )


def test_spheren_concurrent_reseed() -> None:
    """Test that SphereN handles concurrent reseed() calls safely."""
    sgen = SphereN([2, 3, 5, 7])
    results = []
    errors = []

    def worker(seed: int, num_iterations: int) -> None:
        try:
            sgen.reseed(seed)
            for _ in range(num_iterations):
                results.append((seed, sgen.pop()))
        except Exception as e:
            errors.append(e)

    # Create multiple threads that reseed and pop concurrently
    threads = []
    num_threads = 4
    iterations_per_thread = 15

    for i in range(num_threads):
        thread = threading.Thread(target=worker, args=(i * 5, iterations_per_thread))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread


def test_sphere_thread_pool_executor() -> None:
    """Test thread safety using ThreadPoolExecutor."""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)
    results = []

    def worker(num_iterations: int) -> list:
        points = []
        for _ in range(num_iterations):
            point = sgen.pop()
            # Verify point is on unit 3-sphere
            radius_sq = sum(x * x for x in point)
            assert abs(radius_sq - 1.0) < 1e-10
            points.append(point)
        return points

    # Use ThreadPoolExecutor for concurrent execution
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(worker, 25) for _ in range(8)]

        for future in as_completed(futures):
            results.extend(future.result())

    # Verify we got the expected number of results
    assert len(results) == 200  # 8 workers * 25 iterations each

    # Verify all results are unique
    result_tuples = [tuple(point) for point in results]
    assert len(set(result_tuples)) == len(result_tuples), (
        "Duplicate values found - possible race condition"
    )
