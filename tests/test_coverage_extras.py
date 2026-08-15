"""Coverage-extras unit tests for the lds_gen package.

These tests exercise the iterator protocol (__iter__/__next__), pop_batch
and iter_batch methods that the existing test suite does not call, raising
statement and branch coverage of the lds_gen package to ~100%.
"""

from math import sqrt

from pytest import approx, raises

from lds_gen.ilds import Halton as IntHalton
from lds_gen.ilds import VdCorput as IntVdCorput
from lds_gen.lds import Circle, Disk, Halton, HaltonN, Sphere, Sphere3Hopf, VdCorput
from lds_gen.sphere_n import Sphere3, SphereN, simple_interp


def _assert_unit_norm(points, ndim: int) -> None:
    """Assert every point lies on the unit sphere of the given dimension."""
    for point in points:
        assert len(point) == ndim
        assert sqrt(sum(c * c for c in point)) == approx(1.0)


def test_vdcorput_iter() -> None:
    """VdCorput.__iter__ returns self and __next__ returns the next value."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    assert iter(vgen) is vgen
    assert next(vgen) == 0.5


def test_vdcorput_pop_batch_raises() -> None:
    """VdCorput.pop_batch raises ValueError when n is not positive."""
    vgen = VdCorput(2)
    with raises(ValueError, match="n must be positive"):
        vgen.pop_batch(0)
    with raises(ValueError, match="n must be positive"):
        vgen.pop_batch(-1)


def test_halton_iter() -> None:
    """Halton.__iter__ returns self and __next__ returns the next point."""
    hgen = Halton([2, 3])
    hgen.reseed(0)
    assert iter(hgen) is hgen
    res = next(hgen)
    assert res[0] == 0.5
    assert res[1] == approx(1 / 3)


def test_halton_pop_batch_raises() -> None:
    """Halton.pop_batch raises ValueError when n is not positive."""
    hgen = Halton([2, 3])
    with raises(ValueError, match="n must be positive"):
        hgen.pop_batch(0)


def test_halton_iter_batch_raises() -> None:
    """Halton.iter_batch raises ValueError when n is not positive."""
    hgen = Halton([2, 3])
    with raises(ValueError, match="n must be positive"):
        list(hgen.iter_batch(0))


def test_circle_iter() -> None:
    """Circle.__iter__ returns self and __next__ returns a unit point."""
    cgen = Circle(2)
    cgen.reseed(0)
    assert iter(cgen) is cgen
    point = next(cgen)
    assert len(point) == 2
    assert sqrt(point[0] ** 2 + point[1] ** 2) == approx(1.0)


def test_circle_pop_batch() -> None:
    """Circle.pop_batch returns unit-circle points and raises for n <= 0."""
    cgen = Circle(2)
    cgen.reseed(0)
    batch = cgen.pop_batch(5)
    assert len(batch) == 5
    _assert_unit_norm(batch, 2)
    with raises(ValueError, match="n must be positive"):
        cgen.pop_batch(0)


def test_circle_iter_batch() -> None:
    """Circle.iter_batch matches pop_batch and raises for n <= 0."""
    cgen = Circle(2)
    cgen.reseed(0)
    batch = cgen.pop_batch(5)
    cgen.reseed(0)
    lazy = list(cgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(cgen.iter_batch(0))


def test_disk_iter() -> None:
    """Disk.__iter__ returns self and __next__ returns an in-disk point."""
    dgen = Disk([2, 3])
    dgen.reseed(0)
    assert iter(dgen) is dgen
    point = next(dgen)
    assert len(point) == 2
    assert sqrt(point[0] ** 2 + point[1] ** 2) <= 1.0


def test_disk_pop_batch() -> None:
    """Disk.pop_batch returns in-disk points and raises for n <= 0."""
    dgen = Disk([2, 3])
    dgen.reseed(0)
    batch = dgen.pop_batch(5)
    assert len(batch) == 5
    for point in batch:
        assert sqrt(point[0] ** 2 + point[1] ** 2) <= 1.0
    with raises(ValueError, match="n must be positive"):
        dgen.pop_batch(0)


def test_disk_iter_batch() -> None:
    """Disk.iter_batch matches pop_batch and raises for n <= 0."""
    dgen = Disk([2, 3])
    dgen.reseed(0)
    batch = dgen.pop_batch(5)
    dgen.reseed(0)
    lazy = list(dgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(dgen.iter_batch(0))


def test_sphere_iter() -> None:
    """Sphere.__iter__ returns self and __next__ returns a unit point."""
    sgen = Sphere([2, 3])
    sgen.reseed(0)
    assert iter(sgen) is sgen
    point = next(sgen)
    assert len(point) == 3
    assert sqrt(sum(c * c for c in point)) == approx(1.0)


def test_sphere_pop_batch() -> None:
    """Sphere.pop_batch returns unit-sphere points and raises for n <= 0."""
    sgen = Sphere([2, 3])
    sgen.reseed(0)
    batch = sgen.pop_batch(5)
    assert len(batch) == 5
    _assert_unit_norm(batch, 3)
    with raises(ValueError, match="n must be positive"):
        sgen.pop_batch(0)


def test_sphere_iter_batch() -> None:
    """Sphere.iter_batch matches pop_batch and raises for n <= 0."""
    sgen = Sphere([2, 3])
    sgen.reseed(0)
    batch = sgen.pop_batch(5)
    sgen.reseed(0)
    lazy = list(sgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(sgen.iter_batch(0))


def test_sphere3hopf_iter() -> None:
    """Sphere3Hopf.__iter__ returns self and __next__ returns a unit point."""
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(0)
    assert iter(sgen) is sgen
    point = next(sgen)
    assert len(point) == 4
    assert sqrt(sum(c * c for c in point)) == approx(1.0)


def test_sphere3hopf_pop_batch() -> None:
    """Sphere3Hopf.pop_batch returns unit points and raises for n <= 0."""
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(0)
    batch = sgen.pop_batch(5)
    assert len(batch) == 5
    _assert_unit_norm(batch, 4)
    with raises(ValueError, match="n must be positive"):
        sgen.pop_batch(0)


def test_sphere3hopf_iter_batch() -> None:
    """Sphere3Hopf.iter_batch matches pop_batch and raises for n <= 0."""
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(0)
    batch = sgen.pop_batch(5)
    sgen.reseed(0)
    lazy = list(sgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(sgen.iter_batch(0))


def test_halton_n_iter() -> None:
    """HaltonN.__iter__ returns self and __next__ returns the next point."""
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)
    assert iter(hgen) is hgen
    res = next(hgen)
    assert len(res) == 3
    assert res[0] == 0.5
    assert res[1] == approx(1 / 3)
    assert res[2] == approx(1 / 5)


def test_halton_n_pop_batch() -> None:
    """HaltonN.pop_batch returns 3D points and raises for n <= 0."""
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)
    batch = hgen.pop_batch(5)
    assert len(batch) == 5
    for point in batch:
        assert len(point) == 3
    with raises(ValueError, match="n must be positive"):
        hgen.pop_batch(0)


def test_halton_n_iter_batch() -> None:
    """HaltonN.iter_batch matches pop_batch and raises for n <= 0."""
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)
    batch = hgen.pop_batch(5)
    hgen.reseed(0)
    lazy = list(hgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(hgen.iter_batch(0))


def test_int_vdcorput_iter() -> None:
    """Integer VdCorput.__iter__ returns self and __next__ returns a value."""
    vgen = IntVdCorput(2, 10)
    vgen.reseed(0)
    assert iter(vgen) is vgen
    assert next(vgen) == 512


def test_int_vdcorput_pop_batch() -> None:
    """Integer VdCorput.pop_batch returns values and raises for n <= 0."""
    vgen = IntVdCorput(2, 10)
    vgen.reseed(0)
    batch = vgen.pop_batch(5)
    assert len(batch) == 5
    assert all(isinstance(x, int) for x in batch)
    with raises(ValueError, match="n must be positive"):
        vgen.pop_batch(0)


def test_int_vdcorput_iter_batch() -> None:
    """Integer VdCorput.iter_batch matches pop_batch and raises for n <= 0."""
    vgen = IntVdCorput(2, 10)
    vgen.reseed(0)
    batch = vgen.pop_batch(5)
    vgen.reseed(0)
    lazy = list(vgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(vgen.iter_batch(0))


def test_int_halton_iter() -> None:
    """Integer Halton.__iter__ returns self and __next__ returns a point."""
    hgen = IntHalton([2, 3], [11, 7])
    hgen.reseed(0)
    assert iter(hgen) is hgen
    res = next(hgen)
    assert res[0] == 1024
    assert res[1] == 729


def test_int_halton_pop_batch() -> None:
    """Integer Halton.pop_batch returns 2D points and raises for n <= 0."""
    hgen = IntHalton([2, 3], [11, 7])
    hgen.reseed(0)
    batch = hgen.pop_batch(5)
    assert len(batch) == 5
    for point in batch:
        assert len(point) == 2
    with raises(ValueError, match="n must be positive"):
        hgen.pop_batch(0)


def test_int_halton_iter_batch() -> None:
    """Integer Halton.iter_batch matches pop_batch and raises for n <= 0."""
    hgen = IntHalton([2, 3], [11, 7])
    hgen.reseed(0)
    batch = hgen.pop_batch(5)
    hgen.reseed(0)
    lazy = list(hgen.iter_batch(5))
    assert batch == lazy
    with raises(ValueError, match="n must be positive"):
        list(hgen.iter_batch(0))


def test_simple_interp_mismatch_length() -> None:
    """simple_interp raises ValueError when xp and yp lengths differ."""
    with raises(ValueError, match="same length"):
        simple_interp(0.5, [0.0, 1.0], [0.0])


def test_simple_interp_empty() -> None:
    """simple_interp raises ValueError when xp is empty."""
    with raises(ValueError, match="non-empty"):
        simple_interp(0.5, [], [])


def test_sphere3_iter() -> None:
    """Sphere3.__iter__ returns self and __next__ returns a unit point."""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)
    assert iter(sgen) is sgen
    point = next(sgen)
    assert len(point) == 4
    assert sqrt(sum(c * c for c in point)) == approx(1.0)


def test_sphere3_pop_batch() -> None:
    """Sphere3.pop_batch returns unit 3-sphere points and raises for n <= 0."""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)
    batch = sgen.pop_batch(3)
    assert len(batch) == 3
    _assert_unit_norm(batch, 4)
    with raises(ValueError, match="n must be positive"):
        sgen.pop_batch(0)


def test_sphere3_iter_batch_raises() -> None:
    """Sphere3.iter_batch raises ValueError when n is not positive."""
    sgen = Sphere3([2, 3, 5])
    with raises(ValueError, match="n must be positive"):
        list(sgen.iter_batch(0))


def test_spheren_iter() -> None:
    """SphereN.__iter__ returns self and __next__ returns a unit point."""
    sgen = SphereN([2, 3, 5, 7])
    sgen.reseed(0)
    assert iter(sgen) is sgen
    point = next(sgen)
    assert len(point) == 5
    assert sqrt(sum(c * c for c in point)) == approx(1.0)


def test_spheren_pop_batch() -> None:
    """SphereN.pop_batch returns unit n-sphere points and raises for n <= 0."""
    sgen = SphereN([2, 3, 5, 7])
    sgen.reseed(0)
    batch = sgen.pop_batch(3)
    assert len(batch) == 3
    _assert_unit_norm(batch, 5)
    with raises(ValueError, match="n must be positive"):
        sgen.pop_batch(0)
