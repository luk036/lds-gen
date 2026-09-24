import pytest
from pytest import approx

from lds_gen.lds import (
    Circle,
    Disk,
    Halton,
    HaltonN,
    Sphere,
    Sphere3Hopf,
    VdCorput,
    vdc,
)


def test_vdc() -> None:
    """assert that the vdcorput generator produces the correct values""" ""
    assert vdc(11, 2) == 0.8125


def test_prime_table() -> None:
    """Verify PRIME_TABLE contains correct primes."""
    from lds_gen.lds import PRIME_TABLE, _prime_table

    assert len(PRIME_TABLE) == 1000
    assert PRIME_TABLE[0] == 2
    assert PRIME_TABLE[1] == 3
    assert PRIME_TABLE[2] == 5
    assert PRIME_TABLE[3] == 7
    # Spot-check known primes
    assert PRIME_TABLE[99] == 541  # 100th prime
    assert PRIME_TABLE[999] == 7919  # 1000th prime
    # Verify it generates on-demand too
    assert _prime_table(5) == [2, 3, 5, 7, 11]
    assert _prime_table(1) == [2]
    assert _prime_table(0) == []


def test_vdcorput_iter_batch() -> None:
    """iter_batch yields same values as pop_batch."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    batch = vgen.pop_batch(10)
    vgen.reseed(0)
    lazy = list(vgen.iter_batch(10))
    assert batch == lazy
    # Empty/negative
    with pytest.raises(ValueError):
        list(vgen.iter_batch(0))
    with pytest.raises(ValueError):
        list(vgen.iter_batch(-1))


def test_halton_iter_batch() -> None:
    """iter_batch on Halton yields same as pop_batch."""
    hgen = Halton([2, 3])
    hgen.reseed(0)
    batch = hgen.pop_batch(10)
    hgen.reseed(0)
    lazy = list(hgen.iter_batch(10))
    assert batch == lazy


def test_vdcorput_pop() -> None:
    """Test the pop method of the VdCorput class."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    assert vgen.pop() == 0.5
    assert vgen.pop() == 0.25
    assert vgen.pop() == 0.75
    assert vgen.pop() == 0.125


def test_vdcorput_reseed() -> None:
    """Test the reseed method of the VdCorput class."""
    vgen = VdCorput(2)
    vgen.reseed(5)
    assert vgen.pop() == 0.375
    vgen.reseed(0)
    assert vgen.pop() == 0.5


def test_halton_pop() -> None:
    """Test the pop method of the Halton class."""
    hgen = Halton([2, 3])
    hgen.reseed(0)
    res = hgen.pop()
    assert res[0] == 0.5
    assert res[1] == approx(1 / 3)
    res = hgen.pop()
    assert res[0] == 0.25
    assert res[1] == approx(2 / 3)


def test_halton_reseed() -> None:
    """Test the reseed method of the Halton class."""
    hgen = Halton([2, 3])
    hgen.reseed(5)
    res = hgen.pop()
    assert res[0] == approx(0.375)
    assert res[1] == approx(2 / 9)
    hgen.reseed(0)
    res = hgen.pop()
    assert res[0] == 0.5
    assert res[1] == approx(1 / 3)


def test_circle_pop() -> None:
    """Test the pop method of the Circle class."""
    cgen = Circle(2)
    cgen.reseed(0)
    res = cgen.pop()
    assert res[0] == approx(-1.0)
    assert res[1] == approx(0.0)
    res = cgen.pop()
    assert res[0] == approx(0.0)
    assert res[1] == approx(1.0)


def test_circle_reseed() -> None:
    """Test the reseed method of the Circle class."""
    cgen = Circle(2)
    cgen.reseed(2)
    res = cgen.pop()
    assert res[0] == approx(0.0)
    assert res[1] == approx(-1.0)
    cgen.reseed(0)
    res = cgen.pop()
    assert res[0] == approx(-1.0)
    assert res[1] == approx(0.0)


def test_disk_pop() -> None:
    """Test the pop method of the Disk class."""
    dgen = Disk([2, 3])
    dgen.reseed(0)
    res = dgen.pop()
    assert res[0] == approx(-0.5773502691896257)
    assert res[1] == approx(0.0)
    res = dgen.pop()
    assert res[0] == approx(0.0)
    assert res[1] == approx(0.816496580927726)


def test_disk_reseed() -> None:
    """Test the reseed method of the Disk class."""
    dgen = Disk([2, 3])
    dgen.reseed(2)
    res = dgen.pop()
    assert res[0] == approx(0.0)
    assert res[1] == approx(-0.3333333333333333)
    dgen.reseed(0)
    res = dgen.pop()
    assert res[0] == approx(-0.5773502691896257)
    assert res[1] == approx(0.0)


def test_sphere_pop() -> None:
    """Test the pop method of the Sphere class."""
    sgen = Sphere([2, 3])
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(-0.5)
    assert res[1] == approx(0.8660254037844387)
    assert res[2] == approx(0.0)
    res = sgen.pop()
    assert res[0] == approx(-0.4330127018922197)
    assert res[1] == approx(-0.75)
    assert res[2] == approx(-0.5)


def test_sphere_reseed() -> None:
    """Test the reseed method of the Sphere class."""
    sgen = Sphere([2, 3])
    sgen.reseed(1)
    res = sgen.pop()
    assert res[0] == approx(-0.4330127018922197)
    assert res[1] == approx(-0.75)
    assert res[2] == approx(-0.5)
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(-0.5)
    assert res[1] == approx(0.8660254037844387)
    assert res[2] == approx(0.0)


def test_sphere3hopf_pop() -> None:
    """Test the pop method of the Sphere3Hopf class."""
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(-0.22360679774997898)
    assert res[1] == approx(0.3872983346207417)
    assert res[2] == approx(0.4472135954999573)
    assert res[3] == approx(-0.7745966692414837)


def test_sphere3hopf_reseed() -> None:
    """Test the reseed method of the Sphere3Hopf class."""
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(1)
    res = sgen.pop()
    assert res[0] == approx(-0.3162277660168382)
    assert res[1] == approx(-0.547722557505166)
    assert res[2] == approx(0.6708203932499367)
    assert res[3] == approx(-0.38729833462074204)
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(-0.22360679774997898)
    assert res[1] == approx(0.3872983346207417)
    assert res[2] == approx(0.4472135954999573)
    assert res[3] == approx(-0.7745966692414837)


def test_halton_n_reseed() -> None:
    """Test the reseed method of the HaltonN class."""
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(1)
    res = hgen.pop()
    assert res[0] == approx(0.25)
    assert res[1] == approx(2 / 3)
    assert res[2] == approx(2 / 5)
    hgen.reseed(0)
    res = hgen.pop()
    assert res[0] == approx(0.5)
    assert res[1] == approx(1 / 3)
    assert res[2] == approx(1 / 5)
