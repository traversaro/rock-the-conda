#!/bin/bash
set -euo pipefail

export CMAKE_HIP_FLAGS="${CMAKE_HIP_FLAGS:-} -O2 -mcode-object-version=6"
export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS:-} -O2 -mcode-object-version=6 -ftemplate-backtrace-limit=0  -fPIE  -Wno-gnu-line-marker -fbracket-depth=512"

mkdir -p build
cd build

# Configure CMake
cmake -GNinja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_HIP_FLAGS="${CMAKE_HIP_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
    -DGPU_ARCHS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} \
    -DBUILD_DEV=OFF \
    -DBUILD_TESTING=OFF \
    -DENABLE_CLANG_CPP_CHECKS=OFF \
    ..

cmake --build . -- -j4
cmake --install .