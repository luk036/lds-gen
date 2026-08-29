"""
Low-Discrepancy Sequence (LDS) Generator

This code implements a set of low-discrepancy sequence generators, which are used to create
sequences of numbers that are more evenly distributed than random numbers. These sequences are
particularly useful in various fields such as computer graphics, numerical integration, and
Monte Carlo simulations.

The code defines several classes, each representing a different type of low-discrepancy sequence generator.
The main types of sequences implemented are:

1. van der Corput sequence
2. Halton sequence
3. Circle sequence
4. Disk sequence
5. Sphere sequence
6. 3-Sphere Hopf sequence
7. N-dimensional Halton sequence

Each generator takes specific inputs, usually in the form of base numbers or sequences of base numbers.
These bases determine how the sequences are generated. The generators produce outputs in the form of
floating-point numbers or lists of floating-point numbers, depending on the dimensionality of the sequence.

The core algorithm used in most of these generators is the van der Corput sequence. This sequence
is created by expressing integers in a given base, reversing the digits, and placing them after a
decimal point. For example, in base 2, the sequence would start: 1/2, 1/4, 3/4, 1/8, 5/8, and so on.

The Halton sequence extends this concept to multiple dimensions by using a different base for each
dimension. The Circle and Sphere sequences use trigonometric functions to map these
low-discrepancy sequences onto circular or spherical surfaces.

The code also includes utility functions and classes to support these generators. For instance,
there's a list of prime numbers that can be used as bases for the sequences.

Each generator class has methods to produce the next value in the sequence (pop()) and to reset the
sequence to a specific starting point (reseed()). This allows for flexible use of the generators in
various applications.

The purpose of this code is to provide a toolkit for generating well-distributed sequences of
numbers, which can be used in place of random numbers in many applications to achieve more uniform
coverage of a given space or surface. This can lead to more efficient and accurate results in
tasks like sampling, integration, and optimization.
"""

import threading
from functools import cache
from math import cos, pi, sin, sqrt
from typing import Final, Generic, List, Sequence, TypeVar

TWO_PI: Final[float] = 2.0 * pi
"""Constant representing two times pi (2π), used for mapping to full circle angles."""

T = TypeVar("T")


def vdc(count: int, base: int = 2) -> float:
    r"""van der Corput sequence in base :math:`b`.

    Converts an integer to its radical inverse by reversing its base-:math:`b`
    expansion:

    .. math::

       n = \sum_{k=0}^{m} d_k b^k \quad\longrightarrow\quad
       \phi_b(n) = \sum_{k=0}^{m} \frac{d_k}{b^{k+1}}

    where :math:`d_k \in \{0, 1, \dots, b-1\}` are the base-:math:`b` digits
    of :math:`n`. For :math:`b=2` the sequence is
    :math:`\frac12, \frac14, \frac34, \frac18, \frac58, \dots`

    :param count: The integer :math:`n` to convert
    :param base: The base :math:`b` (default 2)
    :return: The radical inverse :math:`\phi_b(n)`

    Examples:
        >>> vdc(11, 2)
        0.8125
    """
    reslt = 0.0
    denom = 1.0
    while count != 0:
        denom *= base
        count, remainder = divmod(count, base)
        if remainder != 0:
            reslt += remainder / denom
    return reslt


class GeneratorBase(Generic[T]):
    """Shared generator protocol.

    Provides the stateful protocol (``pop``/``reseed``), iterator support and
    batch helpers in terms of two hooks supplied by each concrete generator:
    the pure index-to-value computation :meth:`value_at` and the atomic counter
    ``_count`` (guarded by ``_count_lock``).
    """

    _count: int
    _count_lock: threading.Lock

    def pop(self) -> T:
        """Generate the next value in the sequence (advances state).

        Atomically claims the next index under ``_count_lock`` and evaluates
        the pure ``value_at`` computation, so concurrent calls never produce
        duplicate values.

        :return: The next value in the sequence.
        """
        with self._count_lock:
            self._count += 1  # ignore 0
            return self.value_at(self._count)

    def reseed(self, seed: int) -> None:
        """Reset the sequence to a specific starting position.

        :param seed: The starting position for the sequence.
        :type seed: int
        """
        with self._count_lock:
            self._count = seed

    def value_at(self, n: int) -> T:
        """Evaluate the sequence value at index ``n`` (pure, no state change).

        :param n: The sequence index.
        :return: The value at index ``n``.
        :raises NotImplementedError: If the concrete generator does not provide it.
        """
        raise NotImplementedError

    def __iter__(self) -> "GeneratorBase[T]":
        """Return the iterator (self)."""
        return self

    def __next__(self) -> T:
        """Return the next value in the sequence."""
        return self.pop()

    def pop_batch(self, n: int) -> List[T]:
        """Generate a batch of n values.

        :param n: Number of values to generate.
        :type n: int
        :return: List of n values.
        :raises ValueError: If n is not positive.
        """
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        return [self.pop() for _ in range(n)]

    def iter_batch(self, n: int):
        """Generate a batch of n values lazily.

        :param n: Number of values to generate.
        :type n: int
        :raises ValueError: If n is not positive.
        :yields: Values one at a time.
        """
        if n <= 0:
            raise ValueError(f"n must be positive, got {n}")
        for _ in range(n):
            yield self.pop()


