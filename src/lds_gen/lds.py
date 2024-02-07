"""
This module contains low-discrepancy sequence generators
"""

from math import cos, pi, sin, sqrt
from typing import List, Sequence

TWO_PI = 2.0 * pi


def vdc(k: int, base: int = 2) -> float:
    """Van der Corput sequence

    The function `vdc` converts a given number `k` from base `base` to a floating point number.

    :param k: The parameter `k` represents the number for which we want to calculate the van der Corput
              sequence value

    :type k: int

    :param base: The `base` parameter represents the base of the number system being used. In this case,
                 it is set to 2, which means the number system is binary (base 2), defaults to 2

    :type base: int (optional)

    :return: The function `vdc` returns a floating point value.

    Examples:
        >>> vdc(11, 2)
        0.8125
    """
    res = 0.0
    denom = 1.0
    while k != 0:
        denom *= base
        remainder = k % base
        k //= base
        res += remainder / denom
    return res


class VdCorput:
    """Van der Corput sequence generator

    `VdCorput` is a class that generates the Van der Corput sequence. The Van
    def Corput sequence is a low-discrepancy sequence that is commonly used in
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

    count: int
    base: int

    def __init__(self, base: int = 2) -> None:
        """
        The function initializes an object with a base and scale value, and sets the count to 0.

        :param base: The `base` parameter is an optional integer argument that specifies the base of the
                     number system. By default, it is set to 2, which means the number system is binary (base 2).
                     However, you can change the value of `base` to any other prime number to use a different, defaults to 2

        :type base: int (optional)
        """
        self.count = 0
        self.base = base

    def pop(self) -> float:
        """
        The `pop()` function is used to generate the next value in the sequence.
        For example, in the `VdCorput` class, `pop()` increments the count and
        calculates the Van der Corput sequence value for that count and base. In
        the `Halton` class, `pop()` returns the next point in the Halton sequence
        as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
        returns the next point on the unit circle as a `List[float; 2]`. In
        the `Sphere` class, `pop()` returns the next point on the unit sphere as a
        `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
        the next point on the 3-sphere using the Hopf fibration as a
        `List[float; 4]`.

        Examples:
            >>> vgen = VdCorput(2)
            >>> vgen.pop()
            0.5
        """
        self.count += 1
        return vdc(self.count, self.base)

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self.count = seed


class Halton:
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

    vdc0: VdCorput
    vdc1: VdCorput

    def __init__(self, base: Sequence[int]) -> None:
        """
        The `__init__()` function is a constructor for the `Halton` class that initializes two `VdCorput`
        objects with the given bases.

        :param base: The `base` parameter is a list of two integers. These integers are used as the bases
                     for generating the Halton sequence. The first integer in the list is used as the base for generating
                     the first component of the sequence, and the second integer is used as the base for generating the
                     second component

        :type base: Sequence[int]
        """
        self.vdc0 = VdCorput(base[0])
        self.vdc1 = VdCorput(base[1])

    def pop(self) -> List[float]:
        """
        The `pop()` function is used to generate the next value in the sequence.
        For example, in the `VdCorput` class, `pop()` increments the count and
        calculates the Van der Corput sequence value for that count and base. In
        the `Halton` class, `pop()` returns the next point in the Halton sequence
        as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
        returns the next point on the unit circle as a `List[float; 2]`. In
        the `Sphere` class, `pop()` returns the next point on the unit sphere as a
        `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
        the next point on the 3-sphere using the Hopf fibration as a
        `List[float; 4]`.

        Examples:
            >>> hgen = Halton([2, 3])
            >>> hgen.pop()
            [0.5, 0.3333333333333333]
        """
        return [self.vdc0.pop(), self.vdc1.pop()]

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self.vdc0.reseed(seed)
        self.vdc1.reseed(seed)


class Circle:
    """Circle sequence generator

    Examples:
        >>> cgen = Circle(2)
        >>> cgen.reseed(0)
        >>> for _ in range(2):
        ...     print(cgen.pop())
        ...
        [1.2246467991473532e-16, -1.0]
        [1.0, 6.123233995736766e-17]
    """

    vdc: VdCorput

    def __init__(self, base: int) -> None:
        """
        The function initializes an instance of the class with a given base.

        :param base: The `base` parameter is an integer that represents the base of the Van der Corput sequence
        :type base: int
        """
        self.vdc = VdCorput(base)

    def pop(self) -> List[float]:
        """
            The `pop()` function is used to generate the next value in the sequence.
            For example, in the `VdCorput` class, `pop()` increments the count and
            calculates the Van der Corput sequence value for that count and base. In
            the `Halton` class, `pop()` returns the next point in the Halton sequence
            as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
            returns the next point on the unit circle as a `List[float; 2]`. In
            the `Sphere` class, `pop()` returns the next point on the unit sphere as a
            `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
            the next point on the 3-sphere using the Hopf fibration as a
            `List[float; 4]`.

        Examples:
            >>> cgen = Circle(2)
            >>> cgen.pop()
            [1.2246467991473532e-16, -1.0]
        """
        theta = self.vdc.pop() * TWO_PI  # map to [0, 2*pi]
        return [sin(theta), cos(theta)]

    # [allow(dead_code)]
    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self.vdc.reseed(seed)


class Sphere:
    """Sphere sequence generator

    Examples:
        >>> sgen = Sphere([2, 3])
        >>> sgen.reseed(0)
        >>> res = sgen.pop()
        >>> res[2]
        0.0
        >>> res = sgen.pop()
        >>> res[2]
        -0.5
    """

    vdc: VdCorput
    cirgen: Circle

    def __init__(self, base: Sequence[int]) -> None:
        """
        The function initializes the `vdc` and `cirgen` attributes with the first and second elements of the
        `base` list, respectively.

        :param base: The `base` parameter is a sequence of integers. It is expected to have two elements.
                     The first element is used to initialize a `VdCorput` object, and the second element is used to
                     initialize a `Circle` object

        :type base: Sequence[int]
        """
        self.vdc = VdCorput(base[0])
        self.cirgen = Circle(base[1])

    def pop(self) -> List[float]:
        """
        The `pop()` function is used to generate the next value in the sequence.
        For example, in the `VdCorput` class, `pop()` increments the count and
        calculates the Van der Corput sequence value for that count and base. In
        the `Halton` class, `pop()` returns the next point in the Halton sequence
        as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
        returns the next point on the unit circle as a `List[float; 2]`. In
        the `Sphere` class, `pop()` returns the next point on the unit sphere as a
        `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
        the next point on the 3-sphere using the Hopf fibration as a
        `List[float; 4]`.
        """
        cosphi = 2.0 * self.vdc.pop() - 1.0  # map to [-1, 1]
        sinphi = sqrt(1.0 - cosphi * cosphi)
        [c, s] = self.cirgen.pop()
        return [sinphi * c, sinphi * s, cosphi]

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self.cirgen.reseed(seed)
        self.vdc.reseed(seed)


# S(3) sequence generator by Hopf
class Sphere3Hopf:
    """Sphere3Hopf sequence generator"""

    vdc0: VdCorput
    vdc1: VdCorput
    vdc2: VdCorput

    def __init__(self, base: Sequence[int]) -> None:
        """
        The function initializes three VdCorput objects with the values from the base list.

        :param base: The `base` parameter is a list of three integers. It is used to initialize three
                     instances of the `VdCorput` class. The first integer in the `base` list is used to initialize
                     `self.vdc0`, the second integer is used to initialize `self.vdc1

        :type base: Sequence[int]
        """
        self.vdc0 = VdCorput(base[0])
        self.vdc1 = VdCorput(base[1])
        self.vdc2 = VdCorput(base[2])

    def pop(self) -> List[float]:
        """
        The `pop()` function is used to generate the next value in the sequence.
        For example, in the `VdCorput` class, `pop()` increments the count and
        calculates the Van der Corput sequence value for that count and base. In
        the `Halton` class, `pop()` returns the next point in the Halton sequence
        as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
        returns the next point on the unit circle as a `List[float; 2]`. In
        the `Sphere` class, `pop()` returns the next point on the unit sphere as a
        `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
        the next point on the 3-sphere using the Hopf fibration as a
        `List[float; 4]`.
        """
        phi = self.vdc0.pop() * TWO_PI  # map to [0, 2*pi]
        psy = self.vdc1.pop() * TWO_PI  # map to [0, 2*pi]
        vd = self.vdc2.pop()
        cos_eta = sqrt(vd)
        sin_eta = sqrt(1.0 - vd)
        return [
            cos_eta * cos(psy),
            cos_eta * sin(psy),
            sin_eta * cos(phi + psy),
            sin_eta * sin(phi + psy),
        ]

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self.vdc0.reseed(seed)
        self.vdc1.reseed(seed)
        self.vdc2.reseed(seed)


class HaltonN:
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
        """
        The function initializes a list of VdCorput objects using the given base sequence.

        :param n: The parameter `n` is an integer that represents the number of elements in the `base` sequence

        :type n: int

        :param base: The `base` parameter is a list of integers. Each integer represents the base of a Van
                     der Corput sequence. The Van der Corput sequence is a low-discrepancy sequence used in numerical
                     analysis and Monte Carlo methods. In this code, `base` is used to initialize a list

        :type base: Sequence[int]
        """
        self.vdcs = [VdCorput(b) for b in base]

    def pop(self) -> List[float]:
        """
        The `pop()` function is used to generate the next value in the sequence.
        For example, in the `VdCorput` class, `pop()` increments the count and
        calculates the Van der Corput sequence value for that count and base. In
        the `Halton` class, `pop()` returns the next point in the Halton sequence
        as a `List[float; 2]`. Similarly, in the `Circle` class, `pop()`
        returns the next point on the unit circle as a `List[float; 2]`. In
        the `Sphere` class, `pop()` returns the next point on the unit sphere as a
        `List[float; 3]`. And in the `Sphere3Hopf` class, `pop()` returns
        the next point on the 3-sphere using the Hopf fibration as a
        `List[float; 4]`.

        Examples:
            >>> hgen = HaltonN([2, 3, 5])
            >>> hgen.pop()
            [0.5, 0.3333333333333333, 0.2]
        """
        return [vdc.pop() for vdc in self.vdcs]

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        for vdc in self.vdcs:
            vdc.reseed(seed)


# First 1000 prime numbers
# [allow(dead_code)]
PRIME_TABLE: List[int] = [
    2,
    3,
    5,
    7,
    11,
    13,
    17,
    19,
    23,
    29,
    31,
    37,
    41,
    43,
    47,
    53,
    59,
    61,
    67,
    71,
    73,
    79,
    83,
    89,
    97,
    101,
    103,
    107,
    109,
    113,
    127,
    131,
    137,
    139,
    149,
    151,
    157,
    163,
    167,
    173,
    179,
    181,
    191,
    193,
    197,
    199,
    211,
    223,
    227,
    229,
    233,
    239,
    241,
    251,
    257,
    263,
    269,
    271,
    277,
    281,
    283,
    293,
    307,
    311,
    313,
    317,
    331,
    337,
    347,
    349,
    353,
    359,
    367,
    373,
    379,
    383,
    389,
    397,
    401,
    409,
    419,
    421,
    431,
    433,
    439,
    443,
    449,
    457,
    461,
    463,
    467,
    479,
    487,
    491,
    499,
    503,
    509,
    521,
    523,
    541,
    547,
    557,
    563,
    569,
    571,
    577,
    587,
    593,
    599,
    601,
    607,
    613,
    617,
    619,
    631,
    641,
    643,
    647,
    653,
    659,
    661,
    673,
    677,
    683,
    691,
    701,
    709,
    719,
    727,
    733,
    739,
    743,
    751,
    757,
    761,
    769,
    773,
    787,
    797,
    809,
    811,
    821,
    823,
    827,
    829,
    839,
    853,
    857,
    859,
    863,
    877,
    881,
    883,
    887,
    907,
    911,
    919,
    929,
    937,
    941,
    947,
    953,
    967,
    971,
    977,
    983,
    991,
    997,
    1009,
    1013,
    1019,
    1021,
    1031,
    1033,
    1039,
    1049,
    1051,
    1061,
    1063,
    1069,
    1087,
    1091,
    1093,
    1097,
    1103,
    1109,
    1117,
    1123,
    1129,
    1151,
    1153,
    1163,
    1171,
    1181,
    1187,
    1193,
    1201,
    1213,
    1217,
    1223,
    1229,
    1231,
    1237,
    1249,
    1259,
    1277,
    1279,
    1283,
    1289,
    1291,
    1297,
    1301,
    1303,
    1307,
    1319,
    1321,
    1327,
    1361,
    1367,
    1373,
    1381,
    1399,
    1409,
    1423,
    1427,
    1429,
    1433,
    1439,
    1447,
    1451,
    1453,
    1459,
    1471,
    1481,
    1483,
    1487,
    1489,
    1493,
    1499,
    1511,
    1523,
    1531,
    1543,
    1549,
    1553,
    1559,
    1567,
    1571,
    1579,
    1583,
    1597,
    1601,
    1607,
    1609,
    1613,
    1619,
    1621,
    1627,
    1637,
    1657,
    1663,
    1667,
    1669,
    1693,
    1697,
    1699,
    1709,
    1721,
    1723,
    1733,
    1741,
    1747,
    1753,
    1759,
    1777,
    1783,
    1787,
    1789,
    1801,
    1811,
    1823,
    1831,
    1847,
    1861,
    1867,
    1871,
    1873,
    1877,
    1879,
    1889,
    1901,
    1907,
    1913,
    1931,
    1933,
    1949,
    1951,
    1973,
    1979,
    1987,
    1993,
    1997,
    1999,
    2003,
    2011,
    2017,
    2027,
    2029,
    2039,
    2053,
    2063,
    2069,
    2081,
    2083,
    2087,
    2089,
    2099,
    2111,
    2113,
    2129,
    2131,
    2137,
    2141,
    2143,
    2153,
    2161,
    2179,
    2203,
    2207,
    2213,
    2221,
    2237,
    2239,
    2243,
    2251,
    2267,
    2269,
    2273,
    2281,
    2287,
    2293,
    2297,
    2309,
    2311,
    2333,
    2339,
    2341,
    2347,
    2351,
    2357,
    2371,
    2377,
    2381,
    2383,
    2389,
    2393,
    2399,
    2411,
    2417,
    2423,
    2437,
    2441,
    2447,
    2459,
    2467,
    2473,
    2477,
    2503,
    2521,
    2531,
    2539,
    2543,
    2549,
    2551,
    2557,
    2579,
    2591,
    2593,
    2609,
    2617,
    2621,
    2633,
    2647,
    2657,
    2659,
    2663,
    2671,
    2677,
    2683,
    2687,
    2689,
    2693,
    2699,
    2707,
    2711,
    2713,
    2719,
    2729,
    2731,
    2741,
    2749,
    2753,
    2767,
    2777,
    2789,
    2791,
    2797,
    2801,
    2803,
    2819,
    2833,
    2837,
    2843,
    2851,
    2857,
    2861,
    2879,
    2887,
    2897,
    2903,
    2909,
    2917,
    2927,
    2939,
    2953,
    2957,
    2963,
    2969,
    2971,
    2999,
    3001,
    3011,
    3019,
    3023,
    3037,
    3041,
    3049,
    3061,
    3067,
    3079,
    3083,
    3089,
    3109,
    3119,
    3121,
    3137,
    3163,
    3167,
    3169,
    3181,
    3187,
    3191,
    3203,
    3209,
    3217,
    3221,
    3229,
    3251,
    3253,
    3257,
    3259,
    3271,
    3299,
    3301,
    3307,
    3313,
    3319,
    3323,
    3329,
    3331,
    3343,
    3347,
    3359,
    3361,
    3371,
    3373,
    3389,
    3391,
    3407,
    3413,
    3433,
    3449,
    3457,
    3461,
    3463,
    3467,
    3469,
    3491,
    3499,
    3511,
    3517,
    3527,
    3529,
    3533,
    3539,
    3541,
    3547,
    3557,
    3559,
    3571,
    3581,
    3583,
    3593,
    3607,
    3613,
    3617,
    3623,
    3631,
    3637,
    3643,
    3659,
    3671,
    3673,
    3677,
    3691,
    3697,
    3701,
    3709,
    3719,
    3727,
    3733,
    3739,
    3761,
    3767,
    3769,
    3779,
    3793,
    3797,
    3803,
    3821,
    3823,
    3833,
    3847,
    3851,
    3853,
    3863,
    3877,
    3881,
    3889,
    3907,
    3911,
    3917,
    3919,
    3923,
    3929,
    3931,
    3943,
    3947,
    3967,
    3989,
    4001,
    4003,
    4007,
    4013,
    4019,
    4021,
    4027,
    4049,
    4051,
    4057,
    4073,
    4079,
    4091,
    4093,
    4099,
    4111,
    4127,
    4129,
    4133,
    4139,
    4153,
    4157,
    4159,
    4177,
    4201,
    4211,
    4217,
    4219,
    4229,
    4231,
    4241,
    4243,
    4253,
    4259,
    4261,
    4271,
    4273,
    4283,
    4289,
    4297,
    4327,
    4337,
    4339,
    4349,
    4357,
    4363,
    4373,
    4391,
    4397,
    4409,
    4421,
    4423,
    4441,
    4447,
    4451,
    4457,
    4463,
    4481,
    4483,
    4493,
    4507,
    4513,
    4517,
    4519,
    4523,
    4547,
    4549,
    4561,
    4567,
    4583,
    4591,
    4597,
    4603,
    4621,
    4637,
    4639,
    4643,
    4649,
    4651,
    4657,
    4663,
    4673,
    4679,
    4691,
    4703,
    4721,
    4723,
    4729,
    4733,
    4751,
    4759,
    4783,
    4787,
    4789,
    4793,
    4799,
    4801,
    4813,
    4817,
    4831,
    4861,
    4871,
    4877,
    4889,
    4903,
    4909,
    4919,
    4931,
    4933,
    4937,
    4943,
    4951,
    4957,
    4967,
    4969,
    4973,
    4987,
    4993,
    4999,
    5003,
    5009,
    5011,
    5021,
    5023,
    5039,
    5051,
    5059,
    5077,
    5081,
    5087,
    5099,
    5101,
    5107,
    5113,
    5119,
    5147,
    5153,
    5167,
    5171,
    5179,
    5189,
    5197,
    5209,
    5227,
    5231,
    5233,
    5237,
    5261,
    5273,
    5279,
    5281,
    5297,
    5303,
    5309,
    5323,
    5333,
    5347,
    5351,
    5381,
    5387,
    5393,
    5399,
    5407,
    5413,
    5417,
    5419,
    5431,
    5437,
    5441,
    5443,
    5449,
    5471,
    5477,
    5479,
    5483,
    5501,
    5503,
    5507,
    5519,
    5521,
    5527,
    5531,
    5557,
    5563,
    5569,
    5573,
    5581,
    5591,
    5623,
    5639,
    5641,
    5647,
    5651,
    5653,
    5657,
    5659,
    5669,
    5683,
    5689,
    5693,
    5701,
    5711,
    5717,
    5737,
    5741,
    5743,
    5749,
    5779,
    5783,
    5791,
    5801,
    5807,
    5813,
    5821,
    5827,
    5839,
    5843,
    5849,
    5851,
    5857,
    5861,
    5867,
    5869,
    5879,
    5881,
    5897,
    5903,
    5923,
    5927,
    5939,
    5953,
    5981,
    5987,
    6007,
    6011,
    6029,
    6037,
    6043,
    6047,
    6053,
    6067,
    6073,
    6079,
    6089,
    6091,
    6101,
    6113,
    6121,
    6131,
    6133,
    6143,
    6151,
    6163,
    6173,
    6197,
    6199,
    6203,
    6211,
    6217,
    6221,
    6229,
    6247,
    6257,
    6263,
    6269,
    6271,
    6277,
    6287,
    6299,
    6301,
    6311,
    6317,
    6323,
    6329,
    6337,
    6343,
    6353,
    6359,
    6361,
    6367,
    6373,
    6379,
    6389,
    6397,
    6421,
    6427,
    6449,
    6451,
    6469,
    6473,
    6481,
    6491,
    6521,
    6529,
    6547,
    6551,
    6553,
    6563,
    6569,
    6571,
    6577,
    6581,
    6599,
    6607,
    6619,
    6637,
    6653,
    6659,
    6661,
    6673,
    6679,
    6689,
    6691,
    6701,
    6703,
    6709,
    6719,
    6733,
    6737,
    6761,
    6763,
    6779,
    6781,
    6791,
    6793,
    6803,
    6823,
    6827,
    6829,
    6833,
    6841,
    6857,
    6863,
    6869,
    6871,
    6883,
    6899,
    6907,
    6911,
    6917,
    6947,
    6949,
    6959,
    6961,
    6967,
    6971,
    6977,
    6983,
    6991,
    6997,
    7001,
    7013,
    7019,
    7027,
    7039,
    7043,
    7057,
    7069,
    7079,
    7103,
    7109,
    7121,
    7127,
    7129,
    7151,
    7159,
    7177,
    7187,
    7193,
    7207,
    7211,
    7213,
    7219,
    7229,
    7237,
    7243,
    7247,
    7253,
    7283,
    7297,
    7307,
    7309,
    7321,
    7331,
    7333,
    7349,
    7351,
    7369,
    7393,
    7411,
    7417,
    7433,
    7451,
    7457,
    7459,
    7477,
    7481,
    7487,
    7489,
    7499,
    7507,
    7517,
    7523,
    7529,
    7537,
    7541,
    7547,
    7549,
    7559,
    7561,
    7573,
    7577,
    7583,
    7589,
    7591,
    7603,
    7607,
    7621,
    7639,
    7643,
    7649,
    7669,
    7673,
    7681,
    7687,
    7691,
    7699,
    7703,
    7717,
    7723,
    7727,
    7741,
    7753,
    7757,
    7759,
    7789,
    7793,
    7817,
    7823,
    7829,
    7841,
    7853,
    7867,
    7873,
    7877,
    7879,
    7883,
    7901,
    7907,
    7919,
]


if __name__ == "__main__":
    import doctest

    doctest.testmod()
