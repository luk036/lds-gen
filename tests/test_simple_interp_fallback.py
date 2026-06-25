"""Test for simple_interp fallback case."""
from lds_gen.sphere_n import simple_interp


def test_simple_interp_fallback() -> None:
    """Test the fallback case in simple_interp."""
    # reachable only with non-monotonic xp where no interval matches
    result = simple_interp(2.5, [1.0, 3.0, 2.0, 4.0], [2.0, 6.0, 4.0, 8.0])
    assert result is not None

    result = simple_interp(3.5, [2.0, 4.0, 1.0, 5.0], [4.0, 8.0, 2.0, 10.0])
    assert result is not None

    result = simple_interp(0.5, [1.0, 3.0, 2.0, 4.0], [2.0, 6.0, 4.0, 8.0])
    assert result == 2.0

    result = simple_interp(4.5, [1.0, 3.0, 2.0, 4.0], [2.0, 6.0, 4.0, 8.0])
    assert result == 8.0
