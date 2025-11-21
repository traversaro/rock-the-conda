#!/bin/bash

set -xeuo pipefail

mkdir build

cd build

meson setup \
    ${MESON_ARGS} \
    ..

meson compile
meson install

mkdir -p $PREFIX/lib/cmake/perfetto

cat > $PREFIX/lib/cmake/perfetto/PerfettoConfig.cmake <<'EOF'
add_library(perfetto::perfetto STATIC IMPORTED)
set_target_properties(perfetto::perfetto PROPERTIES
    IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/../../libperfetto.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}/../../../include")
EOF