class VdCorput(GeneratorBase[float]):
    """van der Corput sequence generator

    `VdCorput` is a class that generates the van der Corput sequence. The van der
    Corput sequence is a low-discrepancy sequence that is commonly used in
    quasi-Monte Carlo methods. The sequence is generated by iterating over a
    base and calculating the fractional part of the number in that base. The
    `VdCorput` class keeps track of the current count and base, and provides a
    `pop()` method that returns the next value in the sequence.

    Examples:
        >>> vgen = VdCorput(2)
        >>> vgen.reseed(0)
        >>> for _ in range(10):
        ...     print(vgen.pop())
        ...
        0.5
        0.25
        0.75
        0.125
        0.625
        0.375
        0.875
        0.0625
        0.5625
        0.3125
    """

    def __init__(self, base: int = 2) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.base: int = base

    def value_at(self, n: int) -> float:
        r"""Evaluate the van der Corput value at index :math:`n` (pure).

        .. math::

           \phi_b(n) = \sum_{k=0}^{m} \frac{d_k}{b^{k+1}}

        where :math:`d_k` are the base-:math:`b` digits of :math:`n`.

        :param n: The sequence index.
        :return: The van der Corput value for index ``n``.

        Examples:
            >>> vgen = VdCorput(2)
            >>> vgen.value_at(1)
            0.5
        """
        return vdc(n, self.base)


class Halton(GeneratorBase[List[float]]):
    """Halton sequence generator

    The `Halton` class is a sequence generator that generates points in a
    2-dimensional space using the Halton sequence. The Halton sequence is a
    low-discrepancy sequence that is often used in quasi-Monte Carlo methods.
    It is generated by iterating over two different bases and calculating the
    fractional parts of the numbers in those bases. The `Halton` class keeps
    track of the current count and bases, and provides a `pop()` method that
    returns the next point in the sequence as a `List[float]`.

    Examples:
        >>> hgen = Halton([2, 3])
        >>> hgen.reseed(0)
        >>> for _ in range(10):
        ...     print(hgen.pop())
        ...
        [0.5, 0.3333333333333333]
        [0.25, 0.6666666666666666]
        [0.75, 0.1111111111111111]
        [0.125, 0.4444444444444444]
        [0.625, 0.7777777777777777]
        [0.375, 0.2222222222222222]
        [0.875, 0.5555555555555556]
        [0.0625, 0.8888888888888888]
        [0.5625, 0.037037037037037035]
        [0.3125, 0.37037037037037035]
    """

    def __init__(self, base: Sequence[int]) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdc0 = VdCorput(base[0])
        self.vdc1 = VdCorput(base[1])

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the 2D Halton point at index :math:`n` (pure).

        .. math::

           H(n) = \bigl(\phi_{b_0}(n),\; \phi_{b_1}(n)\bigr)

        :param n: The sequence index.
        :return: The 2D Halton point for index ``n``.

        Examples:
            >>> hgen = Halton([2, 3])
            >>> hgen.value_at(1)
            [0.5, 0.3333333333333333]
        """
        return [self.vdc0.value_at(n), self.vdc1.value_at(n)]


class Circle(GeneratorBase[List[float]]):
    """Unit Circle sequence generator

    Examples:
        >>> cgen = Circle(2)
        >>> cgen.reseed(0)
        >>> for _ in range(2):
        ...     print(cgen.pop())
        ...
        [-1.0, 1.2246467991473532e-16]
        [6.123233995736766e-17, 1.0]
    """

    def __init__(self, base: int) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdc = VdCorput(base)

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the point on the unit circle at index :math:`n` (pure).

        Maps a van der Corput value :math:`v \in [0,1]` to the unit circle via
        uniform angular sampling:

        .. math::

           \theta = 2\pi v,\qquad
           \mathbf{x} = (\cos\theta,\; \sin\theta)

        :param n: The sequence index.
        :return: The point on the unit circle for index ``n``.

        Examples:
            >>> cgen = Circle(2)
            >>> cgen.value_at(1)
            [-1.0, 1.2246467991473532e-16]
        """
        theta = self.vdc.value_at(n) * TWO_PI  # map to [0, 2π]
        return [cos(theta), sin(theta)]


class Disk(GeneratorBase[List[float]]):
    """Unit Disk sequence generator

    Examples:
        >>> dgen = Disk([2, 3])
        >>> dgen.reseed(0)
        >>> for _ in range(10):
        ...     # Due to floating point inaccuracies, the output may vary slightly
        ...     print(dgen.pop())
        ...
        [-0.5773502691896257, 7.070501591499379e-17]
        [4.9995996217394874e-17, 0.816496580927726]
        [-6.123233995736765e-17, -0.3333333333333333]
        [0.4714045207910317, 0.4714045207910317]
        [-0.6236095644623236, -0.6236095644623234]
        [-0.3333333333333333, 0.33333333333333337]
        [0.5270462766947298, -0.52704627669473]
        [0.871041976584251, 0.36079740009746464]
        [-0.17780069893139236, -0.07364746089679816]
        [-0.23289372032206912, 0.5622551781930658]
    """

    def __init__(self, base: Sequence[int]) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdc0 = VdCorput(base[0])
        self.vdc1 = VdCorput(base[1])

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the point in the unit disk at index :math:`n` (pure).

        Uses a van der Corput value :math:`v_\theta` for the angle and a second
        value :math:`v_r` for the radius, with :math:`r = \sqrt{v_r}` to
        achieve uniform area distribution:

        .. math::

           \begin{aligned}
           \theta &= 2\pi v_\theta \\[4pt]
           r &= \sqrt{v_r} \\[4pt]
           \mathbf{x} &= (r\cos\theta,\; r\sin\theta)
           \end{aligned}

        :param n: The sequence index.
        :return: The point in the unit disk for index ``n``.

        Examples:
            >>> dgen = Disk([2, 3])
            >>> dgen.value_at(1)
            [-0.5773502691896257, 7.070501591499379e-17]
        """
        theta = self.vdc0.value_at(n) * TWO_PI  # map to [0, 2π]
        radius = sqrt(self.vdc1.value_at(n))  # map to [0, 1]
        return [radius * cos(theta), radius * sin(theta)]


class Sphere(GeneratorBase[List[float]]):
    """Unit Sphere sequence generator

    Examples:
        >>> sgen = Sphere([2, 3])
        >>> sgen.reseed(0)
        >>> res = sgen.pop()
        >>> res
        [-0.4999999999999998, 0.8660254037844387, 0.0]
    """

    def __init__(self, base: Sequence[int]) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdcgen = VdCorput(base[0])
        self.cirgen = Circle(base[1])

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the point on the unit sphere :math:`S^2` at index :math:`n` (pure).

        Uses the cylindrical equal-area projection:

        .. math::

           \begin{aligned}
           \phi &= 2v - 1, \qquad v \in [0,1] \\[4pt]
           \mathbf{x} &= \bigl(\sqrt{1-\phi^2}\cos\theta,\;
                                 \sqrt{1-\phi^2}\sin\theta,\; \phi\bigr)
           \end{aligned}

        where :math:`\theta = 2\pi v_\theta` comes from a :class:`Circle`
        generator and :math:`\phi` is mapped uniformly to :math:`[-1,1]`.

        :param n: The sequence index.
        :return: The point on the unit sphere for index ``n``.
        """
        cosphi = 2.0 * self.vdcgen.value_at(n) - 1.0  # map to [-1, 1]
        sinphi = sqrt(1.0 - cosphi * cosphi)  # cylindrical mapping
        [cos, sin] = self.cirgen.value_at(n)
        return [sinphi * cos, sinphi * sin, cosphi]


class Sphere3Hopf(GeneratorBase[List[float]]):
    """Sphere-3 sequence generator using Hopf coordinates

    .. code-block:: bibtex

        @article{yershova2010generating,
          title={Generating uniform incremental grids on SO (3) using the Hopf fibration},
          author={Yershova, Anna and Jain, Swati and LaValle, Steven M and Mitchell, Julie C},
          journal={The International journal of robotics research},
          volume={29},
          number={7},
          pages={801--812},
          year={2010},
          publisher={SAGE Publications}
        }

    Examples:
        >>> sp3hgen = Sphere3Hopf([2, 3, 5])
        >>> sp3hgen.reseed(0)
        >>> result = sp3hgen.pop()
        >>> result
        [-0.22360679774997885, 0.3872983346207417, 0.4472135954999573, -0.7745966692414837]
    """

    def __init__(self, base: Sequence[int]) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdc0 = VdCorput(base[0])
        self.vdc1 = VdCorput(base[1])
        self.vdc2 = VdCorput(base[2])

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the point on :math:`S^3` at index :math:`n` (pure).

        The 3-sphere :math:`S^3` is parameterised by the Hopf fibration:

        .. math::

           \begin{aligned}
           \mathbf{x} = \bigl(&\cos\eta \cos\psi,\;
                               \cos\eta \sin\psi,\;
                               \sin\eta \cos(\phi+\psi),\;
                               \sin\eta \sin(\phi+\psi)\bigr)
           \end{aligned}

        where :math:`\phi,\psi \in [0, 2\pi)` and
        :math:`\eta = \sqrt{v}` with :math:`v \in [0,1]` (stratified
        sampling for uniform measure on :math:`S^3`).

        Reference:
            Yershova et al., *Int. J. Robotics Research*, 29(7), 2010.

        :param n: The sequence index.
        :return: The point on the 3-sphere for index ``n``.

        Examples:
            >>> sp3hgen = Sphere3Hopf([2, 3, 5])
            >>> sp3hgen.value_at(1)
            [-0.22360679774997885, 0.3872983346207417, 0.4472135954999573, -0.7745966692414837]
        """
        phi = self.vdc0.value_at(n) * TWO_PI  # map to [0, 2π]
        psy = self.vdc1.value_at(n) * TWO_PI  # map to [0, 2π]
        vdc = self.vdc2.value_at(n)
        cos_eta = sqrt(vdc)
        sin_eta = sqrt(1.0 - vdc)
        return [
            cos_eta * cos(psy),
            cos_eta * sin(psy),
            sin_eta * cos(phi + psy),
            sin_eta * sin(phi + psy),
        ]


class HaltonN(GeneratorBase[List[float]]):
    """HaltonN sequence generator

    Examples:
        >>> hgen = HaltonN([2, 3, 5])
        >>> hgen.reseed(0)
        >>> for _ in range(2):
        ...     print(hgen.pop())
        ...
        [0.5, 0.3333333333333333, 0.2]
        [0.25, 0.6666666666666666, 0.4]
    """

    vdcs: List[VdCorput]

    def __init__(self, base: Sequence[int]) -> None:
        self._count: int = 0
        self._count_lock = threading.Lock()
        self.vdcs = [VdCorput(b) for b in base]

    def value_at(self, n: int) -> List[float]:
        r"""Evaluate the N-dimensional Halton point at index :math:`n` (pure).

        .. math::

           H(n) = (\phi_{b_1}(n), \phi_{b_2}(n), \dots, \phi_{b_N}(n))

        :param n: The sequence index.
        :return: The N-dimensional Halton point for index ``n``.

        Examples:
            >>> hgen = HaltonN([2, 3, 5])
            >>> hgen.value_at(1)
            [0.5, 0.3333333333333333, 0.2]
        """
        return [vdc.value_at(n) for vdc in self.vdcs]


@cache
def _prime_table(n: int = 1000) -> List[int]:
    """Generate the first ``n`` primes using the Sieve of Eratosthenes."""
    if n < 1:
        return []
    # Upper bound approximation: p_n < n * (log n + log log n) for n >= 6
    from math import log

    limit = 100
    if n >= 6:
        log_n = log(n)
        limit = int(n * (log_n + log(log_n))) + 10
    sieve = bytearray(b"\x01") * (limit + 1)
    sieve[0:2] = b"\x00\x00"
    for p in range(2, int(limit**0.5) + 1):
        if sieve[p]:
            step = p
            start = p * p
            sieve[start : limit + 1 : step] = b"\x00" * ((limit - start) // step + 1)
    return [p for p, is_prime in enumerate(sieve) if is_prime][:n]


PRIME_TABLE: Final[List[int]] = _prime_table()

if __name__ == "__main__":
    import doctest

    doctest.testmod()
