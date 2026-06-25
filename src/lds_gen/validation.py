"""Validation utilities for LDS generators.

This module provides validation functions for checking base values
and issuing appropriate warnings.
"""

import warnings
from typing import List

from lds_gen.lds import PRIME_TABLE


def is_prime(n: int) -> bool:
    """Check if a number is prime.

    :param n: The number to check.
    :type n: int
    :return: True if n is prime, False otherwise.
    """
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
    """Validate a base value for a sequence generator.

    :param base: The base value to validate.
    :type base: int
    :param generator_name: Name of the generator for error messages.
    :type generator_name: str
    :raises TypeError: If base is not an integer.
    :raises ValueError: If base is less than 2.
    """
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
