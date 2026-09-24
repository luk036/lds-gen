"""Unit tests for the NumPy accelerated utilities module."""

import numpy as np
from pytest import approx

from lds_gen.lds import Halton, HaltonN, VdCorput, vdc
from lds_gen.numpy_utils import (
    batch_to_numpy,
    compute_discrepancy,
    generate_halton_vectorized,
    generate_vdcorput_vectorized,
)


def test_generate_vdcorput_matches_scalar() -> None:
    """Vectorized van der Corput values match the scalar reference."""
    for base in (2, 3, 5):
        expected = [vdc(n, base) for n in range(1, 11)]
        assert generate_vdcorput_vectorized(10, base) == approx(expected)


def test_generate_vdcorput_matches_generator() -> None:
    """Vectorized van der Corput values match the stateful generator."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    assert generate_vdcorput_vectorized(5, 2) == approx(vgen.pop_batch(5))


def test_generate_vdcorput_empty() -> None:
    """Requesting zero values returns an empty list."""
    assert generate_vdcorput_vectorized(0, 2) == []


def test_generate_halton_matches_scalar() -> None:
    """Vectorized Halton points match the pure scalar evaluation."""
    hgen = Halton([2, 3])
    expected = [hgen.value_at(n) for n in range(1, 6)]
    actual = generate_halton_vectorized(5, [2, 3])
    assert len(actual) == len(expected)
    for row, exp in zip(actual, expected):
        assert row == approx(exp)


def test_generate_halton_matches_generator() -> None:
    """Vectorized Halton points match the stateful generator."""
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)
    actual = generate_halton_vectorized(4, [2, 3, 5])
    expected = hgen.pop_batch(4)
    assert len(actual) == len(expected)
    for row, exp in zip(actual, expected):
        assert row == approx(exp)


def test_generate_halton_empty() -> None:
    """Requesting zero points returns an empty list."""
    assert generate_halton_vectorized(0, [2, 3]) == []


def test_compute_discrepancy_empty() -> None:
    """An empty point set has zero discrepancy."""
    assert compute_discrepancy([]) == 0.0


def test_compute_discrepancy_uniform_grid() -> None:
    """A perfectly uniform 1D grid has zero star-discrepancy."""
    points = [[i / 10] for i in range(10)]
    assert compute_discrepancy(points) == approx(0.0, abs=1e-12)


def test_compute_discrepancy_multidim() -> None:
    """Multi-dimensional discrepancies are combined across axes."""
    points = [[0.0, 0.0], [0.5, 0.5], [1.0, 1.0]]
    assert compute_discrepancy(points) == approx(1 / 3)


def test_batch_to_numpy() -> None:
    """Points are converted to a 2D float array preserving values."""
    arr = batch_to_numpy([[1.0, 2.0], [3.0, 4.0]])
    assert isinstance(arr, np.ndarray)
    assert arr.shape == (2, 2)
    assert arr.tolist() == [[1.0, 2.0], [3.0, 4.0]]
