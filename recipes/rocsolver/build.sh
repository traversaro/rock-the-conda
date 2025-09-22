#!/bin/bash

export HIP_DEVICE_LIB_PATH=$PREFIX/lib/amdgcn/bitcode
# Workaround for https://github.com/traversaro/rock-the-conda/issues/3#issuecomment-3314729588
export ROCM_PATH=$PREFIX

cmake -GNinja ${CMAKE_ARGS} -Bbuild -S.
cmake --build ./build
cmake --install ./build
