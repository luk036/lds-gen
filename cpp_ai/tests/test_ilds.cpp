#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"
#include "lds_gen/ilds.hpp"
#include <vector>
#include <array>

TEST_CASE("Test VdCorputInt class") {
    lds_gen::VdCorputInt vdc(2, 10);
    CHECK(vdc.pop() == 512);
}

TEST_CASE("Test VdCorputInt reseed") {
    lds_gen::VdCorputInt vdc(2, 10);
    vdc.reseed(0);
    CHECK(vdc.pop() == 512);
}

TEST_CASE("Test HaltonInt class") {
    std::array<std::uint64_t, 2> base = {2, 3};
    std::array<std::uint64_t, 2> scale = {11, 7};
    lds_gen::HaltonInt hgen(base, scale);
    hgen.reseed(0);

    auto res = hgen.pop();
    CHECK(res[0] == 1024);
    CHECK(res[1] == 729);

    res = hgen.pop();
    CHECK(res[0] == 512);
    CHECK(res[1] == 1458);

    res = hgen.pop();
    CHECK(res[0] == 1536);
    CHECK(res[1] == 243);

    res = hgen.pop();
    CHECK(res[0] == 256);
    CHECK(res[1] == 972);

    res = hgen.pop();
    CHECK(res[0] == 1280);
    CHECK(res[1] == 1701);
}
