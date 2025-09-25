#!/bin/bash

# Workaround for https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3314729588
export ROCM_PATH=$PREFIX

# See https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3317381230
# gfx908 and gfx90a in particular were removed as workaround for rocblas, if you need them you need to patch Tensile
export CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS="gfx942;gfx950;gfx1010;gfx1012;gfx1030;gfx1100;gfx1101;gfx1102;gfx1151;gfx1200;gfx1201"


cmake -GNinja -DGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} ${CMAKE_ARGS} -Bbuild -S.
cmake --build ./build
cmake --install ./build
