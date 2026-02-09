"""Validation utilities for LDS generators.

This module provides validation functions for checking base values
and issuing appropriate warnings.
"""

import warnings
from typing import List

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
]


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False

    i = 3
    while i * i <= n:
        if n % i == 0:
            return False
        i += 2

    return True


def validate_base(base: int, generator_name: str = "generator") -> None:
    if not isinstance(base, int):
        raise TypeError(f"{generator_name} base must be an integer, got {type(base)}")

    if base < 2:
        raise ValueError(f"{generator_name} base must be >= 2, got {base}")

    if not is_prime(base):
        warnings.warn(
            f"Non-prime base ({base}) may reduce sequence uniformity. "
            f"Consider using prime bases from: {PRIME_TABLE[:10]}",
            stacklevel=2,
        )


def validate_bases(bases: List[int], generator_name: str = "generator") -> None:
    """Validate multiple base values and issue warnings.

    Args:
        bases: List of base values to validate
        generator_name: Name of generator class (for warning messages)

    Returns:
        None if valid, otherwise raises ValueError
    """
    if not isinstance(bases, (list, tuple)):
        raise TypeError(
            f"{generator_name} bases must be a list or tuple, got {type(bases)}"
        )

    if len(bases) == 0:
        raise ValueError(f"{generator_name} bases cannot be empty")

    for i, base in enumerate(bases):
        if not isinstance(base, int):
            raise TypeError(
                f"{generator_name} base[{i}] must be an integer, got {type(base)}"
            )

        if base < 2:
            raise ValueError(f"{generator_name} base[{i}] must be >= 2, got {base}")

        if not is_prime(base):
            warnings.warn(
                f"{generator_name} non-prime base[{i}] ({base}) may reduce uniformity. "
                f"Consider using prime bases",
                stacklevel=2,
            )


def validate_scale(scale: int, generator_name: str = "generator") -> None:
    """Validate scale value for integer generators.

    Args:
        scale: Scale value to validate
        generator_name: Name of generator class (for warning messages)

    Returns:
        None if valid, otherwise raises ValueError
    """
    if not isinstance(scale, int):
        raise TypeError(f"{generator_name} scale must be an integer, got {type(scale)}")

    if scale < 1:
        raise ValueError(f"{generator_name} scale must be >= 1, got {scale}")

    if scale > 64:
        warnings.warn(
            f"{generator_name} scale ({scale}) is large and may cause integer overflow. "
            f"Consider using scale <= 64",
            stacklevel=2,
        )
