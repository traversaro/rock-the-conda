# Override the therock_cmake_subproject_declare function
function(therock_cmake_subproject_declare PROJECT_NAME)
    cmake_parse_arguments(
      ARG
      "ACTIVATE;USE_DIST_AMDGPU_TAGETS;DISABLE_AMDGPU_TARGETS;EXCLUDE_FROM_ALL;BACKGROUND_BUILD;NO_MERGE_COMPILE_COMMANDS;OUTPUT_ON_FAILURE;NO_INSTALL_RPATH"
      "EXTERNAL_SOURCE_DIR;BINARY_DIR;DIR_PREFIX;INSTALL_DESTINATION;COMPILER_TOOLCHAIN;INTERFACE_PROGRAM_DIRS;CMAKE_LISTS_RELPATH;INTERFACE_PKG_CONFIG_DIRS;INSTALL_RPATH_EXECUTABLE_DIR;INSTALL_RPATH_LIBRARY_DIR"
      "BUILD_DEPS;RUNTIME_DEPS;CMAKE_ARGS;CMAKE_INCLUDES;INTERFACE_INCLUDE_DIRS;INTERFACE_LINK_DIRS;IGNORE_PACKAGES;EXTRA_DEPENDS;INSTALL_RPATH_DIRS;INTERFACE_INSTALL_RPATH_DIRS" ${ARGN}
    )
    
    message(STATUS "therock_cmake_subproject_declare with ${PROJECT_NAME} ARG_BUILD_DEPS: ${ARG_BUILD_DEPS} ARG_RUNTIME_DEPS: ${ARG_RUNTIME_DEPS}")
    # Collect all dependencies (both BUILD_DEPS and RUNTIME_DEPS)
    set(ALL_PROJECT_DEPS "")
    if(ARG_BUILD_DEPS)
        list(APPEND ALL_PROJECT_DEPS ${ARG_BUILD_DEPS})
    endif()
    if(ARG_RUNTIME_DEPS)
        list(APPEND ALL_PROJECT_DEPS ${ARG_RUNTIME_DEPS})
    endif()
    
    # Remove duplicates
    if(ALL_PROJECT_DEPS)
        list(REMOVE_DUPLICATES ALL_PROJECT_DEPS)
    endif()
    
    # Format as: PROJECT_NAME:dep1,dep2,dep3
    set(DEPS_STRING "${PROJECT_NAME}:")
    if(ALL_PROJECT_DEPS)
        string(REPLACE ";" "," DEPS_LIST "${ALL_PROJECT_DEPS}")
        set(DEPS_STRING "${DEPS_STRING}${DEPS_LIST}")
    endif()
    
    # Add to global list using global property
    get_property(CURRENT_ALL_DEPS GLOBAL PROPERTY ALL_DEPS)
    list(APPEND CURRENT_ALL_DEPS "${DEPS_STRING}")
    set_property(GLOBAL PROPERTY ALL_DEPS "${CURRENT_ALL_DEPS}")
    
    # Optional: print for debugging
    message(STATUS "Found project: ${PROJECT_NAME} with deps: ${ALL_PROJECT_DEPS}")

    # Add dummy target to ensure that add_dependencies works fine
    add_custom_target(${PROJECT_NAME})
    add_custom_target(${PROJECT_NAME}+dist)

endfunction()

# Override other functions that might be called but we don't need
function(therock_cmake_subproject_add)
    # Do nothing - just collect the declarations
endfunction()

function(therock_cmake_subproject_pre_add_subdirectory)
    # Do nothing
endfunction()

function(therock_cmake_subproject_post_add_subdirectory)
    # Do nothing
endfunction()

function(therock_subproject_fetch)
    # Do nothing
endfunction()

function(therock_cmake_subproject_provide_package)
    # Do nothing
endfunction()

function(therock_cmake_subproject_activate)
    # Do nothing
endfunction()

function(_therock_cmake_subproject_deps_to_stamp)
endfunction()

function(therock_cmake_subproject_glob_c_sources)
endfunction()

function(therock_cmake_subproject_dist_dir)
endfunction()

function(therock_subproject_merge_compile_commands)
endfunction()