#!/bin/bash

set -xeuo pipefail

mkdir build

cd build

cmake -GNinja ${CMAKE_ARGS} ..

cmake --build . -j${CPU_COUNT}
cmake --install .
