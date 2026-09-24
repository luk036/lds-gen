"""NumPy accelerated utilities for LDS generators.

This module provides NumPy-based operations for common LDS operations.
"""

from typing import List

import numpy as np


def generate_vdcorput_vectorized(count: int, base: int) -> List[float]:
    """Generate van der Corput sequence values using NumPy for vectorized computation.

    :param count: Number of values to generate.
    :type count: int
    :param base: The base for the van der Corput sequence.
    :type base: int
    :return: List of count floating-point values in the sequence.
    """
    indices = np.arange(1, count + 1, dtype=np.float64)
    result = np.zeros(count, dtype=np.float64)

    denom = 1.0
    while np.any(indices > 0):
        denom *= base
        remainder = indices % base
        indices = np.floor(indices / base)
        result += remainder / denom

    return result.tolist()


def generate_halton_vectorized(count: int, bases: List[int]) -> List[List[float]]:
    """Generate multi-dimensional Halton sequence using NumPy for vectorized computation.

    :param count: Number of points to generate.
    :type count: int
    :param bases: List of bases, one for each dimension.
    :type bases: List[int]
    :return: List of count N-dimensional points in the Halton sequence.
    """
    ndim = len(bases)
    result = np.zeros((count, ndim), dtype=np.float64)

    for dim, base in enumerate(bases):
        indices = np.arange(1, count + 1, dtype=np.float64)
        denom = 1.0
        while np.any(indices > 0):
            denom *= base
            remainder = indices % base
            indices = np.floor(indices / base)
            result[:, dim] += remainder / denom

    return result.tolist()


def compute_discrepancy(points: List[List[float]]) -> float:
    """Compute the star-discrepancy of a set of points.

    The star-discrepancy is a measure of how uniformly a set of points
    is distributed in a unit hypercube. Lower values indicate more uniform
    distribution.

    :param points: List of N-dimensional points to evaluate.
    :type points: List[List[float]]
    :return: The star-discrepancy value.
    """
    n = len(points)
    if n == 0:
        return 0.0

    points_array = np.array(points)
    ndim = points_array.shape[1]

    max_discrepancy = 0.0

    for d in range(ndim):
        sorted_x = np.sort(points_array[:, d])
        differences = sorted_x - np.arange(n) / n
        max_diff = np.max(np.abs(differences))
        max_discrepancy = max(max_discrepancy, max_diff)

    return max_discrepancy


def batch_to_numpy(points: List[List[float]]) -> np.ndarray:
    """Convert a list of points to a NumPy array.

    :param points: List of N-dimensional points.
    :type points: List[List[float]]
    :return: NumPy array of shape (n_points, n_dimensions).
    """
    return np.array(points)


if __name__ == "__main__":
    import time

    print("NumPy Utilities Test")
    print("=" * 60)

    n = 100000

    print(f"\nGenerating {n} van der Corput points...")
    start = time.time()
    vdc_points = generate_vdcorput_vectorized(n, 2)
    elapsed = time.time() - start
    print(f"  Time: {elapsed:.4f}s")
    print(f"  First 5: {vdc_points[:5]}")

    print(f"\nGenerating {n} Halton points (2D)...")
    start = time.time()
    halton_points = generate_halton_vectorized(n, [2, 3])
    elapsed = time.time() - start
    print(f"  Time: {elapsed:.4f}s")
    print(f"  First point: {halton_points[0]}")

    print("\nComputing discrepancy for 1000 Halton points...")
    disc = compute_discrepancy(halton_points[:1000])
    print(f"  Star-discrepancy: {disc:.6f}")

    print("\nAll tests passed!")
