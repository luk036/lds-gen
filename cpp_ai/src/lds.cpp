#include "lds_gen/lds.hpp"
#include <cmath>
#include <cstdint>
#include <vector>
#include <numbers>

namespace lds_gen {

double vdc(std::uint64_t k, std::uint64_t base) {
    double res = 0.0;
    double denom = 1.0;
    while (k != 0) {
        denom *= static_cast<double>(base);
        std::uint64_t remainder = k % base;
        k /= base;
        res += static_cast<double>(remainder) / denom;
    }
    return res;
}

VdCorput::VdCorput(std::uint64_t base) : count_(0), base_(base) {
    rev_lst_.reserve(64);
    double reverse = 1.0;
    for (int i = 0; i < 64; ++i) {
        reverse /= static_cast<double>(base_);
        rev_lst_.push_back(reverse);
    }
}

double VdCorput::pop() {
    ++count_; // ignore 0
    std::uint64_t k = count_;
    double res = 0.0;
    std::size_t i = 0;
    while (k != 0) {
        std::uint64_t remainder = k % base_;
        k /= base_;
        if (remainder != 0) {
            res += static_cast<double>(remainder) * rev_lst_[i];
        }
        ++i;
    }
    return res;
}

void VdCorput::reseed(std::uint64_t seed) {
    count_ = seed;
}

Halton::Halton(const std::vector<std::uint64_t>& base) 
    : vdc0_(base[0]), vdc1_(base[1]) {}

std::vector<double> Halton::pop() {
    return {vdc0_.pop(), vdc1_.pop()};
}

void Halton::reseed(std::uint64_t seed) {
    vdc0_.reseed(seed);
    vdc1_.reseed(seed);
}

Circle::Circle(std::uint64_t base) : vdc_(base) {}

std::vector<double> Circle::pop() {
    double theta = vdc_.pop() * TWO_PI; // map to [0, 2π]
    return {std::cos(theta), std::sin(theta)};
}

void Circle::reseed(std::uint64_t seed) {
    vdc_.reseed(seed);
}

Disk::Disk(const std::vector<std::uint64_t>& base) 
    : vdc0_(base[0]), vdc1_(base[1]) {}

std::vector<double> Disk::pop() {
    double theta = vdc0_.pop() * TWO_PI; // map to [0, 2π]
    double radius = std::sqrt(vdc1_.pop()); // map to [0, 1]
    return {radius * std::cos(theta), radius * std::sin(theta)};
}

void Disk::reseed(std::uint64_t seed) {
    vdc0_.reseed(seed);
    vdc1_.reseed(seed);
}

Sphere::Sphere(const std::vector<std::uint64_t>& base) 
    : vdc_(base[0]), cirgen_(base[1]) {}

std::vector<double> Sphere::pop() {
    double cosphi = 2.0 * vdc_.pop() - 1.0; // map to [-1, 1]
    double sinphi = std::sqrt(1.0 - cosphi * cosphi); // cylindrical mapping
    auto circle_vals = cirgen_.pop();
    double c = circle_vals[0];
    double s = circle_vals[1];
    return {sinphi * c, sinphi * s, cosphi};
}

void Sphere::reseed(std::uint64_t seed) {
    cirgen_.reseed(seed);
    vdc_.reseed(seed);
}

Sphere3Hopf::Sphere3Hopf(const std::vector<std::uint64_t>& base) 
    : vdc0_(base[0]), vdc1_(base[1]), vdc2_(base[2]) {}

std::vector<double> Sphere3Hopf::pop() {
    double phi = vdc0_.pop() * TWO_PI; // map to [0, 2π]
    double psy = vdc1_.pop() * TWO_PI; // map to [0, 2π]
    double vdc = vdc2_.pop();
    double cos_eta = std::sqrt(vdc);
    double sin_eta = std::sqrt(1.0 - vdc);
    return {
        cos_eta * std::cos(psy),
        cos_eta * std::sin(psy),
        sin_eta * std::cos(phi + psy),
        sin_eta * std::sin(phi + psy)
    };
}

void Sphere3Hopf::reseed(std::uint64_t seed) {
    vdc0_.reseed(seed);
    vdc1_.reseed(seed);
    vdc2_.reseed(seed);
}

HaltonN::HaltonN(const std::vector<std::uint64_t>& base) {
    vdcs_.reserve(base.size());
    for (auto b : base) {
        vdcs_.emplace_back(b);
    }
}

std::vector<double> HaltonN::pop() {
    std::vector<double> result;
    result.reserve(vdcs_.size());
    for (auto& vdc : vdcs_) {
        result.push_back(vdc.pop());
    }
    return result;
}

void HaltonN::reseed(std::uint64_t seed) {
    for (auto& vdc : vdcs_) {
        vdc.reseed(seed);
    }
}

// First 1000 prime numbers
const std::vector<std::uint64_t> PRIME_TABLE = {
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,
    101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199,
    211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
    353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499,
    503, 509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659,
    661, 673, 677, 683, 691, 701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829,
    839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997,
    1009, 1013, 1019, 1021, 1031, 1033, 1039, 1049, 1051, 1061, 1063, 1069, 1087, 1091, 1093, 1097, 1103, 1109, 1117, 1123, 1129,
    1151, 1153, 1163, 1171, 1181, 1187, 1193, 1201, 1213, 1217, 1223, 1229, 1231, 1237, 1249, 1259, 1277, 1279, 1283, 1289, 1291,
    1297, 1301, 1303, 1307, 1319, 1321, 1327, 1361, 1367, 1373, 1381, 1399, 1409, 1423, 1427, 1429, 1433, 1439, 1447, 1451, 1453,
    1459, 1471, 1481, 1483, 1487, 1489, 1493, 1499, 1511, 1523, 1531, 1543, 1549, 1553, 1559, 1567, 1571, 1579, 1583, 1597, 1601,
    1607, 1609, 1613, 1619, 1621, 1627, 1637, 1657, 1663, 1667, 1669, 1693, 1697, 1699, 1709, 1721, 1723, 1733, 1741, 1747, 1753,
    1759, 1777, 1783, 1787, 1789, 1801, 1811, 1823, 1831, 1847, 1861, 1867, 1871, 1873, 1877, 1879, 1889, 1901, 1907, 1913, 1931,
    1933, 1949, 1951, 1973, 1979, 1987, 1993, 1997, 1999, 2003, 2011, 2017, 2027, 2029, 2039, 2053, 2063, 2069, 2081, 2083, 2087,
    2089, 2099, 2111, 2113, 2129, 2131, 2137, 2141, 2143, 2153, 2161, 2179, 2203, 2207, 2213, 2221, 2237, 2239, 2243, 2251, 2267,
    2269, 2273, 2281, 2287, 2293, 2297, 2309, 2311, 2333, 2339, 2341, 2347, 2351, 2357, 2371, 2377, 2381, 2383, 2389, 2393, 2399,
    2411, 2417, 2423, 2437, 2441, 2447, 2459, 2467, 2473, 2477, 2503, 2521, 2531, 2539, 2543, 2549, 2551, 2557, 2579, 2591, 2593,
    2609, 2617, 2621, 2633, 2647, 2657, 2659, 2663, 2671, 2677, 2683, 2687, 2689, 2693, 2699, 2707, 2711, 2713, 2719, 2729, 2731,
    2741, 2749, 2753, 2767, 2777, 2789, 2791, 2797, 2801, 2803, 2819, 2833, 2837, 2843, 2851, 2857, 2861, 2879, 2887, 2897, 2903,
    2909, 2917, 2927, 2939, 2953, 2957, 2963, 2969, 2971, 2999, 3001, 3011, 3019, 3023, 3037, 3041
};

} // namespace lds_gen