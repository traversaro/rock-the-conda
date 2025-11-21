#!/bin/bash
set -euo pipefail

mkdir -p "$PREFIX/include"
cp -a "$SRC_DIR/external/cereal/include/cereal" "$PREFIX/include/"

# Create CMake config file for cereal
mkdir -p "${PREFIX}/lib/cmake/cereal"
cat > "${PREFIX}/lib/cmake/cereal/cerealConfig.cmake" <<EOF
add_library(cereal::cereal INTERFACE IMPORTED)
set_target_properties(cereal::cereal PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "\${CMAKE_CURRENT_LIST_DIR}/../../../include"
  INTERFACE_COMPILE_DEFINITIONS "CEREAL_THREAD_SAFE=1"
)
EOF
