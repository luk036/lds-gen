#!/usr/bin/env python3
"""Performance benchmarks for lds-gen generators.

This script benchmarks the performance of different LDS generators
and compares them across various configurations.
"""

import time
from statistics import mean, stdev
from typing import Callable, List

from lds_gen.ilds import Halton as HaltonI
from lds_gen.ilds import VdCorput as VdCorputI
from lds_gen.lds import Circle, Disk, Halton, HaltonN, Sphere, Sphere3Hopf, VdCorput
from lds_gen.sphere_n import Sphere3, SphereN


def benchmark(generator_func: Callable, n: int, name: str, warmup: int = 100) -> float:
    gen = generator_func()

    for _ in range(warmup):
        gen.pop()

    gen = generator_func()
    times: List[float] = []

    for _ in range(n):
        start = time.perf_counter()
        gen.pop()
        end = time.perf_counter()
        times.append((end - start) * 1e6)

    avg_time = mean(times)
    std_dev = stdev(times) if len(times) > 1 else 0.0

    print(f"{name:30s}: {avg_time:8.2f} ± {std_dev:6.2f} μs")

    return avg_time


def benchmark_batch(
    generator_func: Callable, batch_size: int, n: int, name: str
) -> float:
    gen = generator_func()
    times: List[float] = []

    for _ in range(n):
        start = time.perf_counter()
        gen.pop_batch(batch_size)
        end = time.perf_counter()
        times.append((end - start) * 1e6 / batch_size)

    avg_time = mean(times)
    std_dev = stdev(times) if len(times) > 1 else 0.0

    print(f"{name:30s}: {avg_time:8.2f} ± {std_dev:6.2f} μs/point")

    return avg_time


def main():
    print("=" * 70)
    print("LDS-GEN Performance Benchmarks")
    print("=" * 70)

    n_iterations = 10000

    print("\n1. Single Point Generation (10,000 iterations)")
    print("-" * 70)

    benchmark(lambda: VdCorput(base=2), n_iterations, "VdCorput (base=2)")
    benchmark(lambda: VdCorput(base=3), n_iterations, "VdCorput (base=3)")
    benchmark(lambda: VdCorput(base=5), n_iterations, "VdCorput (base=5)")

    benchmark(lambda: Halton(base=[2, 3]), n_iterations, "Halton (2D, base=[2,3])")
    benchmark(lambda: Halton(base=[2, 5]), n_iterations, "Halton (2D, base=[2,5])")
    benchmark(lambda: HaltonN(base=[2, 3, 5]), n_iterations, "HaltonN (3D)")

    benchmark(lambda: Circle(base=2), n_iterations, "Circle")
    benchmark(lambda: Disk(base=[2, 3]), n_iterations, "Disk")
    benchmark(lambda: Sphere(base=[2, 3]), n_iterations, "Sphere")

    print("\n2. Integer Variants (10,000 iterations)")
    print("-" * 70)

    benchmark(
        lambda: VdCorputI(base=2, scale=10),
        n_iterations,
        "VdCorputI (base=2, scale=10)",
    )
    benchmark(
        lambda: HaltonI(base=[2, 3], scale=[10, 10]),
        n_iterations,
        "HaltonI (2D, scale=10)",
    )

    print("\n3. Higher Dimensional Spheres (10,000 iterations)")
    print("-" * 70)

    benchmark(lambda: Sphere3Hopf(base=[2, 3, 5]), n_iterations, "Sphere3Hopf (4D)")
    benchmark(lambda: Sphere3(base=[2, 3, 5]), n_iterations, "Sphere3 (4D)")
    benchmark(lambda: SphereN(base=[2, 3, 5, 7]), n_iterations, "SphereN (5D)")
    benchmark(lambda: SphereN(base=[2, 3, 5, 7, 11]), n_iterations, "SphereN (6D)")

    print("\n4. Batch Generation (10 batches of 1000 points each)")
    print("-" * 70)

    benchmark_batch(lambda: VdCorput(base=2), 1000, 10, "VdCorput (batch)")
    benchmark_batch(lambda: Halton(base=[2, 3]), 1000, 10, "Halton (batch)")
    benchmark_batch(lambda: Sphere(base=[2, 3]), 1000, 10, "Sphere (batch)")
    benchmark_batch(lambda: HaltonN(base=[2, 3, 5]), 1000, 10, "HaltonN (batch)")

    print("\n5. Base Comparison (Van der Corput, 10,000 iterations)")
    print("-" * 70)

    base_times = {}
    for base in [2, 3, 5, 7, 11, 13, 17, 19]:
        t = benchmark(lambda b=base: VdCorput(base=b), n_iterations, f"Base {base:2d}")
        base_times[base] = t

    print("\nBase Performance Summary:")
    print("-" * 70)
    for base, t in sorted(base_times.items()):
        print(f"  Base {base:2d}: {t:8.2f} μs")

    print("\n6. Dimension Scaling (Halton, 10,000 iterations)")
    print("-" * 70)

    dim_times = {}
    dims = [2, 3, 5, 7, 10]
    bases_list = [
        [2, 3],
        [2, 3, 5],
        [2, 3, 5, 7],
        [2, 3, 5, 7, 11],
        [2, 3, 5, 7, 11, 13, 17, 19, 23, 29],
    ]

    for dim, bases in zip(dims, bases_list):
        t = benchmark(lambda b=bases: HaltonN(base=b), n_iterations, f"{dim}D")
        dim_times[dim] = t

    print("\nDimension Performance Summary:")
    print("-" * 70)
    for dim, t in sorted(dim_times.items()):
        print(f"  {dim:2d}D: {t:8.2f} μs")

    print("\n" + "=" * 70)
    print("Benchmarks complete!")
    print("=" * 70)


if __name__ == "__main__":
    main()
