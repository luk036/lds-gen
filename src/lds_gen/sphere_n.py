r"""Generates points on n-dimensional spheres.

.. svgbob::
   :align: center

   +-----------------------+
   |        Sphere         |
   |      O---------> x    |
   |     /|                |
   |    / |                |
   |   /  |                |
   |  /   |                |
   | O----+-----> y        |
   |  \\  |                 |
   |   \\ |                 |
   |    \\|                 |
   |     * z               |
   +-----------------------+

Algorithm Overview:

.. svgbob::
   :align: center

          VdCorput Sequence
                 |
                 v
   [0,1] ------------------> [0,\u03c0] -----> Sphere(n)
                    Mapping      Interpolation

"""

import math
import threading
from abc import ABC, abstractmethod
from functools import cache
from typing import List, Union


from lds_gen.lds import Sphere, VdCorput  # low-discrepancy sequence generators

PI: float = math.pi


def linspace(start: float, stop: float, num: int) -> List[float]:
    """Simple implementation of numpy.linspace"""
    if num == 1:
        return [start]
    step = (stop - start) / (num - 1)
    return [start + i * step for i in range(num)]


X: List[float] = linspace(0.0, PI, 300)
NEG_COSINE: List[float] = [-math.cos(x) for x in X]
SINE: List[float] = [math.sin(x) for x in X]
F2: List[float] = [(x + nc * s) / 2.0 for x, nc, s in zip(X, NEG_COSINE, SINE)]
HALF_PI = PI / 2.0


def simple_interp(x: float, xp: List[float], yp: List[float]) -> float:
    """Simple implementation of numpy.interp for 1D interpolation"""
    if x <= xp[0]:
        return yp[0]
    if x >= xp[-1]:
        return yp[-1]

    for i in range(len(xp) - 1):
        if xp[i] <= x <= xp[i + 1]:
            # Linear interpolation
            t_val = (x - xp[i]) / (xp[i + 1] - xp[i])
            return yp[i] + t_val * (yp[i + 1] - yp[i])

    return yp[-1]  # fallback


@cache
def get_tp_recursive(ndim: int) -> List[float]:
    """Recursively calculates the table-lookup of the mapping function for n.

    Args:
        ndim (int): The dimension.

    Returns:
        List[float]: The table-lookup of the mapping function.
    """
    if ndim == 0:
        return X
    if ndim == 1:
        return NEG_COSINE
    tp_minus2 = get_tp_recursive(ndim - 2)
    return [
        ((ndim - 1) * tp_minus2[i] + NEG_COSINE[i] * (SINE[i] ** (ndim - 1))) / ndim
        for i in range(len(tp_minus2))
    ]


def get_tp(ndim: int) -> List[float]:
    """Calculates the table-lookup of the mapping function for n.

    Args:
        ndim (int): The dimension.

    Returns:
        List[float]: The table-lookup of the mapping function.
    """
    return get_tp_recursive(ndim)


class SphereGen(ABC):
    """Base class for sphere generators."""

    @abstractmethod
    def pop(self) -> List[float]:
        """Generates and returns a vector of values."""
        raise NotImplementedError

    @abstractmethod
    def reseed(self, seed: int) -> None:
        """Reseeds the generator with a new seed."""
        raise NotImplementedError


class Sphere3(SphereGen):
    """3-Sphere sequence generator

    Examples:
        >>> sgen = Sphere3([2, 3, 5])
        >>> sgen.reseed(0)
        >>> for _ in range(1):
        ...     print(sgen.pop())
        ...
        [0.2913440162992141, 0.8966646826186098, -0.33333333333333337, 6.123233995736766e-17]
    """

    vdc: VdCorput  # van der Corput sequence generator
    sphere2: Sphere  # 2-Sphere generator

    def __init__(self, base: List[int]) -> None:
        """_summary_

        Args:
            base (List[int]): _description_
        """
        self.vdc = VdCorput(base[0])
        self.sphere2 = Sphere(base[1:3])
        self._lock = threading.Lock()

    def reseed(self, seed: int) -> None:
        """_summary_

        Args:
            seed (int): _description_
        """
        with self._lock:
            self.vdc.reseed(seed)
            self.sphere2.reseed(seed)

    def pop(self) -> List[float]:
        """_summary_

        Returns:
            List[float]: _description_
        """
        with self._lock:
            theta = HALF_PI * self.vdc.pop()  # map to [t0, tm-1]
            x_val = simple_interp(theta, F2, X)
            cosxi = math.cos(x_val)
            sinxi = math.sin(x_val)
            return [sinxi * s for s in self.sphere2.pop()] + [cosxi]


class SphereN(SphereGen):
    """Sphere-N sequence generator.

    Examples:
        >>> sgen = SphereN([2, 3, 5, 7])
        >>> sgen.reseed(0)
        >>> for _ in range(1):
        ...     print(sgen.pop())
        ...
        [0.4809684718990214, 0.6031153874276115, -0.5785601510223212, 0.2649326520763179, 6.123233995736766e-17]
    """

    s_gen: Union[Sphere, "SphereN"]

    def __init__(self, base: List[int]) -> None:
        """Initializes the n-sphere generator.

        Args:
            base (List[int]): The base for the van der Corput sequence.
        """
        ndim = len(base) - 1
        assert ndim >= 2
        self.vdc = VdCorput(base[0])
        if ndim == 2:
            self.s_gen = Sphere(base[1:3])
        else:
            self.s_gen = SphereN(base[1:])
        self.n = ndim
        tp_val = get_tp(ndim)
        self.range = tp_val[-1] - tp_val[0]
        self._lock = threading.Lock()

    def pop(self) -> List[float]:
        """Generates a new point on the n-sphere.

        Returns:
            List[float]: A new point on the n-sphere.
        """
        with self._lock:
            if self.n == 2:
                theta = HALF_PI * self.vdc.pop()  # map to [t0, tm-1]
                x_val = simple_interp(theta, F2, X)
                cosxi = math.cos(x_val)
                sinxi = math.sin(x_val)
                return [sinxi * s for s in self.s_gen.pop()] + [cosxi]

            vdc_val = self.vdc.pop()
            tp_val = get_tp(self.n)
            theta = tp_val[0] + self.range * vdc_val  # map to [t0, tm-1]
            x_val = simple_interp(theta, tp_val, X)
            sinphi = math.sin(x_val)
            return [x_val * sinphi for x_val in self.s_gen.pop()] + [math.cos(x_val)]

    def reseed(self, seed: int) -> None:
        """Reseeds the generator.

        Args:
            seed (int): The new seed.
        """
        with self._lock:
            self.vdc.reseed(seed)
            self.s_gen.reseed(seed)


if __name__ == "__main__":
    import doctest

    doctest.testmod()
