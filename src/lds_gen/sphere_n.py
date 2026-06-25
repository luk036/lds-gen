"""Generates points on n-dimensional spheres."""

import math
import threading
from functools import cache
from typing import Final, List, Protocol, Union

from lds_gen.lds import Sphere, VdCorput  # low-discrepancy sequence generators

PI: Final[float] = math.pi


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
HALF_PI: float = PI / 2.0


def simple_interp(x: float, xp: List[float], yp: List[float]) -> float:
    """Simple implementation of numpy.interp for 1D interpolation"""
    if x <= xp[0]:
        return yp[0]
    if x >= xp[-1]:
        return yp[-1]

    for i in range(len(xp) - 1):
        if xp[i] <= x <= xp[i + 1]:
            t_val = (x - xp[i]) / (xp[i + 1] - xp[i])
            return yp[i] + t_val * (yp[i + 1] - yp[i])

    return yp[-1]  # fallback


@cache
def get_tp_odd(ndim: int) -> List[float]:
    r"""Recursively compute the marginal CDF table for odd-dimensional spheres.

    The mapping function :math:`T_n(\theta)` satisfies the recurrence:

    .. math::

       T_n(\theta) = \frac{n-1}{n}\,T_{n-2}(\theta) +
                     \frac{\cos\theta\,\sin^{n-1}\theta}{n}

    with base case :math:`T_1(\theta) = -\cos\theta`.

    Args:
        ndim (int): The dimension :math:`n` (odd).

    Returns:
        List[float]: The lookup table of :math:`T_n`.
    """
    if ndim == 1:
        return NEG_COSINE
    tp_minus2 = get_tp_odd(ndim - 2)
    return [
        ((ndim - 1) * tp_minus2[i] + NEG_COSINE[i] * (SINE[i] ** (ndim - 1))) / ndim
        for i in range(len(tp_minus2))
    ]


@cache
def get_tp_even(ndim: int) -> List[float]:
    r"""Recursively compute the marginal CDF table for even-dimensional spheres.

    Same recurrence as :func:`get_tp_odd` with base case
    :math:`T_0(\theta) = \theta`.

    .. math::

       T_n(\theta) = \frac{n-1}{n}\,T_{n-2}(\theta) +
                     \frac{\cos\theta\,\sin^{n-1}\theta}{n}

    Args:
        ndim (int): The dimension :math:`n` (even).

    Returns:
        List[float]: The lookup table of :math:`T_n`.
    """
    if ndim == 0:
        return X
    tp_minus2 = get_tp_even(ndim - 2)
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
    return get_tp_odd(ndim) if ndim & 1 else get_tp_even(ndim)


class SphereGen(Protocol):
    """Protocol defining the interface for sphere sequence generators.

    This protocol specifies the required methods that any sphere generator
    implementation must provide: pop() to get the next point and reseed()
    to reset the sequence to a specific starting position.
    """

    def pop(self) -> List[float]:
        """Generate the next point on the sphere.

        :return: List of floats representing a point on the sphere.
        """

    def reseed(self, seed: int) -> None:
        """Reset the sequence to a specific starting position.

        :param seed: The starting position for the sequence.
        """


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
        """Initialize the 3-sphere sequence generator.

        :param base: List of 3 integers specifying bases for the van der Corput
                     sequence and the 2-sphere generator.
        :type base: List[int]
        """
        self.vdc = VdCorput(base[0])
        self.sphere2 = Sphere(base[1:3])
        self._lock = threading.Lock()

    def reseed(self, seed: int) -> None:
        """Reset the sequence to a specific starting position.

        :param seed: The starting position for the sequence.
        :type seed: int
        """
        with self._lock:
            self.vdc.reseed(seed)
            self.sphere2.reseed(seed)

    def __iter__(self) -> "Sphere3":
        """Return iterator for the 3-sphere sequence generator.

        :return: Self as the iterator.
        """
        return self

    def __next__(self) -> List[float]:
        """Return the next point on the 3-sphere.

        :return: Next 4D point on the 3-sphere.
        """
        return self.pop()

    def pop_batch(self, n: int) -> List[List[float]]:
        """Generate a batch of n points on the 3-sphere.

        :param n: Number of points to generate.
        :type n: int
        :return: List of n 4D points on the 3-sphere.
        :raises ValueError: If n is not positive.
        """
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        return [self.pop() for _ in range(n)]

    def pop(self) -> List[float]:
        r"""Next point on :math:`S^3` using the covariance-mapping technique.

        The polar angle :math:`\chi` is obtained by interpolating the inverse
        cumulative distribution function (precomputed in :data:`F2`):

        .. math::

           \begin{aligned}
           \theta &= \frac{\pi}{2}\,v \\[4pt]
           \chi &= F_2^{-1}(\theta) \\[4pt]
           \mathbf{x} &= (\sin\chi \cdot \mathbf{s},\; \cos\chi)
           \end{aligned}

        where :math:`\mathbf{s} \in S^2` is a uniform point on the 2-sphere
        and :math:`F_2(\chi)` is the marginal CDF for dimension 2.

        :return: Next 4D point on the 3-sphere surface.
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
        r"""Next point uniformly distributed on :math:`S^{n-1}`.

        Uses the recursive covariance-mapping technique. The polar angle
        :math:`\chi` is obtained by inverting the precomputed marginal CDF
        :math:`T_n`:

        .. math::

           \begin{aligned}
           \theta &= T_n(0) + \bigl(T_n(\pi) - T_n(0)\bigr) v,\qquad
           v \in [0,1] \\[4pt]
           \chi &= T_n^{-1}(\theta) \\[4pt]
           \mathbf{x} &= (\sin\chi \cdot \mathbf{s}_{n-2},\; \cos\chi)
           \end{aligned}

        where :math:`\mathbf{s}_{n-2} \in S^{n-2}` is generated recursively
        and the CDF recurrence is:

        .. math::

           T_n(\chi) = \frac{n-1}{n}\,T_{n-2}(\chi) +
                       \frac{\cos\chi\,\sin^{\,n-1}\chi}{n}

        Returns:
            List[float]: A new point on the :math:`n`-sphere.
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
        """Reset the sequence to a specific starting position.

        :param seed: The starting position for the sequence.
        :type seed: int
        """
        with self._lock:
            self.vdc.reseed(seed)
            self.s_gen.reseed(seed)

    def __iter__(self) -> "SphereN":
        """Return iterator for the N-sphere sequence generator.

        :return: Self as the iterator.
        """
        return self

    def __next__(self) -> List[float]:
        """Return the next point on the N-sphere.

        :return: Next N-dimensional point on the N-sphere surface.
        """
        return self.pop()

    def pop_batch(self, n: int) -> List[List[float]]:
        """Generate a batch of n points on the N-sphere.

        :param n: Number of points to generate.
        :type n: int
        :return: List of n N-dimensional points on the N-sphere.
        :raises ValueError: If n is not positive.
        """
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        return [self.pop() for _ in range(n)]


if __name__ == "__main__":
    import doctest

    doctest.testmod()
