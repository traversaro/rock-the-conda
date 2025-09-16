#!/bin/bash

mkdir build
cd build

cmake ${CMAKE_ARGS} \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DROCM_DIR=$PREFIX \
  -DROCRTST_BLD_TYPE=Release \
  ..

make VERBOSE=1 -j${CPU_COUNT}
make install
