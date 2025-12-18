#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"
#include "lds_gen/lds.hpp"
#include <vector>
#include <cmath>
#include <array>

TEST_CASE("Test vdc function") {
    CHECK(lds_gen::vdc(11, 2) == doctest::Approx(0.8125));
}

TEST_CASE("Test VdCorput class") {
    lds_gen::VdCorput vgen(2);
    vgen.reseed(0);

    CHECK(vgen.pop() == doctest::Approx(0.5));
    CHECK(vgen.pop() == doctest::Approx(0.25));
    CHECK(vgen.pop() == doctest::Approx(0.75));
    CHECK(vgen.pop() == doctest::Approx(0.125));
}

TEST_CASE("Test VdCorput reseed") {
    lds_gen::VdCorput vgen(2);
    vgen.reseed(5);
    CHECK(vgen.pop() == doctest::Approx(0.375));

    vgen.reseed(0);
    CHECK(vgen.pop() == doctest::Approx(0.5));
}

TEST_CASE("Test Halton class") {
    std::array<std::uint64_t, 2> base = {2, 3};
    lds_gen::Halton hgen(base);
    hgen.reseed(0);

    auto res = hgen.pop();
    CHECK(res[0] == doctest::Approx(0.5));
    CHECK(res[1] == doctest::Approx(1.0 / 3.0));

    res = hgen.pop();
    CHECK(res[0] == doctest::Approx(0.25));
    CHECK(res[1] == doctest::Approx(2.0 / 3.0));
}

TEST_CASE("Test Circle class") {
    lds_gen::Circle cgen(2);
    cgen.reseed(0);

    auto res = cgen.pop();
    CHECK(res[0] == doctest::Approx(-1.0).epsilon(1e-10));
    CHECK(res[1] == doctest::Approx(0.0).epsilon(1e-10));

    res = cgen.pop();
    CHECK(res[0] == doctest::Approx(0.0).epsilon(1e-10));
    CHECK(res[1] == doctest::Approx(1.0).epsilon(1e-10));
}

TEST_CASE("Test Disk class") {
    std::array<std::uint64_t, 2> base = {2, 3};
    lds_gen::Disk dgen(base);
    dgen.reseed(0);

    auto res = dgen.pop();
    CHECK(res[0] == doctest::Approx(-0.5773502691896257).epsilon(1e-10));
    CHECK(res[1] == doctest::Approx(0.0).epsilon(1e-10));
}

TEST_CASE("Test Sphere class") {
    std::array<std::uint64_t, 2> base = {2, 3};
    lds_gen::Sphere sgen(base);
    sgen.reseed(0);

    auto res = sgen.pop();
    CHECK(res[0] == doctest::Approx(-0.5).epsilon(1e-10));
    CHECK(res[1] == doctest::Approx(0.8660254037844387).epsilon(1e-10));
    CHECK(res[2] == doctest::Approx(0.0).epsilon(1e-10));
}

TEST_CASE("Test Sphere3Hopf class") {
    std::array<std::uint64_t, 3> base = {2, 3, 5};
    lds_gen::Sphere3Hopf sp3hgen(base);
    sp3hgen.reseed(0);

    auto res = sp3hgen.pop();
    CHECK(res[0] == doctest::Approx(-0.22360679774997885).epsilon(1e-10));
    CHECK(res[1] == doctest::Approx(0.3872983346207417).epsilon(1e-10));
    CHECK(res[2] == doctest::Approx(0.4472135954999573).epsilon(1e-10));
    CHECK(res[3] == doctest::Approx(-0.7745966692414837).epsilon(1e-10));
}

TEST_CASE("Test HaltonN class") {
    std::array<std::uint64_t, 3> base = {2, 3, 5};
    lds_gen::HaltonN hgen(base);
    hgen.reseed(0);

    auto res = hgen.pop();
    CHECK(res[0] == doctest::Approx(0.5));
    CHECK(res[1] == doctest::Approx(1.0 / 3.0));
    CHECK(res[2] == doctest::Approx(0.2));

    res = hgen.pop();
    CHECK(res[0] == doctest::Approx(0.25));
    CHECK(res[1] == doctest::Approx(2.0 / 3.0));
    CHECK(res[2] == doctest::Approx(0.4));
}

TEST_CASE("Test PRIME_TABLE") {
    CHECK(lds_gen::PRIME_TABLE[0] == 2);
    CHECK(lds_gen::PRIME_TABLE[1] == 3);
    CHECK(lds_gen::PRIME_TABLE[2] == 5);
    CHECK(lds_gen::PRIME_TABLE.size() >= 436);
}