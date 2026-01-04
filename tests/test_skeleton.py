import pytest
from unittest.mock import patch

from lds_gen.skeleton import fib, main, run

__author__ = "Wai-Shing Luk"
__copyright__ = "Wai-Shing Luk"
__license__ = "MIT"


def test_fib() -> None:
    """API Tests"""
    assert fib(1) == 1
    assert fib(2) == 1
    assert fib(7) == 13
    with pytest.raises(AssertionError):
        fib(-10)


def test_main(capsys: pytest.CaptureFixture) -> None:
    """CLI Tests"""
    # capsys is a pytest fixture that allows asserts against stdout/stderr
    # https://docs.pytest.org/en/stable/capture.html
    main(["7"])
    captured = capsys.readouterr()
    assert "The 7-th Fibonacci number is 13" in captured.out


def test_run(capsys: pytest.CaptureFixture) -> None:
    """Test run() function that calls main with sys.argv"""
    with patch("sys.argv", ["skeleton", "5"]):
        run()
        captured = capsys.readouterr()
        assert "The 5-th Fibonacci number is 5" in captured.out
