#!/bin/bash

cmake -GNinja ${CMAKE_ARGS} -Bbuild -S.
cmake --build ./build
cmake --install ./build
