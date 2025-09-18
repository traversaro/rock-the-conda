#!/bin/bash

# A lot of part of the build system hardcode amdclang++ as compiler, let's temporary
# add a symlink with this name
ln -sf -- "$CXX" "$PREFIX/bin/amdclang++"
ln -sf -- "$CC" "$PREFIX/bin/amdclang"

cmake -GNinja ${CMAKE_ARGS} -DAMDGPU_TARGETS=gfx942 -Bbuild -S.
cmake --build ./build
cmake --install ./build

# Remove amdclang++ symlink to avoid to ship it
rm -f -- "$PREFIX/bin/amdclang++"
rm -f -- "$PREFIX/bin/amdclang"
