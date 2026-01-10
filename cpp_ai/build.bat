@echo off
echo Building lds-gen C++ library...

REM Check for CMake
where cmake >nul 2>nul
if %errorlevel% neq 0 (
    echo CMake not found. Please install CMake 3.20 or later.
    exit /b 1
)

REM Create build directory
if not exist build mkdir build
cd build

REM Configure with CMake
echo Configuring with CMake...
cmake .. -G "Visual Studio 17 2022" -A x64

if %errorlevel% neq 0 (
    echo CMake configuration failed.
    exit /b 1
)

REM Build
echo Building...
cmake --build . --config Release

if %errorlevel% neq 0 (
    echo Build failed.
    exit /b 1
)

echo Build completed successfully!
echo.
echo To run tests: ctest -C Release
echo To run example: .\Release\example.exe
cd ..
