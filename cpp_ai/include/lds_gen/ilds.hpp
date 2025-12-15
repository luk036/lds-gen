#pragma once

#include <cstdint>
#include <vector>

namespace lds_gen {

// Integer Van der Corput sequence generator class
class VdCorputInt {
public:
    explicit VdCorputInt(std::uint64_t base = 2, std::uint64_t scale = 10);
    
    std::uint64_t pop();
    void reseed(std::uint64_t seed);
    
private:
    std::uint64_t base_;
    std::uint64_t scale_;
    std::uint64_t count_;
    std::uint64_t factor_;
};

// Integer Halton sequence generator (2D)
class HaltonInt {
public:
    explicit HaltonInt(const std::vector<std::uint64_t>& base, 
                       const std::vector<std::uint64_t>& scale);
    
    std::vector<std::uint64_t> pop();
    void reseed(std::uint64_t seed);
    
private:
    VdCorputInt vdc0_;
    VdCorputInt vdc1_;
};

} // namespace lds_gen