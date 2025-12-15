#pragma once

#include "lds_gen/lds.hpp"
#include <cmath>
#include <cstdint>
#include <vector>
#include <memory>
#include <numbers>

namespace lds_gen {

constexpr double PI = std::numbers::pi;
constexpr double HALF_PI = PI / 2.0;

// Simple implementation of numpy.linspace
std::vector<double> linspace(double start, double stop, std::size_t num);

// Simple implementation of numpy.interp for 1D interpolation
double simple_interp(double x, const std::vector<double>& xp, const std::vector<double>& yp);

// Calculates the table-lookup of the mapping function for n
std::vector<double> get_tp(int n);

// Base class for sphere generators
class SphereGen {
public:
    virtual ~SphereGen() = default;
    virtual std::vector<double> pop() = 0;
    virtual void reseed(std::uint64_t seed) = 0;
};

// 3-Sphere sequence generator
class Sphere3 : public SphereGen {
public:
    explicit Sphere3(const std::vector<std::uint64_t>& base);

    std::vector<double> pop() override;
    void reseed(std::uint64_t seed) override;

private:
    VdCorput vdc_;
    Sphere sphere2_;
};

// Wrapper class to make Sphere compatible with SphereGen interface
class SphereWrapper : public SphereGen {
public:
    explicit SphereWrapper(const std::vector<std::uint64_t>& base);
    
    std::vector<double> pop() override;
    void reseed(std::uint64_t seed) override;
    
private:
    Sphere sphere_;
};

// Sphere-N sequence generator
class SphereN : public SphereGen {
public:
    explicit SphereN(const std::vector<std::uint64_t>& base);
    
    std::vector<double> pop() override;
    void reseed(std::uint64_t seed) override;
    
private:
    VdCorput vdc_;
    std::unique_ptr<SphereGen> s_gen_;
    int n_;
    double range_;
};
} // namespace lds_gen