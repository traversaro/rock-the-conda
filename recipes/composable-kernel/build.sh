#!/bin/bash

set -xeuo pipefail

# Create temporary hipcc and hipconfig symlinks if they don't exist
# HIP cmake config validates these executables exist in $PREFIX/bin
# but conda-build installs them in $BUILD_PREFIX/bin
CLEANUP_HIPCC=0
CLEANUP_HIPCONFIG=0

if [ ! -f "${PREFIX}/bin/hipcc" ]; then
    # hipcc is in BUILD_PREFIX, but hip-config.cmake expects it in PREFIX
    if [ -f "${BUILD_PREFIX}/bin/hipcc" ]; then
        ln -sf "${BUILD_PREFIX}/bin/hipcc" "${PREFIX}/bin/hipcc"
        CLEANUP_HIPCC=1
    else
        # Fallback: create symlink to HIPCXX compiler
        ln -sf "${HIPCXX}" "${PREFIX}/bin/hipcc"
        CLEANUP_HIPCC=1
    fi
fi

if [ ! -f "${PREFIX}/bin/hipconfig" ]; then
    # Check if hipconfig exists in BUILD_PREFIX
    if [ -f "${BUILD_PREFIX}/bin/hipconfig" ]; then
        ln -sf "${BUILD_PREFIX}/bin/hipconfig" "${PREFIX}/bin/hipconfig"
        CLEANUP_HIPCONFIG=1
    else
        # Create a minimal hipconfig script for HIP platform detection
        cat > "${PREFIX}/bin/hipconfig" << 'EOF'
#!/bin/bash
# Minimal hipconfig for conda-forge builds
case "$1" in
    --platform) echo "amd" ;;
    --version)  echo "7.0.2" ;;
    *)          echo "amd" ;;
esac
exit 0
EOF
        chmod +x "${PREFIX}/bin/hipconfig"
        CLEANUP_HIPCONFIG=1
    fi
fi

mkdir -p build
cd build

cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_CXX_COMPILER=${HIPCXX} \
    -DCMAKE_HIP_COMPILER=${HIPCXX} \
    -DGPU_TARGETS=${CONDA_FORGE_DEFAULT_ROCM_GPU_TARGETS} \
    -DBUILD_DEV=OFF \
    -DBUILD_TESTING=OFF \
    ..

cmake --build . -j${CPU_COUNT}
cmake --install .

# Clean up temporary files
if [ "${CLEANUP_HIPCC}" = "1" ]; then
    rm -f "${PREFIX}/bin/hipcc"
fi

if [ "${CLEANUP_HIPCONFIG}" = "1" ]; then
    rm -f "${PREFIX}/bin/hipconfig"
fi
