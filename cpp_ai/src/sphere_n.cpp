#include "lds_gen/sphere_n.hpp"
#include <cmath>
#include <cstdint>
#include <vector>
#include <memory>
#include <stdexcept>
#include <numbers>

namespace lds_gen {

std::vector<double> linspace(double start, double stop, std::size_t num) {
    if (num == 1) {
        return {start};
    }
    
    std::vector<double> result;
    result.reserve(num);
    
    double step = (stop - start) / static_cast<double>(num - 1);
    for (std::size_t i = 0; i < num; ++i) {
        result.push_back(start + static_cast<double>(i) * step);
    }
    
    return result;
}

double simple_interp(double x, const std::vector<double>& xp, const std::vector<double>& yp) {
    if (xp.empty() || yp.empty() || xp.size() != yp.size()) {
        throw std::invalid_argument("xp and yp must be non-empty and same size");
    }
    
    if (x <= xp[0]) {
        return yp[0];
    }
    if (x >= xp.back()) {
        return yp.back();
    }
    
    for (std::size_t i = 0; i < xp.size() - 1; ++i) {
        if (xp[i] <= x && x <= xp[i + 1]) {
            // Linear interpolation
            double t = (x - xp[i]) / (xp[i + 1] - xp[i]);
            return yp[i] + t * (yp[i + 1] - yp[i]);
        }
    }
    
    return yp.back(); // fallback
}

// Precomputed tables (similar to Python version)
namespace {
    const std::vector<double> X = linspace(0.0, PI, 300);
    
    std::vector<double> compute_neg_cosine() {
        std::vector<double> result;
        result.reserve(X.size());
        for (double x : X) {
            result.push_back(-std::cos(x));
        }
        return result;
    }
    
    std::vector<double> compute_sine() {
        std::vector<double> result;
        result.reserve(X.size());
        for (double x : X) {
            result.push_back(std::sin(x));
        }
        return result;
    }
    
    std::vector<double> compute_f2(const std::vector<double>& neg_cosine, const std::vector<double>& sine) {
        std::vector<double> result;
        result.reserve(X.size());
        for (std::size_t i = 0; i < X.size(); ++i) {
            result.push_back((X[i] + neg_cosine[i] * sine[i]) / 2.0);
        }
        return result;
    }
    
    const std::vector<double> NEG_COSINE = compute_neg_cosine();
    const std::vector<double> SINE = compute_sine();
    const std::vector<double> F2 = compute_f2(NEG_COSINE, SINE);
}

// Recursive helper function for get_tp
static std::vector<double> get_tp_recursive(int n) {
    if (n == 0) {
        return X;
    }
    if (n == 1) {
        return NEG_COSINE;
    }
    
    std::vector<double> tp_minus2 = get_tp_recursive(n - 2);
    std::vector<double> result;
    result.reserve(tp_minus2.size());
    
    for (std::size_t i = 0; i < tp_minus2.size(); ++i) {
        double value = ((n - 1) * tp_minus2[i] + NEG_COSINE[i] * std::pow(SINE[i], n - 1)) / n;
        result.push_back(value);
    }
    
    return result;
}

std::vector<double> get_tp(int n) {
    if (n < 0) {
        throw std::invalid_argument("n must be non-negative");
    }
    return get_tp_recursive(n);
}

Sphere3::Sphere3(const std::vector<std::uint64_t>& base) 
    : vdc_(base[0]), sphere2_({base[1], base[2]}) {
    if (base.size() < 3) {
        throw std::invalid_argument("Sphere3 requires at least 3 bases");
    }
}

std::vector<double> Sphere3::pop() {
    double ti = HALF_PI * vdc_.pop(); // map to [t0, tm-1]
    double xi = simple_interp(ti, F2, X);
    double cosxi = std::cos(xi);
    double sinxi = std::sin(xi);
    
    auto sphere2_point = sphere2_.pop();
    std::vector<double> result;
    result.reserve(sphere2_point.size() + 1);
    
    for (double s : sphere2_point) {
        result.push_back(sinxi * s);
    }
    result.push_back(cosxi);
    
    return result;
}

void Sphere3::reseed(std::uint64_t seed) {
    vdc_.reseed(seed);
    sphere2_.reseed(seed);
}

SphereN::SphereN(const std::vector<std::uint64_t>& base) 
    : vdc_(base[0]), n_(static_cast<int>(base.size()) - 1) {
    
    if (n_ < 2) {
        throw std::invalid_argument("SphereN requires at least 3 bases (n >= 2)");
    }
    
    if (n_ == 2) {
        s_gen_ = std::make_unique<Sphere>(std::vector<std::uint64_t>{base[1], base[2]});
    } else {
        std::vector<std::uint64_t> sub_base(base.begin() + 1, base.end());
        s_gen_ = std::make_unique<SphereN>(sub_base);
    }
    
    auto tp = get_tp(n_);
    range_ = tp.back() - tp.front();
}

std::vector<double> SphereN::pop() {
    if (n_ == 2) {
        double ti = HALF_PI * vdc_.pop(); // map to [t0, tm-1]
        double xi = simple_interp(ti, F2, X);
        double cosxi = std::cos(xi);
        double sinxi = std::sin(xi);
        
        auto sub_point = s_gen_->pop();
        std::vector<double> result;
        result.reserve(sub_point.size() + 1);
        
        for (double s : sub_point) {
            result.push_back(sinxi * s);
        }
        result.push_back(cosxi);
        
        return result;
    }
    
    double vd = vdc_.pop();
    auto tp = get_tp(n_);
    double ti = tp.front() + range_ * vd; // map to [t0, tm-1]
    double xi = simple_interp(ti, tp, X);
    double sinphi = std::sin(xi);
    
    auto sub_point = s_gen_->pop();
    std::vector<double> result;
    result.reserve(sub_point.size() + 1);
    
    for (double s : sub_point) {
        result.push_back(s * sinphi);
    }
    result.push_back(std::cos(xi));
    
    return result;
}

void SphereN::reseed(std::uint64_t seed) {
    vdc_.reseed(seed);
    s_gen_->reseed(seed);
}

} // namespace lds_gen