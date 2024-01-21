from pytest import approx

from lds_gen.lds import Circle, Halton, HaltonN, Sphere, Sphere3Hopf, VdCorput, vdc


def test_vdc():
    assert vdc(11, 2) == 0.8125


def test_vdcorput():
    vgen = VdCorput(2)
    vgen.reseed(0)
    assert vgen.pop() == 0.5


def test_halton():
    hgen = Halton([2, 3])
    hgen.reseed(0)
    res = hgen.pop()
    assert res[0] == 0.5


def test_circle():
    cgen = Circle(2)
    cgen.reseed(0)
    res = cgen.pop()
    assert res[1] == -1.0
    res = cgen.pop()
    assert res[0] == 1.0


def test_sphere():
    sgen = Sphere([2, 3])
    sgen.reseed(0)
    res = sgen.pop()
    assert res[1] == approx(-0.5)
    assert res[2] == approx(0.0)
    res = sgen.pop()
    assert res[0] == approx(-0.75)
    assert res[2] == approx(-0.5)


def test_sphere3hopf():
    sgen = Sphere3Hopf([2, 3, 5])
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(-0.22360679774997885)
    assert res[1] == approx(0.3872983346207417)
    assert res[2] == approx(0.44721359549995726)
    assert res[3] == approx(-0.7745966692414837)


def test_halton_n():
    hgen = HaltonN([2, 3, 5])
    hgen.reseed(0)
    res = hgen.pop()
    assert res[0] == 0.5
    assert res[2] == 0.2
    res = hgen.pop()
    assert res[0] == 0.25
    assert res[2] == 0.4
