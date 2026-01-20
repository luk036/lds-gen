#!/usr/bin/env python3
"""Visualization script for LDS distribution patterns.

This script generates visual comparisons of different low-discrepancy sequences
to demonstrate their uniform distribution properties.
"""

import random
from typing import List

try:
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d import Axes3D
except ImportError:
    print("This script requires matplotlib. Install with: pip install matplotlib")
    exit(1)

from lds_gen.lds import Circle, Disk, Halton, HaltonN, Sphere, Sphere3Hopf, VdCorput
from lds_gen.sphere_n import Sphere3


def generate_random_points(n: int, dim: int = 2) -> List[List[float]]:
    if dim == 2:
        return [[random.random(), random.random()] for _ in range(n)]
    elif dim == 3:
        return [[random.random(), random.random(), random.random()] for _ in range(n)]
    return []


def plot_1d_comparison():
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    fig.suptitle("1D Distribution Comparison (100 points)", fontsize=14)

    n = 100

    vdc2 = VdCorput(base=2)
    points2 = [vdc2.pop() for _ in range(n)]
    axes[0, 0].scatter(range(n), points2, alpha=0.6, s=30)
    axes[0, 0].set_title("Van der Corput (base=2)")
    axes[0, 0].set_xlabel("Sequence Index")
    axes[0, 0].set_ylabel("Value")

    vdc3 = VdCorput(base=3)
    points3 = [vdc3.pop() for _ in range(n)]
    axes[0, 1].scatter(range(n), points3, alpha=0.6, s=30, color="orange")
    axes[0, 1].set_title("Van der Corput (base=3)")
    axes[0, 1].set_xlabel("Sequence Index")
    axes[0, 1].set_ylabel("Value")

    random_points = [random.random() for _ in range(n)]
    axes[1, 0].scatter(range(n), random_points, alpha=0.6, s=30, color="green")
    axes[1, 0].set_title("Random (Uniform)")
    axes[1, 0].set_xlabel("Sequence Index")
    axes[1, 0].set_ylabel("Value")

    axes[1, 1].hist(
        points2, bins=20, alpha=0.5, label="VdCorput (base=2)", color="blue"
    )
    axes[1, 1].hist(random_points, bins=20, alpha=0.5, label="Random", color="green")
    axes[1, 1].set_title("Distribution Histogram")
    axes[1, 1].set_xlabel("Value Bins")
    axes[1, 1].set_ylabel("Frequency")
    axes[1, 1].legend()

    plt.tight_layout()
    plt.savefig("visualizations_1d.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: visualizations_1d.png")


def plot_2d_comparison():
    fig, axes = plt.subplots(2, 2, figsize=(12, 12))
    fig.suptitle("2D Distribution Comparison (500 points)", fontsize=14)

    n = 500

    halton = Halton(base=[2, 3])
    points_halton = [halton.pop() for _ in range(n)]
    x = [p[0] for p in points_halton]
    y = [p[1] for p in points_halton]
    axes[0, 0].scatter(x, y, alpha=0.6, s=20)
    axes[0, 0].set_title("Halton (base=[2,3])")
    axes[0, 0].set_xlabel("X")
    axes[0, 0].set_ylabel("Y")
    axes[0, 0].set_xlim(0, 1)
    axes[0, 0].set_ylim(0, 1)
    axes[0, 0].grid(True, alpha=0.3)

    random_points = generate_random_points(n, 2)
    x_rand = [p[0] for p in random_points]
    y_rand = [p[1] for p in random_points]
    axes[0, 1].scatter(x_rand, y_rand, alpha=0.6, s=20, color="green")
    axes[0, 1].set_title("Random (Uniform)")
    axes[0, 1].set_xlabel("X")
    axes[0, 1].set_ylabel("Y")
    axes[0, 1].set_xlim(0, 1)
    axes[0, 1].set_ylim(0, 1)
    axes[0, 1].grid(True, alpha=0.3)

    circle = Circle(base=2)
    points_circle = [circle.pop() for _ in range(n)]
    x_c = [p[0] for p in points_circle]
    y_c = [p[1] for p in points_circle]
    axes[1, 0].scatter(x_c, y_c, alpha=0.6, s=20, color="orange")
    axes[1, 0].set_title("Circle (base=2)")
    axes[1, 0].set_xlabel("X")
    axes[1, 0].set_ylabel("Y")
    axes[1, 0].set_aspect("equal")
    axes[1, 0].grid(True, alpha=0.3)

    disk = Disk(base=[2, 3])
    points_disk = [disk.pop() for _ in range(n)]
    x_d = [p[0] for p in points_disk]
    y_d = [p[1] for p in points_disk]
    axes[1, 1].scatter(x_d, y_d, alpha=0.6, s=20, color="purple")
    axes[1, 1].set_title("Disk (base=[2,3])")
    axes[1, 1].set_xlabel("X")
    axes[1, 1].set_ylabel("Y")
    axes[1, 1].set_aspect("equal")
    axes[1, 1].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("visualizations_2d.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: visualizations_2d.png")


