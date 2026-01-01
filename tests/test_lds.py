import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
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


def test_vdcorput_thread_safety() -> None:
    """Test that VdCorput class is thread-safe."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    results = []
    errors = []

    def worker(num_iterations: int) -> None:
        try:
            for _ in range(num_iterations):
                results.append(vgen.pop())
        except Exception as e:
            errors.append(e)

    # Create multiple threads that call pop() concurrently
    threads = []
    num_threads = 10
    iterations_per_thread = 100

    for _ in range(num_threads):
        thread = threading.Thread(target=worker, args=(iterations_per_thread,))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread

    # Verify all results are unique (no duplicates from race conditions)
    assert len(set(results)) == len(results), (
        "Duplicate values found - possible race condition"
    )

    # Verify results are within expected range [0, 1]
    for result in results:
        assert 0.0 <= result <= 1.0, f"Result {result} out of range"


def test_vdcorput_concurrent_reseed() -> None:
    """Test that VdCorput handles concurrent reseed() calls safely."""
    vgen = VdCorput(3)
    results = []
    errors = []

    def worker(seed: int, num_iterations: int) -> None:
        try:
            vgen.reseed(seed)
            for _ in range(num_iterations):
                results.append((seed, vgen.pop()))
        except Exception as e:
            errors.append(e)

    # Create multiple threads that reseed and pop concurrently
    threads = []
    num_threads = 5
    iterations_per_thread = 20

    for i in range(num_threads):
        thread = threading.Thread(target=worker, args=(i * 10, iterations_per_thread))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread


def test_halton_thread_safety() -> None:
    """Test that Halton class is thread-safe."""
    hgen = Halton([2, 3])
    hgen.reseed(0)
    results = []
    errors = []

    def worker(num_iterations: int) -> None:
        try:
            for _ in range(num_iterations):
                results.append(hgen.pop())
        except Exception as e:
            errors.append(e)

    # Create multiple threads that call pop() concurrently
    threads = []
    num_threads = 8
    iterations_per_thread = 50

    for _ in range(num_threads):
        thread = threading.Thread(target=worker, args=(iterations_per_thread,))
        threads.append(thread)

    # Start all threads
    for thread in threads:
        thread.start()

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

    # Verify no errors occurred
    assert len(errors) == 0, f"Errors occurred: {errors}"

    # Verify we got the expected number of results
    assert len(results) == num_threads * iterations_per_thread

    # Verify all results are unique (no duplicates from race conditions)
    result_tuples = [tuple(result) for result in results]
    assert len(set(result_tuples)) == len(result_tuples), (
        "Duplicate values found - possible race condition"
    )

    # Verify results are within expected range
    for result in results:
        assert len(result) == 2
        assert 0.0 <= result[0] <= 1.0, f"Result[0] {result[0]} out of range"
        assert 0.0 <= result[1] <= 1.0, f"Result[1] {result[1]} out of range"


def test_composite_thread_safety() -> None:
    """Test that composite classes (Circle, Disk, Sphere) are thread-safe."""
    test_classes: list[tuple[type, list]] = [
        (Circle, [2]),
        (Disk, [[2, 3]]),
        (Sphere, [[2, 3]]),
        (Sphere3Hopf, [[2, 3, 5]]),
        (HaltonN, [[2, 3, 5, 7]]),
    ]

    for cls, args in test_classes:
        if cls is Circle:
            gen = cls(args[0])  # Circle expects an int, not a list
        else:
            gen = cls(*args)
        gen.reseed(0)
        results = []
        errors = []

        def worker(num_iterations: int) -> None:
            try:
                for _ in range(num_iterations):
                    results.append(gen.pop())
            except Exception as e:
                errors.append(e)

        # Create multiple threads that call pop() concurrently
        threads = []
        num_threads = 5
        iterations_per_thread = 20

        for _ in range(num_threads):
            thread = threading.Thread(target=worker, args=(iterations_per_thread,))
            threads.append(thread)

        # Start all threads
        for thread in threads:
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # Verify no errors occurred
        assert len(errors) == 0, f"Errors occurred in {cls.__name__}: {errors}"

        # Verify we got the expected number of results
        assert len(results) == num_threads * iterations_per_thread

        # Verify all results are unique (no duplicates from race conditions)
        result_tuples = [tuple(result) for result in results]
        assert len(set(result_tuples)) == len(result_tuples), (
            f"Duplicate values found in {cls.__name__} - possible race condition"
        )


def test_thread_pool_executor() -> None:
    """Test thread safety using ThreadPoolExecutor."""
    vgen = VdCorput(2)
    vgen.reseed(0)
    results = []

    def worker(num_iterations: int) -> list:
        return [vgen.pop() for _ in range(num_iterations)]

    # Use ThreadPoolExecutor for concurrent execution
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(worker, 50) for _ in range(10)]

        for future in as_completed(futures):
            results.extend(future.result())

    # Verify we got the expected number of results
    assert len(results) == 500  # 10 workers * 50 iterations each

    # Verify all results are unique
    assert len(set(results)) == len(results), (
        "Duplicate values found - possible race condition"
    )
