#!/bin/bash

# Workaround for https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3314729588
export ROCM_PATH=$PREFIX

# A lot of part of the build system hardcode amdclang++ as compiler, let's temporary
# add a symlink with this name, see https://github.com/ROCm/rocm-libraries/issues/944
ln -sf -- "$CXX" "$BUILD_PREFIX/bin/amdclang++"
ln -sf -- "$CC" "$BUILD_PREFIX/bin/amdclang"

cmake -GNinja ${CMAKE_ARGS} -Bbuild -S.
cmake --build ./build
cmake --install ./build

# Remove amdclang++ symlink to avoid to ship it
rm -f -- "$BUILD_PREFIX/bin/amdclang++"
rm -f -- "$BUILD_PREFIX/bin/amdclang"