def plot_3d_comparison():
    fig = plt.figure(figsize=(15, 5))

    n = 500

    ax1 = fig.add_subplot(131, projection="3d")
    halton3d = HaltonN(base=[2, 3, 5])
    points_h3d = [halton3d.pop() for _ in range(n)]
    x_h = [p[0] for p in points_h3d]
    y_h = [p[1] for p in points_h3d]
    z_h = [p[2] for p in points_h3d]
    ax1.scatter(x_h, y_h, z_h, alpha=0.6, s=20)
    ax1.set_title("Halton 3D (base=[2,3,5])")
    ax1.set_xlabel("X")
    ax1.set_ylabel("Y")
    ax1.set_zlabel("Z")

    ax2 = fig.add_subplot(132, projection="3d")
    sphere = Sphere(base=[2, 3])
    points_sphere = [sphere.pop() for _ in range(n)]
    x_s = [p[0] for p in points_sphere]
    y_s = [p[1] for p in points_sphere]
    z_s = [p[2] for p in points_sphere]
    ax2.scatter(x_s, y_s, z_s, alpha=0.6, s=20, color="orange")
    ax2.set_title("Sphere 3D (base=[2,3])")
    ax2.set_xlabel("X")
    ax2.set_ylabel("Y")
    ax2.set_zlabel("Z")

    ax3 = fig.add_subplot(133, projection="3d")
    random_points = generate_random_points(n, 3)
    x_r = [p[0] for p in random_points]
    y_r = [p[1] for p in random_points]
    z_r = [p[2] for p in random_points]
    ax3.scatter(x_r, y_r, z_r, alpha=0.6, s=20, color="green")
    ax3.set_title("Random 3D")
    ax3.set_xlabel("X")
    ax3.set_ylabel("Y")
    ax3.set_zlabel("Z")

    plt.tight_layout()
    plt.savefig("visualizations_3d.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: visualizations_3d.png")


def plot_sphere_comparison():
    fig = plt.figure(figsize=(15, 5))

    n = 500

    ax1 = fig.add_subplot(131, projection="3d")
    sphere = Sphere(base=[2, 3])
    points_s = [sphere.pop() for _ in range(n)]
    x_s = [p[0] for p in points_s]
    y_s = [p[1] for p in points_s]
    z_s = [p[2] for p in points_s]
    ax1.scatter(x_s, y_s, z_s, alpha=0.6, s=20)
    ax1.set_title("Sphere (base=[2,3])")
    ax1.set_xlabel("X")
    ax1.set_ylabel("Y")
    ax1.set_zlabel("Z")

    ax2 = fig.add_subplot(132, projection="3d")
    sphere3 = Sphere3(base=[2, 3, 5])
    points_s3 = [sphere3.pop() for _ in range(n)]
    x_s3 = [p[0] for p in points_s3]
    y_s3 = [p[1] for p in points_s3]
    z_s3 = [p[2] for p in points_s3]
    ax2.scatter(x_s3, y_s3, z_s3, alpha=0.6, s=20, color="orange")
    ax2.set_title("Sphere3 (base=[2,3,5])")
    ax2.set_xlabel("X")
    ax2.set_ylabel("Y")
    ax2.set_zlabel("Z")

    ax3 = fig.add_subplot(133, projection="3d")
    sphere3h = Sphere3Hopf(base=[2, 3, 5])
    points_s3h = [sphere3h.pop() for _ in range(n)]
    x_s3h = [p[0] for p in points_s3h]
    y_s3h = [p[1] for p in points_s3h]
    z_s3h = [p[2] for p in points_s3h]
    ax3.scatter(x_s3h, y_s3h, z_s3h, alpha=0.6, s=20, color="purple")
    ax3.set_title("Sphere3Hopf (base=[2,3,5])")
    ax3.set_xlabel("X")
    ax3.set_ylabel("Y")
    ax3.set_zlabel("Z")

    plt.tight_layout()
    plt.savefig("visualizations_sphere.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: visualizations_sphere.png")


