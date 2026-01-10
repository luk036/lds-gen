#include "lds_gen/ilds.hpp"
#include <cstdint>
#include <vector>

namespace lds_gen {

VdCorputInt::VdCorputInt(std::uint64_t base, std::uint64_t scale)
    : base_(base), scale_(scale), count_(0), factor_(1) {
    for (std::uint64_t i = 0; i < scale_; ++i) {
        factor_ *= base_;
    }
}

std::uint64_t VdCorputInt::pop() {
    ++count_;
    std::uint64_t count = count_;
    std::uint64_t vdc = 0;
    std::uint64_t factor = factor_;

    while (count != 0) {
        factor /= base_;
        std::uint64_t remainder = count % base_;
        count /= base_;
        vdc += remainder * factor;
    }

    return vdc;
}

void VdCorputInt::reseed(std::uint64_t seed) {
    count_ = seed;
}

HaltonInt::HaltonInt(std::span<const std::uint64_t> base,
                     std::span<const std::uint64_t> scale)
    : vdc0_(base[0], scale[0]), vdc1_(base[1], scale[1]) {}

std::array<std::uint64_t, 2> HaltonInt::pop() {
    return {vdc0_.pop(), vdc1_.pop()};
}

void HaltonInt::reseed(std::uint64_t seed) {
    vdc0_.reseed(seed);
    vdc1_.reseed(seed);
}

} // namespace lds_gen
