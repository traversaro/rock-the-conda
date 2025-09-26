#!/bin/bash

cd amd/device-libs

mkdir build
cd build

cmake \
  -DLLVM_DIR=$PREFIX \
  $CMAKE_ARGS \
  -DROCM_DEVICE_LIBS_BITCODE_INSTALL_LOC_NEW:STRING=lib/clang/20/lib/amdgcn \
  ..

make VERBOSE=1 -j${CPU_COUNT}
make install
