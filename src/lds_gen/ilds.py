"""
ilds.py

This code implements two low-discrepancy sequence generators: the Van der Corput sequence and the Halton sequence (specific for integer output). These sequences are used to generate evenly distributed points in a space, which can be useful for various applications like sampling, optimization, or numerical integration.

The code defines three main components: a function called vdc_i, and two classes named VdCorput and Halton.

The vdc_i function is the core of the Van der Corput sequence generation. It takes an integer k, a base (default 2), and a scale (default 10) as inputs. It converts the number k from the given base to a decimal number, using the specified scale for integer output. This function is used to generate individual elements of the Van der Corput sequence.

The VdCorput class is a wrapper around the vdc_i function. It keeps track of the current count and allows you to generate successive elements of the Van der Corput sequence by calling its pop method. You can also reset the sequence to a specific starting point using the reseed method.

The Halton class generates points in a 2-dimensional space using two Van der Corput sequences with different bases. It creates two VdCorput objects internally and uses them to generate pairs of numbers. The pop method of the Halton class returns a list of two integers, representing a point in 2D space.

The main logic flow in this code is the generation of these low-discrepancy sequences. For the Van der Corput sequence, it works by repeatedly dividing the input number by the base and using the remainders to construct the output number. This process creates a sequence of numbers that are well-distributed between 0 and N (when properly scaled).

The Halton sequence extends this idea to multiple dimensions by using different bases for each dimension. In this implementation, it generates 2D points by combining two Van der Corput sequences.

The code doesn't take any direct input from the user. Instead, it provides classes and functions that can be used in other programs to generate these sequences. The output of these generators are individual numbers (for Van der Corput) or pairs of numbers (for Halton) that form the respective sequences.

This code is particularly useful for applications that need well-distributed random-like numbers, but with more uniformity than typical pseudo-random number generators provide. It's a building block that can be used in more complex algorithms and simulations.
"""

from typing import List, Sequence


# The `VdCorput` class initializes an object with a base and scale value, and sets the count to 0.
class VdCorput:
    def __init__(self, base: int = 2, scale: int = 10) -> None:
        """
        The function initializes an object with a base and scale value, and sets the count to 0.

        :param base: The `base` parameter is an optional integer argument that specifies the base of the
                     number system. By default, it is set to 2, which means the number system is binary (base 2).
                     However, you can change the value of `base` to any other prime number to use a different, defaults to 2

        :type base: int (optional)

        :param scale: The `scale` parameter determines the number of digits that can be represented in the
                      number system. For example, if `scale` is set to 10, the number system can represent digits from 0
                      to 9, defaults to 10

        :type scale: int (optional)
        """
        self._base: int = base
        self._scale: int = scale
        self._count: int = 0
        self._factor: int = base**scale

    def pop(self) -> int:
        """
        The `pop()` function is a member function of the `VdCorput` class that increments the count and
        calculates the next value in the Van der Corput sequence.

        :return: The `pop()` function is returning an `int` value.

        Examples:
            >>> vdc = VdCorput(2, 10)
            >>> vdc.pop()
            512
        """
        self._count += 1
        k = self._count
        vdc: int = 0
        factor: int = self._factor
        while k != 0:
            factor //= self._base
            remainder: int = k % self._base
            k //= self._base
            vdc += remainder * factor
        return vdc

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int

        Examples:
            >>> vdc = VdCorput(2, 10)
            >>> vdc.reseed(0)
            >>> vdc.pop()
            512
        """
        self._count = seed


class Halton:
    """Halton sequence generator

    The `Halton` class is a sequence generator that generates points in a
    2-dimensional space using the Halton sequence. The Halton sequence is a
    low-discrepancy sequence that is often used in quasi-Monte Carlo methods.
    It is generated by iterating over two different bases and calculating the
    fractional parts of the numbers in those bases. The `Halton` class keeps
    track of the current count and bases, and provides a `pop()` method that
    returns the next point in the sequence as a `List[int]`.

    Examples:
        >>> hgen = Halton([2, 3], [11, 7])
        >>> hgen.reseed(0)
        >>> for _ in range(10):
        ...     print(hgen.pop())
        ...
        [1024, 729]
        [512, 1458]
        [1536, 243]
        [256, 972]
        [1280, 1701]
        [768, 486]
        [1792, 1215]
        [128, 1944]
        [1152, 81]
        [640, 810]
    """

    def __init__(self, base: Sequence[int], scale: Sequence[int]) -> None:
        """
        The `__init__()` function is a constructor for the `Halton` class that initializes two `VdCorput`
        objects with the given bases.

        :param base: The `base` parameter is a list of two integers. These integers are used as the bases
                     for generating the Halton sequence. The first integer in the list is used as the base for generating
                     the first component of the sequence, and the second integer is used as the base for generating the
                     second component

        :type base: Sequence[int]
        """
        self._vdc0 = VdCorput(base[0], scale[0])
        self._vdc1 = VdCorput(base[1], scale[1])

    def pop(self) -> List[int]:
        """
        The `pop` function returns a list of two integers by popping elements from `vdc0` and `vdc1`.

        :return: The `pop` method is returning a list of two integers.
        """
        return [self._vdc0.pop(), self._vdc1.pop()]

    def reseed(self, seed: int) -> None:
        """
        The `reseed` function resets the state of a sequence generator to a specific seed value.

        :param seed: The `seed` parameter is an integer value that is used to reset the state of the
                     sequence generator. It determines the starting point of the sequence generation

        :type seed: int
        """
        self._vdc0.reseed(seed)
        self._vdc1.reseed(seed)


if __name__ == "__main__":
    import doctest

    doctest.testmod()
