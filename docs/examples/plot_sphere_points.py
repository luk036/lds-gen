"""
Points on a sphere
==================

200 points on the unit sphere surface using the Sphere generator.
"""
import matplotlib.pyplot as plt
import numpy as np

from lds_gen.lds import Sphere

pts = np.array(Sphere(base=[2, 3]).pop_batch(200))

fig = plt.figure(figsize=(7, 7))
ax = fig.add_subplot(111, projection="3d")
ax.scatter(pts[:, 0], pts[:, 1], pts[:, 2], s=15, alpha=0.8)
ax.set_box_aspect([1, 1, 1])
ax.set_title("Sphere(2,3) — 200 points on the unit sphere")
