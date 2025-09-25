#!/bin/bash

# Workaround for https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3314729588
export ROCM_PATH=$PREFIX

# See https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3317381230
# gfx908 and gfx90a in particular were removed as workaround, if you need them you need to patch Tensile
export CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS="gfx942;gfx950;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102;gfx1151;gfx1200;gfx1201"

# A lot of part of the build system hardcode amdclang++ as compiler, let's temporary
# add a symlink with this name, see https://github.com/ROCm/rocm-libraries/issues/944
ln -sf -- "$CXX" "$BUILD_PREFIX/bin/amdclang++"
ln -sf -- "$CC" "$BUILD_PREFIX/bin/amdclang"

# CMAKE_C_COMPILER AND CMAKE_CXX_COMPILER is passed as a Workaround for hack check that requires the compiler to have a specific name:
# https://github.com/ROCm/Tensile/blob/e8a8999e0e7374aaae546a6d7cb703d9e06b0ebf/Tensile/Utilities/Toolchain.py#L147C58-L147C65
# and https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3315983823
cmake -GNinja ${CMAKE_ARGS} -DGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} -DCMAKE_C_COMPILER="$BUILD_PREFIX/bin/amdclang" -DCMAKE_CXX_COMPILER="$BUILD_PREFIX/bin/amdclang++"  -Bbuild -S.
cmake --build ./build
cmake --install ./build
