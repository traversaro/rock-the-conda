#!/bin/bash

cmake -GNinja -DAMDGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} ${CMAKE_ARGS} -Bbuild -S.
cmake --build ./build
cmake --install ./build
