"""Generates points on n-dimensional spheres."""

import bisect
import math
import threading
from functools import cache
from typing import Final, List, Protocol, Union

from lds_gen.lds import Sphere, VdCorput  # low-discrepancy sequence generators

PI: Final[float] = math.pi
HALF_PI: float = PI / 2.0


def linspace(start: float, stop: float, num: int) -> List[float]:
    """Simple implementation of numpy.linspace"""
    if num == 1:
        return [start]
    step = (stop - start) / (num - 1)
    return [start + i * step for i in range(num)]


@cache
def _get_x() -> List[float]:
    return linspace(0.0, PI, 300)


@cache
def _get_neg_cosine() -> List[float]:
    return [-math.cos(x) for x in _get_x()]


@cache
def _get_sine() -> List[float]:
    return [math.sin(x) for x in _get_x()]


@cache
def _get_f2() -> List[float]:
    xv = _get_x()
    nc = _get_neg_cosine()
    s = _get_sine()
    return [(x + nc[i] * s[i]) / 2.0 for i, x in enumerate(xv)]


def simple_interp(x: float, xp: List[float], yp: List[float]) -> float:
    """1D linear interpolation using binary search (C++-style).

    Assumes *xp* is monotonically increasing.  Uses ``bisect_left``
    (equivalent to ``std::ranges::upper_bound``) for O(log n) lookup.

    :param x: Value to interpolate at.
    :param xp: 1-D sequence of x-coordinates (must be sorted).
    :param yp: 1-D sequence of y-coordinates, same length as *xp*.
    :returns: Interpolated value (clamped to endpoints).
    :raises ValueError: If *xp* and *yp* differ in length or are empty.
    """
    if len(xp) != len(yp):
        raise ValueError(
            f"xp and yp must have the same length, got {len(xp)} and {len(yp)}"
        )
    if not xp:
        raise ValueError("xp and yp must be non-empty")
    if x <= xp[0]:
        return yp[0]
    if x >= xp[-1]:
        return yp[-1]
    i = bisect.bisect_left(xp, x) - 1
    t = (x - xp[i]) / (xp[i + 1] - xp[i])
    return yp[i] + t * (yp[i + 1] - yp[i])


@cache
def get_tp(ndim: int) -> List[float]:
    r"""Table of the marginal CDF mapping function :math:`T_n`.

    Uses the iterative shift-register recurrence (same algorithm as the
    C++ implementation):

    .. math::

       T_n(\chi) = \frac{n-1}{n}\,T_{n-2}(\chi) +
                   \frac{\cos\chi\,\sin^{\,n-1}\chi}{n}

    with base cases :math:`T_0(\chi) = \chi` and
    :math:`T_1(\chi) = -\cos\chi`.

    :param ndim: The dimension :math:`n`.
    :returns: ``TABLE_SIZE`` interpolated values of :math:`T_n`.
    """
    if ndim == 0:
        return _get_x()
    if ndim == 1:
        return _get_neg_cosine()

    nc = _get_neg_cosine()
    sine = _get_sine()
    n_pts = len(nc)

    # Tp(n) depends only on Tp(n-2), so we iterate by step 2
    # from the appropriate parity base case.
    if ndim % 2 == 0:
        prev = _get_x()  # Tp(0)
        start = 2
    else:
        prev = _get_neg_cosine()  # Tp(1)
        start = 3

    for i in range(start, ndim + 1, 2):
        current = [
            ((i - 1) * prev[j] + nc[j] * (sine[j] ** (i - 1))) / i for j in range(n_pts)
        ]
        prev = current

    return current


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

    def iter_batch(self, n: int):
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        for _ in range(n):
            yield self.pop()

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
            x_val = simple_interp(theta, _get_f2(), _get_x())
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
                x_val = simple_interp(theta, _get_f2(), _get_x())
                cosxi = math.cos(x_val)
                sinxi = math.sin(x_val)
                return [sinxi * s for s in self.s_gen.pop()] + [cosxi]

            vdc_val = self.vdc.pop()
            tp_val = get_tp(self.n)
            theta = tp_val[0] + self.range * vdc_val  # map to [t0, tm-1]
            x_val = simple_interp(theta, tp_val, _get_x())
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

    def iter_batch(self, n: int):
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        for _ in range(n):
            yield self.pop()


if __name__ == "__main__":
    import doctest

    doctest.testmod()
