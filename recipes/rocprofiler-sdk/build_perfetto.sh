#!/bin/bash
set -euo pipefail

SDK="${SRC_DIR}/external/perfetto/sdk"

${CXX} -std=c++17 -fPIC -I"${SDK}" -c "${SDK}/perfetto.cc" -o perfetto.o
ar rcs libperfetto.a perfetto.o

install -Dm644 "${SDK}/perfetto.h" "${PREFIX}/include/perfetto.h"
install -Dm644 libperfetto.a "${PREFIX}/lib/libperfetto.a"

mkdir -p "${PREFIX}/lib/cmake/perfetto"
cat > "${PREFIX}/lib/cmake/perfetto/PerfettoConfig.cmake" <<EOF
add_library(perfetto::perfetto STATIC IMPORTED)
set_target_properties(perfetto::perfetto PROPERTIES
  IMPORTED_LOCATION "\${CMAKE_CURRENT_LIST_DIR}/../../libperfetto.a"
  INTERFACE_INCLUDE_DIRECTORIES "\${CMAKE_CURRENT_LIST_DIR}/../../../include"
)

# Also create Perfetto::Perfetto (capitalized) alias for compatibility
if(NOT TARGET Perfetto::Perfetto)
  add_library(Perfetto::Perfetto ALIAS perfetto::perfetto)
endif()
EOF