def plot_coverage_analysis():
    fig, axes = plt.subplots(2, 2, figsize=(12, 12))
    fig.suptitle("Coverage Analysis (1000 points, 10x10 grid)", fontsize=14)

    n = 1000
    grid_size = 10

    halton = Halton(base=[2, 3])
    points_halton = [halton.pop() for _ in range(n)]
    x = [p[0] for p in points_halton]
    y = [p[1] for p in points_halton]
    axes[0, 0].scatter(x, y, alpha=0.4, s=10)
    axes[0, 0].set_title("Halton (base=[2,3])")
    axes[0, 0].set_xlabel("X")
    axes[0, 0].set_ylabel("Y")
    for i in range(grid_size + 1):
        axes[0, 0].axhline(i / grid_size, color="gray", alpha=0.3, linewidth=0.5)
        axes[0, 0].axvline(i / grid_size, color="gray", alpha=0.3, linewidth=0.5)

    random_points = generate_random_points(n, 2)
    x_rand = [p[0] for p in random_points]
    y_rand = [p[1] for p in random_points]
    axes[0, 1].scatter(x_rand, y_rand, alpha=0.4, s=10, color="green")
    axes[0, 1].set_title("Random")
    axes[0, 1].set_xlabel("X")
    axes[0, 1].set_ylabel("Y")
    for i in range(grid_size + 1):
        axes[0, 1].axhline(i / grid_size, color="gray", alpha=0.3, linewidth=0.5)
        axes[0, 1].axvline(i / grid_size, color="gray", alpha=0.3, linewidth=0.5)

    def count_in_grid(points, grid_size):
        counts = [[0 for _ in range(grid_size)] for _ in range(grid_size)]
        for px, py in points:
            gx = int(px * grid_size)
            gy = int(py * grid_size)
            if 0 <= gx < grid_size and 0 <= gy < grid_size:
                counts[gy][gx] += 1
        return counts

    halton_counts = count_in_grid(points_halton, grid_size)
    random_counts = count_in_grid(random_points, grid_size)

    im1 = axes[1, 0].imshow(halton_counts, cmap="YlOrRd", origin="lower")
    axes[1, 0].set_title("Halton Grid Counts")
    axes[1, 0].set_xlabel("X Grid")
    axes[1, 0].set_ylabel("Y Grid")
    plt.colorbar(im1, ax=axes[1, 0])

    im2 = axes[1, 1].imshow(random_counts, cmap="YlOrRd", origin="lower")
    axes[1, 1].set_title("Random Grid Counts")
    axes[1, 1].set_xlabel("X Grid")
    axes[1, 1].set_ylabel("Y Grid")
    plt.colorbar(im2, ax=axes[1, 1])

    plt.tight_layout()
    plt.savefig("visualizations_coverage.png", dpi=150, bbox_inches="tight")
    plt.close()
    print("Saved: visualizations_coverage.png")


def main():
    print("Generating LDS visualization plots...")
    print("=" * 60)

    plot_1d_comparison()
    plot_2d_comparison()
    plot_3d_comparison()
    plot_sphere_comparison()
    plot_coverage_analysis()

    print("=" * 60)
    print("All visualizations saved successfully!")
    print("\nGenerated files:")
    print("  - visualizations_1d.png")
    print("  - visualizations_2d.png")
    print("  - visualizations_3d.png")
    print("  - visualizations_sphere.png")
    print("  - visualizations_coverage.png")


if __name__ == "__main__":
    main()
