#pragma once

#include <cmath>
#include <cstdint>
#include <numbers>
#include <vector>
#include <memory>
#include <algorithm>
#include <numeric>
#include <span>
#include <array>

namespace lds_gen {

constexpr double TWO_PI = 2.0 * std::numbers::pi;

// Van der Corput sequence function
double vdc(std::uint64_t k, std::uint64_t base = 2);

// Van der Corput sequence generator class
class VdCorput {
public:
    explicit VdCorput(std::uint64_t base = 2);

    double pop();
    void reseed(std::uint64_t seed);

private:
    std::uint64_t count_;
    std::uint64_t base_;
    std::vector<double> rev_lst_;
};

// Halton sequence generator (2D)
class Halton {
public:
    explicit Halton(std::span<const std::uint64_t> base);

    std::array<double, 2> pop();
    void reseed(std::uint64_t seed);

private:
    VdCorput vdc0_;
    VdCorput vdc1_;
};

// Circle sequence generator
class Circle {
public:
    explicit Circle(std::uint64_t base);

    std::array<double, 2> pop();
    void reseed(std::uint64_t seed);

private:
    VdCorput vdc_;
};

// Disk sequence generator
class Disk {
public:
    explicit Disk(std::span<const std::uint64_t> base);

    std::array<double, 2> pop();
    void reseed(std::uint64_t seed);

private:
    VdCorput vdc0_;
    VdCorput vdc1_;
};

// Sphere sequence generator
class Sphere {
public:
    explicit Sphere(std::span<const std::uint64_t> base);

    std::array<double, 3> pop();
    void reseed(std::uint64_t seed);

private:
    VdCorput vdc_;
    Circle cirgen_;
};

// Sphere3 Hopf sequence generator
class Sphere3Hopf {
public:
    explicit Sphere3Hopf(std::span<const std::uint64_t> base);

    std::array<double, 4> pop();
    void reseed(std::uint64_t seed);

private:
    VdCorput vdc0_;
    VdCorput vdc1_;
    VdCorput vdc2_;
};

// N-dimensional Halton sequence generator
class HaltonN {
public:
    explicit HaltonN(std::span<const std::uint64_t> base);

    std::vector<double> pop();
    void reseed(std::uint64_t seed);

private:
    std::vector<VdCorput> vdcs_;
};

// First 1000 prime numbers
extern const std::vector<std::uint64_t> PRIME_TABLE;

} // namespace lds_gen