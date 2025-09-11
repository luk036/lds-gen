from lds_gen.ilds import Halton, VdCorput


def test_vdcorput():
    vgen = VdCorput(2, 10)
    vgen.reseed(0)
    assert vgen.pop() == 512


def test_halton():
    hgen = Halton([2, 3], [11, 7])
    hgen.reseed(0)
    assert hgen.pop() == [1024, 729]
