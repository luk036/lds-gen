Figures Demo
============

This page demonstrates two ways to include figures in Sphinx docs:
``.. svgbob::`` for ASCII-to-SVG diagrams and ``.. plot::`` for
auto-generated matplotlib figures.

Svgbob diagrams
---------------

The ``.. svgbob::`` directive converts ASCII art into inline SVG
at build time — no image files needed.

Van der Corput digit reversal (base 2):

.. svgbob::
   :align: center

            10 → binary:  1010₂
                                ↕ reverse digits
                               0101₂ = 5
                                    ↕ divide by 2⁴
                                  5/16 = 0.3125

Halton sequence in 2D (bases 2 and 3):

.. svgbob::
   :align: center

         x-axis (base 2):  0.5  0.25  0.75  0.125  ...
         y-axis (base 3):  1/3  2/3  1/9   4/9    ...

         (0.5, 1/3)  →  ●
         (0.25, 2/3) →     ●
         (0.75, 1/9) →          ●
         (0.125, 4/9) →    ●

Mapping a 1D sequence onto a circle:

.. svgbob::
   :align: center

               ● (cos θ, sin θ)
              /|\
             / | \
            /  |  \
           /   |   \
          /    |    \
         /     |     \
        /      |      \
       /       |       \
      /        |        \
     /         |         \
    /          |          \
   /           |           \
  /            |            \
 +-------------+-------------+-->
  \            |            θ=2π⋅φ₂(n)
   \           |           /
    \          |          /
     \         |         /
      \        |        /
       \       |       /
        \      |      /
         \     |     /
          \    |    /
           \   |   /
            \  |  /
             \ | /
              \|/
               ●

Referencing an external script
------------------------------

.. plot:: examples/plot_halton_2d.py

   Halton sequence in bases (2, 3) — 500 points in the unit square.
   Notice the uniform coverage compared to random sampling.

With a 3D projection:

.. plot:: examples/plot_sphere_points.py

The plot inline directive
-------------------------

You can also embed the plotting code directly in the RST file:

.. plot::

   import matplotlib.pyplot as plt
   import numpy as np
   from lds_gen.lds import VdCorput

   vdc = np.array([VdCorput(base=3).pop() for _ in range(100)])
   fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 3))
   ax1.plot(vdc, marker='o', linestyle='-', linewidth=0.5)
   ax1.set_title('VdCorput(base=3) — 100 values')
   ax1.set_ylabel('value')
   ax2.hist(vdc, bins=15, edgecolor='black')
   ax2.set_title('Histogram')
   fig.tight_layout()

Compare Halton vs random scatter:

.. plot::

   import matplotlib.pyplot as plt
   import numpy as np
   from lds_gen.lds import Halton

   rng = np.random.default_rng(42)
   halton = np.array(Halton(base=[2, 3]).pop_batch(256))
   random = rng.uniform(size=(256, 2))

   fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))
   ax1.scatter(halton[:, 0], halton[:, 1], s=8, alpha=0.6)
   ax1.set_title('Halton(2,3) — 256 points')
   ax1.set_aspect('equal')
   ax2.scatter(random[:, 0], random[:, 1], s=8, alpha=0.6)
   ax2.set_title('Random — 256 points')
   ax2.set_aspect('equal')
   fig.tight_layout()

Controlling options
-------------------

Use ``:width:``, ``:alt:``, and ``:align:`` as with any figure:

.. plot:: examples/plot_halton_2d.py
   :width: 50%
   :align: center
   :alt: Halton 2D scatter plot at 50% width
