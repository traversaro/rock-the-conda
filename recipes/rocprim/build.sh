#!/bin/bash

cmake -GNinja ${CMAKE_ARGS} -DAMDGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} -Bbuild -S.
cmake --build ./build
cmake --install ./build
