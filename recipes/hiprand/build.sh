#!/bin/bash

set -xeuo pipefail

mkdir build
cd build

cmake \
    -GNinja \
    ${CMAKE_ARGS} \
    -DBUILD_TEST=OFF \
    -DBUILD_BENCHMARK=OFF \
    -DBUILD_EXAMPLE=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .
