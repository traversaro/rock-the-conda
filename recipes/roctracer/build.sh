#!/bin/bash

cmake -GNinja ${CMAKE_ARGS} -DROCM_PATH=$BUILD_PREFIX -DBUILD_TESTING:BOOL=OFF -Bbuild -S.
cmake --build ./build
cmake --install ./build
