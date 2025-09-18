#!/bin/bash

cmake -GNinja ${CMAKE_ARGS} -DBUILD_TESTING:BOOL=OFF -Bbuild -S.
cmake --build ./build
cmake --install ./build
