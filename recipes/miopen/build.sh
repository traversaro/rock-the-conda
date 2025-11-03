#!/bin/bash

set -xeuo pipefail

# Use GPU targets from environment or default to gfx1151 for testing
AMDGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS:-"gfx1151"}

echo "Building MIOpen for GPU targets: ${AMDGPU_TARGETS}"

# MIOpen needs a database directory
mkdir -p ${PREFIX}/share/miopen/db

mkdir -p build
cd build

# Configure MIOpen
cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DMIOPEN_BACKEND=HIP \
    -DMIOPEN_USE_COMPOSABLEKERNEL=ON \
    -DMIOPEN_USE_MIOPENGEMM=OFF \
    -DGPU_TARGETS="${AMDGPU_TARGETS}" \
    -DMIOPEN_INSTALL_CXX_HEADERS=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_FILE_REORG_BACKWARD_COMPATIBILITY=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .
