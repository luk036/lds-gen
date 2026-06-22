"""
Halton sequence in 2D
=====================

500 points of a Halton sequence in bases (2, 3) plotted in the unit square.
"""
import matplotlib.pyplot as plt
import numpy as np

from lds_gen.lds import Halton

pts = np.array(Halton(base=[2, 3]).pop_batch(500))
plt.figure(figsize=(6, 6))
plt.scatter(pts[:, 0], pts[:, 1], s=10, alpha=0.7)
plt.xlim(0, 1)
plt.ylim(0, 1)
plt.gca().set_aspect("equal")
plt.title("Halton(2,3) — 500 points")
