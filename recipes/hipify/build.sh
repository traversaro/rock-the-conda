#!/bin/bash

set -xeuo pipefail

# Build hipify-clang using CMake
cmake -S . -B build -G Ninja ${CMAKE_ARGS}
cmake --build build --parallel "${CPU_COUNT}"
cmake --install build
