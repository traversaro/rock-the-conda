cmake_minimum_required(VERSION 3.16)
project(ExtractTheRockDeps)

# Get the TheRock source directory
if(NOT DEFINED THEROCK_SOURCE_DIR)
    message(FATAL_ERROR "THEROCK_SOURCE_DIR must be defined")
endif()

if(NOT EXISTS "${THEROCK_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "TheRock source directory not found at: ${THEROCK_SOURCE_DIR}")
endif()

message(STATUS "Processing TheRock source at: ${THEROCK_SOURCE_DIR}")

# Set required AMDGPU families (dummy value to prevent CMake errors)
if(NOT DEFINED THEROCK_AMDGPU_FAMILIES)
    set(THEROCK_AMDGPU_FAMILIES "gfx1100")
endif()

# Initialize the global property for storing dependencies
set_property(GLOBAL PROPERTY ALL_DEPS "")

# Insert our `cmake` folder here to override the files in the rock
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Add TheRock as the add_subdirectory
add_subdirectory(${THEROCK_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/TheRock)

# Output the collected dependencies
message(STATUS "=== DEPENDENCY EXTRACTION COMPLETE ===")
get_property(ALL_DEPS GLOBAL PROPERTY ALL_DEPS)
list(LENGTH ALL_DEPS NUM_DEPS)
message(STATUS "Found ${NUM_DEPS} projects")

# Output in a format that Python can easily parse
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/therock_deps.txt" "")
foreach(DEP_LINE ${ALL_DEPS})
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/therock_deps.txt" "${DEP_LINE}\n")
    message(STATUS "${DEP_LINE}")
endforeach()

message(STATUS "Dependencies written to: ${CMAKE_CURRENT_BINARY_DIR}/therock_deps.txt")

# Create a dummy target so this is a valid CMake project
add_custom_target(extract_deps_dummy)
