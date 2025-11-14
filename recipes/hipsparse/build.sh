#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    -GNinja \
    ${CMAKE_ARGS} \
    -DBUILD_CLIENTS_TESTS=OFF \
    -DBUILD_CLIENTS_BENCHMARKS=OFF \
    -DBUILD_CLIENTS_SAMPLES=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .
