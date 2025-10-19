#!/bin/bash

# A lot of part of the build system hardcode amdclang++ as compiler, let's temporary
# add a symlink with this name, see https://github.com/ROCm/rocm-libraries/issues/944
ln -sf -- "$CXX" "$PREFIX/bin/amdclang++"
ln -sf -- "$CC" "$PREFIX/bin/amdclang"

# CMAKE_C_COMPILER AND CMAKE_CXX_COMPILER is passed as a Workaround for hack check that requires the compiler to have a specific name:
# https://github.com/ROCm/Tensile/blob/e8a8999e0e7374aaae546a6d7cb703d9e06b0ebf/Tensile/Utilities/Toolchain.py#L147C58-L147C65
# and https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3315983823
cmake -GNinja ${CMAKE_ARGS} -DGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} -DCMAKE_C_COMPILER="$BUILD_PREFIX/bin/amdclang" -DCMAKE_CXX_COMPILER="$BUILD_PREFIX/bin/amdclang++"  -Bbuild -S.
cmake --build ./build
cmake --install ./build

# Remove amdclang++ symlink to avoid to ship it
rm -f -- "$PREFIX/bin/amdclang++"
rm -f -- "$PREFIX/bin/amdclang"
