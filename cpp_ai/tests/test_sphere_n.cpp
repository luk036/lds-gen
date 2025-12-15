#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"
#include "lds_gen/sphere_n.hpp"
#include <vector>
#include <cmath>
#include <numeric>

TEST_CASE("Test linspace function") {
    auto result = lds_gen::linspace(0.0, 1.0, 5);
    REQUIRE(result.size() == 5);
    CHECK(result[0] == doctest::Approx(0.0));
    CHECK(result[1] == doctest::Approx(0.25));
    CHECK(result[2] == doctest::Approx(0.5));
    CHECK(result[3] == doctest::Approx(0.75));
    CHECK(result[4] == doctest::Approx(1.0));

    result = lds_gen::linspace(0.0, 1.0, 1);
    REQUIRE(result.size() == 1);
    CHECK(result[0] == doctest::Approx(0.0));

    result = lds_gen::linspace(-1.0, 1.0, 3);
    REQUIRE(result.size() == 3);
    CHECK(result[0] == doctest::Approx(-1.0));
    CHECK(result[1] == doctest::Approx(0.0));
    CHECK(result[2] == doctest::Approx(1.0));
}

TEST_CASE("Test simple_interp function") {
    std::vector<double> xp = {0.0, 1.0, 2.0, 3.0};
    std::vector<double> yp = {0.0, 2.0, 4.0, 6.0}; // Linear function y = 2x

    CHECK(lds_gen::simple_interp(0.5, xp, yp) == doctest::Approx(1.0));
    CHECK(lds_gen::simple_interp(1.5, xp, yp) == doctest::Approx(3.0));
    CHECK(lds_gen::simple_interp(-0.5, xp, yp) == doctest::Approx(0.0));
    CHECK(lds_gen::simple_interp(3.5, xp, yp) == doctest::Approx(6.0));
    CHECK(lds_gen::simple_interp(2.0, xp, yp) == doctest::Approx(4.0));
}

TEST_CASE("Test get_tp function") {
    auto tp0 = lds_gen::get_tp(0);
    REQUIRE(tp0.size() == 300);
    CHECK(tp0[0] == doctest::Approx(0.0));
    CHECK(tp0.back() == doctest::Approx(lds_gen::PI).epsilon(1e-10));

    auto tp1 = lds_gen::get_tp(1);
    REQUIRE(tp1.size() == 300);
    CHECK(tp1[0] == doctest::Approx(-std::cos(0.0)));
    CHECK(tp1.back() == doctest::Approx(-std::cos(lds_gen::PI)).epsilon(1e-10));

    auto tp2 = lds_gen::get_tp(2);
    REQUIRE(tp2.size() == 300);
}

TEST_CASE("Test Sphere3 basic functionality") {
    lds_gen::Sphere3 sgen({2, 3, 5});
    sgen.reseed(0);

    auto point = sgen.pop();
    REQUIRE(point.size() == 4);

    // Check if point is on unit 3-sphere (approximately)
    double radius_sq = std::inner_product(point.begin(), point.end(), point.begin(), 0.0);
    CHECK(radius_sq == doctest::Approx(1.0).epsilon(1e-10));

    // Check values are in reasonable range
    for (double coord : point) {
        CHECK(coord >= -1.0 - 1e-10);
        CHECK(coord <= 1.0 + 1e-10);
    }
}

TEST_CASE("Test Sphere3 consistency") {
    std::vector<std::vector<std::uint64_t>> bases = {
        {2, 3, 5},
        {2, 5, 3},
        {3, 2, 7}
    };

    for (const auto& base : bases) {
        lds_gen::Sphere3 sgen(base);
        sgen.reseed(0);

        // Generate multiple points
        std::vector<std::vector<double>> points;
        for (int i = 0; i < 5; ++i) {
            points.push_back(sgen.pop());
        }

        // Check all points are on unit 3-sphere
        for (const auto& point : points) {
            double radius_sq = std::inner_product(point.begin(), point.end(), point.begin(), 0.0);
            CHECK(radius_sq == doctest::Approx(1.0).epsilon(1e-10));
        }
    }
}

TEST_CASE("Test Sphere3 reseed functionality") {
    lds_gen::Sphere3 sgen({2, 3, 5});

    // Generate sequence with seed 0
    sgen.reseed(0);
    std::vector<std::vector<double>> seq1;
    for (int i = 0; i < 3; ++i) {
        seq1.push_back(sgen.pop());
    }

    // Generate sequence with seed 0 again
    sgen.reseed(0);
    std::vector<std::vector<double>> seq2;
    for (int i = 0; i < 3; ++i) {
        seq2.push_back(sgen.pop());
    }

    // Should be identical
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 4; ++j) {
            CHECK(seq1[i][j] == doctest::Approx(seq2[i][j]).epsilon(1e-10));
        }
    }

    // Different seed should give different sequence
    sgen.reseed(1);
    std::vector<std::vector<double>> seq3;
    for (int i = 0; i < 3; ++i) {
        seq3.push_back(sgen.pop());
    }

    // Should be different from seed 0
    bool different = false;
    for (int i = 0; i < 3 && !different; ++i) {
        for (int j = 0; j < 4; ++j) {
            if (std::abs(seq1[i][j] - seq3[i][j]) > 1e-10) {
                different = true;
                break;
            }
        }
    }
    CHECK(different);
}

TEST_CASE("Test SphereN basic functionality") {
    // Test 4-sphere (5D)
    lds_gen::SphereN sgen({2, 3, 5, 7});
    sgen.reseed(0);

    auto point = sgen.pop();
    REQUIRE(point.size() == 5); // 4 bases produce 5D point

    // Check if point is on unit 4-sphere (approximately)
    double radius_sq = std::inner_product(point.begin(), point.end(), point.begin(), 0.0);
    CHECK(radius_sq == doctest::Approx(1.0).epsilon(1e-10));
}

TEST_CASE("Test SphereN higher dimensions") {
    // Test 5-sphere (6D)
    lds_gen::SphereN sgen({2, 3, 5, 7, 11});
    sgen.reseed(0);

    auto point = sgen.pop();
    REQUIRE(point.size() == 6); // 5 bases produce 6D point

    // Check if point is on unit 5-sphere (approximately)
    double radius_sq = std::inner_product(point.begin(), point.end(), point.begin(), 0.0);
    CHECK(radius_sq == doctest::Approx(1.0).epsilon(1e-10));
}

TEST_CASE("Test SphereN reseed functionality") {
    lds_gen::SphereN sgen({2, 3, 5, 7});

    // Generate sequence with seed 0
    sgen.reseed(0);
    std::vector<std::vector<double>> seq1;
    for (int i = 0; i < 3; ++i) {
        seq1.push_back(sgen.pop());
    }

    // Generate sequence with seed 0 again
    sgen.reseed(0);
    std::vector<std::vector<double>> seq2;
    for (int i = 0; i < 3; ++i) {
        seq2.push_back(sgen.pop());
    }

    // Should be identical
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 4; ++j) {
            CHECK(seq1[i][j] == doctest::Approx(seq2[i][j]).epsilon(1e-10));
        }
    }
}

TEST_CASE("Test comparison with Python implementation") {
    // Expected values from Python doctest examples
    std::vector<double> expected_sphere3 = {
        0.2913440162992141,
        0.8966646826186098,
        -0.33333333333333337,
        6.123233995736766e-17
    };

    std::vector<double> expected_spheren = {
        0.4809684718990214,
        0.6031153874276115,
        -0.5785601510223212,
        0.2649326520763179,
        6.123233995736766e-17
    };

    // Test Sphere3
    lds_gen::Sphere3 sgen3({2, 3, 5});
    sgen3.reseed(0);
    auto result3 = sgen3.pop();

    REQUIRE(result3.size() == expected_sphere3.size());
    for (std::size_t i = 0; i < result3.size(); ++i) {
        CHECK(result3[i] == doctest::Approx(expected_sphere3[i]).epsilon(1e-10));
    }

    // Test SphereN
    lds_gen::SphereN sgenN({2, 3, 5, 7});
    sgenN.reseed(0);
    auto resultN = sgenN.pop();

    REQUIRE(resultN.size() == expected_spheren.size());
    for (std::size_t i = 0; i < resultN.size(); ++i) {
        CHECK(resultN[i] == doctest::Approx(expected_spheren[i]).epsilon(1e-10));
    }
}