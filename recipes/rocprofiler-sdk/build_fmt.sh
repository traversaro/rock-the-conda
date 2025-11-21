#!/bin/bash
set -euo pipefail

cmake ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_SHARED_LIBS=ON \
    -DFMT_DOC=OFF \
    -DFMT_TEST=OFF \
    -DFMT_FUZZ=OFF \
    -DFMT_CUDA_TEST=OFF \
    -GNinja \
    -S "${SRC_DIR}/external/fmt" \
    -B build_fmt

cmake --build build_fmt --parallel ${CPU_COUNT}
cmake --install build_fmt