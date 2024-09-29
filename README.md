<!-- These are examples of badges you might want to add to your README:
     please update the URLs accordingly

[![Built Status](https://api.cirrus-ci.com/github/<USER>/lds-gen.svg?branch=main)](https://cirrus-ci.com/github/<USER>/lds-gen)
[![ReadTheDocs](https://readthedocs.org/projects/lds-gen/badge/?version=latest)](https://lds-gen.readthedocs.io/en/stable/)
[![Coveralls](https://img.shields.io/coveralls/github/<USER>/lds-gen/main.svg)](https://coveralls.io/r/<USER>/lds-gen)
[![PyPI-Server](https://img.shields.io/pypi/v/lds-gen.svg)](https://pypi.org/project/lds-gen/)
[![Conda-Forge](https://img.shields.io/conda/vn/conda-forge/lds-gen.svg)](https://anaconda.org/conda-forge/lds-gen)
[![Monthly Downloads](https://pepy.tech/badge/lds-gen/month)](https://pepy.tech/project/lds-gen)
[![Twitter](https://img.shields.io/twitter/url/http/shields.io.svg?style=social&label=Twitter)](https://twitter.com/lds-gen)
-->

[![Project generated with PyScaffold](https://img.shields.io/badge/-PyScaffold-005CA0?logo=pyscaffold)](https://pyscaffold.org/)
[![Documentation Status](https://readthedocs.org/projects/lds-gen/badge/?version=latest)](https://lds-gen.readthedocs.io/en/latest/?badge=latest)
[![Coveralls](https://img.shields.io/coveralls/github/luk036/lds-gen/main.svg)](https://coveralls.io/r/luk036/lds-gen)

# lds-gen

> Low Discrepancy Sequence Generation

This code implements a set of low-discrepancy sequence generators, which are used to create sequences of numbers that are more evenly distributed than random numbers. These sequences are particularly useful in various fields such as computer graphics, numerical integration, and Monte Carlo simulations.

The code defines several classes, each representing a different type of low-discrepancy sequence generator. The main types of sequences implemented are:

1. Van der Corput sequence
2. Halton sequence
3. Circle sequence
4. Sphere sequence
5. 3-Sphere Hopf sequence
6. N-dimensional Halton sequence

Each generator takes specific inputs, usually in the form of base numbers or sequences of base numbers. These bases determine how the sequences are generated. The generators produce outputs in the form of floating-point numbers or lists of floating-point numbers, depending on the dimensionality of the sequence.

The core algorithm used in most of these generators is the Van der Corput sequence. This sequence is created by expressing integers in a given base, reversing the digits, and placing them after a decimal point. For example, in base 2, the sequence would start: 1/2, 1/4, 3/4, 1/8, 5/8, and so on.

The Halton sequence extends this concept to multiple dimensions by using a different base for each dimension. The Circle and Sphere sequences use trigonometric functions to map these low-discrepancy sequences onto circular or spherical surfaces.

The code also includes utility functions and classes to support these generators. For instance, there's a list of prime numbers that can be used as bases for the sequences.

Each generator class has methods to produce the next value in the sequence (pop()) and to reset the sequence to a specific starting point (reseed()). This allows for flexible use of the generators in various applications.

The purpose of this code is to provide a toolkit for generating well-distributed sequences of numbers, which can be used in place of random numbers in many applications to achieve more uniform coverage of a given space or surface. This can lead to more efficient and accurate results in tasks like sampling, integration, and optimization.

# Used In

- [sphere-n](https://github.com/luk036/sphere-n)
- [physdes-py](https://luk036.github.io/physdes-py)
- [bairstow](https://luk036.github.io/bairstow)

## 👀 See also

- [lds-gen-cpp](https://github.com/luk036/lds-gen-cpp)
- [lds-rs](https://github.com/luk036/lds-rs)
- [sphere-n](https://github.com/luk036/sphere-n)

<!-- pyscaffold-notes -->

## 👉 Note

This project has been set up using PyScaffold 4.5. For details and usage
information on PyScaffold see https://pyscaffold.org/.
