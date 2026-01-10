add_rules("mode.debug", "mode.release")

set_languages("c++20")

target("lds_gen")
    set_kind("static")
    add_headerfiles("include/(lds_gen/**.hpp)")
    add_files("src/lds.cpp", "src/ilds.cpp", "src/sphere_n.cpp")
    add_includedirs("include", {public = true})

    -- C++20 features
    add_cxxflags("-std=c++20", "-Wall", "-Wextra", "-pedantic")

    if is_mode("debug") then
        add_defines("DEBUG")
        add_cxxflags("-g", "-O0")
    else
        add_cxxflags("-O3")
    end

target("test_lds")
    set_kind("binary")
    add_deps("lds_gen")
    add_files("tests/test_lds.cpp")
    add_includedirs("include")

    -- Download doctest if not present
    before_build(function (target)
        local doctest_path = path.join(target:scriptdir(), "tests", "doctest.h")
        if not os.isfile(doctest_path) then
            print("Downloading doctest...")
            os.execv("curl", {"-L", "https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h", "-o", doctest_path})
        end
    end)

target("test_ilds")
    set_kind("binary")
    add_deps("lds_gen")
    add_files("tests/test_ilds.cpp")
    add_includedirs("include")

    before_build(function (target)
        local doctest_path = path.join(target:scriptdir(), "tests", "doctest.h")
        if not os.isfile(doctest_path) then
            print("Downloading doctest...")
            os.execv("curl", {"-L", "https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h", "-o", doctest_path})
        end
    end)

target("test_sphere_n")
    set_kind("binary")
    add_deps("lds_gen")
    add_files("tests/test_sphere_n.cpp")
    add_includedirs("include")

    before_build(function (target)
        local doctest_path = path.join(target:scriptdir(), "tests", "doctest.h")
        if not os.isfile(doctest_path) then
            print("Downloading doctest...")
            os.execv("curl", {"-L", "https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h", "-o", doctest_path})
        end
    end)

target("example")
    set_kind("binary")
    add_deps("lds_gen")
    add_files("examples/example.cpp")
    add_includedirs("include")

-- Package configuration
package("lds_gen")
    set_description("Low-Discrepancy Sequence Generator C++ Library")
    set_license("MIT")

    add_urls("https://github.com/luk036/lds-gen.git")
    add_versions("1.0.0", "dcda260be4010b1509c1dcb9d5f3edcddba9cc51")

    on_install(function (package)
        import("package.tools.cmake").install(package)
    end)

    on_test(function (package)
        assert(package:has_cxxfuncs("lds_gen::vdc", {includes = "lds_gen/lds.hpp"}))
    end)
