#!/bin/bash
set -euo pipefail

mkdir -p "$PREFIX/include"
cp -a "$SRC_DIR/external/json/include/nlohmann" "$PREFIX/include/"

# Create CMake config file for nlohmann_json
mkdir -p "${PREFIX}/lib/cmake/nlohmann_json"
cat > "${PREFIX}/lib/cmake/nlohmann_json/nlohmann_jsonConfig.cmake" <<EOF
add_library(nlohmann_json::nlohmann_json INTERFACE IMPORTED)
set_target_properties(nlohmann_json::nlohmann_json PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES "\${CMAKE_CURRENT_LIST_DIR}/../../../include"
)

# Provide version information
set(nlohmann_json_VERSION_MAJOR 3)
set(nlohmann_json_VERSION_MINOR 12)
set(nlohmann_json_VERSION_PATCH 0)
set(nlohmann_json_VERSION \${nlohmann_json_VERSION_MAJOR}.\${nlohmann_json_VERSION_MINOR}.\${nlohmann_json_VERSION_PATCH})
EOF
