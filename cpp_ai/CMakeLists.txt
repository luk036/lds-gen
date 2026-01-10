cmake_minimum_required(VERSION 3.20)
project(lds_gen VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Options
option(BUILD_SHARED_LIBS "Build shared library" OFF)
option(BUILD_TESTS "Build tests" ON)
option(BUILD_EXAMPLES "Build examples" ON)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Library target
add_library(lds_gen
    src/lds.cpp
    src/ilds.cpp
    src/sphere_n.cpp
)

target_include_directories(lds_gen PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Install targets
install(TARGETS lds_gen
    EXPORT lds_gen-targets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)

install(DIRECTORY include/ DESTINATION include)

install(EXPORT lds_gen-targets
    FILE lds_gen-config.cmake
    NAMESPACE lds_gen::
    DESTINATION lib/cmake/lds_gen
)

# Tests
if(BUILD_TESTS)
    # Download doctest if not found
    if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tests/doctest.h)
        message(STATUS "Downloading doctest...")
        file(DOWNLOAD
            https://raw.githubusercontent.com/doctest/doctest/v2.4.11/doctest/doctest.h
            ${CMAKE_CURRENT_SOURCE_DIR}/tests/doctest.h
            SHOW_PROGRESS
        )
    endif()

    add_executable(test_lds tests/test_lds.cpp)
    target_link_libraries(test_lds lds_gen)

    add_executable(test_ilds tests/test_ilds.cpp)
    target_link_libraries(test_ilds lds_gen)

    add_executable(test_sphere_n tests/test_sphere_n.cpp)
    target_link_libraries(test_sphere_n lds_gen)

    # Add test targets
    add_test(NAME test_lds COMMAND test_lds)
    add_test(NAME test_ilds COMMAND test_ilds)
    add_test(NAME test_sphere_n COMMAND test_sphere_n)
endif()

# Examples
if(BUILD_EXAMPLES)
    add_executable(example examples/example.cpp)
    target_link_libraries(example lds_gen)
endif()

# Package configuration
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/lds_gen-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/lds_gen-config-version.cmake
    DESTINATION lib/cmake/lds_gen
)
