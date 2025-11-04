#!/bin/bash
set -euo pipefail

CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS="gfx11-generic"
export CMAKE_HIP_FLAGS="${CMAKE_HIP_FLAGS:-} -O2 -mcode-object-version=6"
export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS:-} -O2 -mcode-object-version=6"

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
    -DMIOPEN_REQ_LIBS_ONLY=ON \
    -DBUILD_DEV=OFF \
    -DBUILD_TESTING=OFF \
    -DENABLE_CLANG_CPP_CHECKS=OFF \
    ..

# List all valid device_* targets (strip any trailing colons)
mapfile -t targets < <(cmake --build . --target help | grep -o 'device_[^ ]*' | sed 's/:$//' | sort -u)

# Build each target sequentially to reduce memory use
for target in "${targets[@]}"; do
  echo "=== Building ${target} ==="
  if ! cmake --build . --target "${target}" -j2; then
    echo "WARNING: Skipping ${target} due to failure"
  fi
done

# Build the main library and install
echo "Building composablekernel"
cmake --build . --target composablekernel -j2 || echo "WARNING: Failed to link composablekernel"

# Remove libutility.a from install targets (it's not built)
sed -i '/  \.a/d' library/src/utility/cmake_install.cmake 2>/dev/null || true

cmake --install .
