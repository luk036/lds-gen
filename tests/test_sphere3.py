from pytest import approx

from lds_gen.sphere_n import Sphere3


def test_sphere3() -> None:
    """assert that the sphere3hopf generator produces the correct values"""
    sgen = Sphere3([2, 3, 5])
    sgen.reseed(0)
    res = sgen.pop()
    assert res[0] == approx(0.2913440162992141)
    assert res[1] == approx(0.8966646826186098)
    assert res[2] == approx(-0.33333333333333337)
    assert res[3] == approx(6.123233995736766e-17)
