#!/bin/bash

set -xeuo pipefail

cmake -S . -B build -G Ninja \
    ${CMAKE_ARGS} \
    -DROCPROFILER_REGISTER_BUILD_GLOG=OFF \
    -DROCPROFILER_REGISTER_BUILD_FMT=OFF

cmake --build build -j${CPU_COUNT}
cmake --install build
