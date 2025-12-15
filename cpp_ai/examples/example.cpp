#include "lds_gen.hpp"
#include <iostream>
#include <iomanip>
#include <vector>

int main() {
    std::cout << "Low-Discrepancy Sequence Generator Examples\n";
    std::cout << "===========================================\n\n";

    // Example 1: Van der Corput sequence
    std::cout << "1. Van der Corput sequence (base 2):\n";
    lds_gen::VdCorput vgen(2);
    vgen.reseed(0);
    for (int i = 0; i < 10; ++i) {
        std::cout << "   " << vgen.pop() << "\n";
    }
    std::cout << "\n";

    // Example 2: Halton sequence
    std::cout << "2. Halton sequence (bases [2, 3]):\n";
    lds_gen::Halton hgen({2, 3});
    hgen.reseed(0);
    for (int i = 0; i < 5; ++i) {
        auto point = hgen.pop();
        std::cout << "   [" << point[0] << ", " << point[1] << "]\n";
    }
    std::cout << "\n";

    // Example 3: Circle sequence
    std::cout << "3. Circle sequence (base 2):\n";
    lds_gen::Circle cgen(2);
    cgen.reseed(0);
    for (int i = 0; i < 5; ++i) {
        auto point = cgen.pop();
        std::cout << "   [" << point[0] << ", " << point[1] << "]\n";
    }
    std::cout << "\n";

    // Example 4: Disk sequence
    std::cout << "4. Disk sequence (bases [2, 3]):\n";
    lds_gen::Disk dgen({2, 3});
    dgen.reseed(0);
    for (int i = 0; i < 5; ++i) {
        auto point = dgen.pop();
        std::cout << "   [" << point[0] << ", " << point[1] << "]\n";
    }
    std::cout << "\n";

    // Example 5: Sphere sequence
    std::cout << "5. Sphere sequence (bases [2, 3]):\n";
    lds_gen::Sphere sgen({2, 3});
    sgen.reseed(0);
    for (int i = 0; i < 3; ++i) {
        auto point = sgen.pop();
        std::cout << "   [" << point[0] << ", " << point[1] << ", " << point[2] << "]\n";
    }
    std::cout << "\n";

    // Example 6: Sphere3 sequence
    std::cout << "6. Sphere3 sequence (bases [2, 3, 5]):\n";
    lds_gen::Sphere3 s3gen({2, 3, 5});
    s3gen.reseed(0);
    for (int i = 0; i < 3; ++i) {
        auto point = s3gen.pop();
        std::cout << "   [";
        for (std::size_t j = 0; j < point.size(); ++j) {
            std::cout << point[j];
            if (j < point.size() - 1) std::cout << ", ";
        }
        std::cout << "]\n";
    }
    std::cout << "\n";

    // Example 7: SphereN sequence
    std::cout << "7. SphereN sequence (bases [2, 3, 5, 7]):\n";
    lds_gen::SphereN sngen({2, 3, 5, 7});
    sngen.reseed(0);
    for (int i = 0; i < 2; ++i) {
        auto point = sngen.pop();
        std::cout << "   [";
        for (std::size_t j = 0; j < point.size(); ++j) {
            std::cout << point[j];
            if (j < point.size() - 1) std::cout << ", ";
        }
        std::cout << "]\n";
    }
    std::cout << "\n";

    // Example 8: Integer version
    std::cout << "8. Integer Van der Corput sequence (base 2, scale 10):\n";
    lds_gen::VdCorputInt vdc_int(2, 10);
    vdc_int.reseed(0);
    for (int i = 0; i < 5; ++i) {
        std::cout << "   " << vdc_int.pop() << "\n";
    }

    return 0;
}