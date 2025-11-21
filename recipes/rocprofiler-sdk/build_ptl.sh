#!/bin/bash
set -euo pipefail

cd "${SRC_DIR}/external/ptl"
mkdir build && cd build

cmake -G Ninja \
    -DBUILD_SHARED_LIBS=OFF \
    -DPTL_USE_TBB=OFF \
    -DPTL_USE_GPU=OFF \
    -DPTL_USE_LOCKS=ON \
    -DPTL_BUILD_TESTS=OFF \
    -DPTL_DEVELOPER_INSTALL=OFF \
    ${CMAKE_ARGS} ..

cmake --build . -j${CPU_COUNT}
cmake install .
