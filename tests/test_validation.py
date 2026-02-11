"""Unit tests for validation utilities."""

import warnings

import pytest

from lds_gen.validation import (
    PRIME_TABLE,
    is_prime,
    validate_base,
    validate_bases,
    validate_scale,
)


class TestIsPrime:
    """Test the is_prime function."""

    def test_small_primes(self) -> None:
        """Test that small prime numbers are correctly identified."""
        assert is_prime(2) is True
        assert is_prime(3) is True
        assert is_prime(5) is True
        assert is_prime(7) is True
        assert is_prime(11) is True
        assert is_prime(13) is True

    def test_small_composites(self) -> None:
        """Test that small composite numbers are correctly identified."""
        assert is_prime(4) is False
        assert is_prime(6) is False
        assert is_prime(8) is False
        assert is_prime(9) is False
        assert is_prime(10) is False
        assert is_prime(12) is False

    def test_edge_cases(self) -> None:
        """Test edge cases for is_prime function."""
        assert is_prime(0) is False
        assert is_prime(1) is False
        assert is_prime(2) is True  # Smallest prime
        assert is_prime(-1) is False
        assert is_prime(-7) is False

    def test_larger_primes(self) -> None:
        """Test that larger prime numbers are correctly identified."""
        assert is_prime(97) is True
        assert is_prime(101) is True
        assert is_prime(997) is True

    def test_larger_composites(self) -> None:
        """Test that larger composite numbers are correctly identified."""
        assert is_prime(100) is False
        assert is_prime(999) is False
        assert is_prime(1001) is False

    def test_first_1000_primes(self) -> None:
        """Verify that all numbers in PRIME_TABLE are actually prime."""
        for prime in PRIME_TABLE:
            assert is_prime(prime) is True


class TestValidateBase:
    """Test the validate_base function."""

    def test_valid_prime_base(self) -> None:
        """Test that valid prime bases pass validation."""
        validate_base(2)
        validate_base(3)
        validate_base(5)
        validate_base(97)

    def test_valid_non_prime_base_warning(self) -> None:
        """Test that non-prime bases trigger warnings."""
        with pytest.warns(UserWarning, match="Non-prime base.*"):
            validate_base(4)

        with pytest.warns(UserWarning, match="Non-prime base.*"):
            validate_base(6)

        with pytest.warns(UserWarning, match="Non-prime base.*"):
            validate_base(10)

    def test_invalid_base_type(self) -> None:
        """Test that non-integer bases raise TypeError."""
        with pytest.raises(TypeError, match="base must be an integer"):
            validate_base(2.5)  # type: ignore[arg-type]

        with pytest.raises(TypeError, match="base must be an integer"):
            validate_base("2")  # type: ignore

        with pytest.raises(TypeError, match="base must be an integer"):
            validate_base([2])  # type: ignore

    def test_invalid_base_value(self) -> None:
        """Test that bases < 2 raise ValueError."""
        with pytest.raises(ValueError, match="base must be >= 2"):
            validate_base(1)

        with pytest.raises(ValueError, match="base must be >= 2"):
            validate_base(0)

        with pytest.raises(ValueError, match="base must be >= 2"):
            validate_base(-5)

    def test_custom_generator_name(self) -> None:
        """Test that custom generator names appear in error messages."""
        with pytest.raises(TypeError, match="Halton base must be an integer"):
            validate_base(2.5, generator_name="Halton")  # type: ignore[arg-type]

        with pytest.raises(ValueError, match="VdCorput base must be >= 2"):
            validate_base(1, generator_name="VdCorput")

        # Warning for non-prime base doesn't include generator name prefix
        with pytest.warns(UserWarning, match="Non-prime base"):
            validate_base(4, generator_name="Halton")


class TestValidateBases:
    """Test the validate_bases function."""

    def test_valid_prime_bases(self) -> None:
        """Test that valid prime base lists pass validation."""
        validate_bases([2, 3])
        validate_bases([2, 3, 5])
        validate_bases([97, 101, 103])

    def test_valid_non_prime_bases_warning(self) -> None:
        """Test that non-prime bases in lists trigger warnings."""
        with pytest.warns(UserWarning, match="non-prime base"):
            validate_bases([2, 4])

        with pytest.warns(UserWarning, match="non-prime base"):
            validate_bases([6, 9, 10])

    def test_valid_tuple(self) -> None:
        """Test that tuples are accepted as input."""
        validate_bases((2, 3))  # type: ignore[arg-type]
        validate_bases((2, 3, 5))  # type: ignore[arg-type]

    def test_invalid_type(self) -> None:
        """Test that non-list/tuple inputs raise TypeError."""
        with pytest.raises(TypeError, match="bases must be a list or tuple"):
            validate_bases(2)  # type: ignore

        with pytest.raises(TypeError, match="bases must be a list or tuple"):
            validate_bases("2,3")  # type: ignore

    def test_empty_list(self) -> None:
        """Test that empty lists raise ValueError."""
        with pytest.raises(ValueError, match="bases cannot be empty"):
            validate_bases([])

    def test_invalid_base_type_in_list(self) -> None:
        """Test that non-integer bases in lists raise TypeError."""
        with pytest.raises(TypeError, match=r"base\[0\] must be an integer"):
            validate_bases([2.5, 3])  # type: ignore

        with pytest.raises(TypeError, match=r"base\[1\] must be an integer"):
            validate_bases([2, "3"])  # type: ignore

    def test_invalid_base_value_in_list(self) -> None:
        """Test that bases < 2 in lists raise ValueError."""
        with pytest.raises(ValueError, match=r"base\[0\] must be >= 2"):
            validate_bases([1, 3])

        with pytest.raises(ValueError, match=r"base\[1\] must be >= 2"):
            validate_bases([2, 0])

    def test_custom_generator_name(self) -> None:
        """Test that custom generator names appear in messages."""
        with pytest.raises(TypeError, match="Halton bases must be a list or tuple"):
            validate_bases(2, generator_name="Halton")  # type: ignore

        with pytest.raises(ValueError, match="Halton bases cannot be empty"):
            validate_bases([], generator_name="Halton")

        with pytest.warns(UserWarning, match="Halton.*non-prime base"):
            validate_bases([2, 4], generator_name="Halton")


class TestValidateScale:
    """Test the validate_scale function."""

    def test_valid_scale(self) -> None:
        """Test that valid scale values pass validation."""
        validate_scale(1)
        validate_scale(32)
        validate_scale(64)

    def test_large_scale_warning(self) -> None:
        """Test that scales > 64 trigger warnings."""
        with pytest.warns(UserWarning, match="scale.*is large"):
            validate_scale(65)

        with pytest.warns(UserWarning, match="scale.*is large"):
            validate_scale(100)

    def test_invalid_scale_type(self) -> None:
        """Test that non-integer scales raise TypeError."""
        with pytest.raises(TypeError, match="scale must be an integer"):
            validate_scale(1.5)  # type: ignore

        with pytest.raises(TypeError, match="scale must be an integer"):
            validate_scale("32")  # type: ignore

    def test_invalid_scale_value(self) -> None:
        """Test that scales < 1 raise ValueError."""
        with pytest.raises(ValueError, match="scale must be >= 1"):
            validate_scale(0)

        with pytest.raises(ValueError, match="scale must be >= 1"):
            validate_scale(-5)

    def test_custom_generator_name(self) -> None:
        """Test that custom generator names appear in messages."""
        with pytest.raises(TypeError, match="VdCorput scale must be an integer"):
            validate_scale(1.5, generator_name="VdCorput")  # type: ignore

        with pytest.raises(ValueError, match="Halton scale must be >= 1"):
            validate_scale(0, generator_name="Halton")

        with pytest.warns(UserWarning, match="Halton.*scale.*is large"):
            validate_scale(100, generator_name="Halton")
