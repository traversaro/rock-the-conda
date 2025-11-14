#!/bin/bash

set -xeuo pipefail

# Initialize git submodules (rccl uses submodules)
git submodule update --init --recursive --depth=1

# Set ROCM_PATH to BUILD_PREFIX so hipcc can find ROCm tools
export ROCM_PATH="${BUILD_PREFIX}"
export HIP_PATH="${BUILD_PREFIX}"

# Ensure hipcc can find rocm_agent_enumerator and other tools
export PATH="${BUILD_PREFIX}/bin:${PATH}"

mkdir build
cd build

# Override CXX compiler to use hipcc (RCCL requires hipcc or amdclang++)
# Use BUILD_PREFIX since hipcc is a build-time tool
# Force pthread to be found from sysroot
cmake \
    -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_CXX_COMPILER="${BUILD_PREFIX}/bin/hipcc" \
    -DCMAKE_THREAD_LIBS_INIT="-lpthread" \
    -DCMAKE_HAVE_THREADS_LIBRARY=1 \
    -DCMAKE_USE_PTHREADS_INIT=1 \
    -DROCM_PATH="${ROCM_PATH}" \
    -DHIP_PATH="${HIP_PATH}" \
    -DAMDGPU_TARGETS="${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS}" \
    -DBUILD_TESTS=OFF \
    -DBUILD_BFD=OFF \
    -DRCCL_ROCPROFILER_REGISTER=OFF \
    -DENABLE_MSCCLPP=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .
