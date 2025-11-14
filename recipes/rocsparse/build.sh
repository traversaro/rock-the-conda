#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DAMDGPU_TARGETS="${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS}" \
    -DBUILD_CLIENTS_TESTS=OFF \
    -DBUILD_CLIENTS_BENCHMARKS=OFF \
    -DBUILD_CLIENTS_SAMPLES=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .
