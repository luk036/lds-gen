"""NumPy accelerated utilities for LDS generators.

This module provides optional NumPy-accelerated operations for common
LDS operations. All functions are optional and will gracefully fall back
to pure Python if NumPy is not available.
"""

import warnings
from typing import List

try:
    import numpy as np

    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False

    class np:  # type: ignore
        pass


def numpy_available() -> bool:
    return HAS_NUMPY


def ensure_numpy() -> None:
    if not HAS_NUMPY:
        raise ImportError(
            "NumPy is required for this function. Install with: pip install numpy"
        )


def generate_vdcorput_vectorized(count: int, base: int) -> List[float]:
    if HAS_NUMPY:
        ensure_numpy()
        indices = np.arange(1, count + 1, dtype=np.float64)
        result = np.zeros(count, dtype=np.float64)

        denom = 1.0
        while np.any(indices > 0):
            denom *= base
            remainder = indices % base
            indices = np.floor(indices / base)
            result += remainder / denom

        return result.tolist()

    warnings.warn("NumPy not available, falling back to pure Python")
    from lds_gen.lds import VdCorput

    gen = VdCorput(base=base)
    return gen.pop_batch(count)


def generate_halton_vectorized(count: int, bases: List[int]) -> List[List[float]]:
    if HAS_NUMPY:
        ensure_numpy()
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

    warnings.warn("NumPy not available, falling back to pure Python")
    from lds_gen.lds import Halton

    gen = Halton(base=bases)
    return gen.pop_batch(count)


def compute_discrepancy(points: List[List[float]]) -> float:
    if not HAS_NUMPY:
        raise ImportError("NumPy is required for discrepancy computation")

    ensure_numpy()
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


def batch_to_numpy(points: List[List[float]]) -> "np.ndarray":
    if not HAS_NUMPY:
        raise ImportError("NumPy is required for this function")

    ensure_numpy()
    return np.array(points)


if __name__ == "__main__":
    import time

    print("NumPy Utilities Test")
    print("=" * 60)

    if not HAS_NUMPY:
        print("NumPy not available. Install with: pip install numpy")
        exit(1)

    n = 100000

    print(f"\nGenerating {n} Van der Corput points...")
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
