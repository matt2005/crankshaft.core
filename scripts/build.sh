#!/bin/bash
# Project: Crankshaft
# This file is part of Crankshaft project.
# Copyright (C) 2025 OpenCarDev Team
#
#  Crankshaft is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Crankshaft is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.

set -e

# Script to build Crankshaft consistently across Docker and local environments
# Usage: ./build.sh [release|debug] [--component COMPONENT] [--clean] [--package] [--output-dir DIR] [--with-aasdk] [--aasdk-branch BRANCH] [--enable-slim-ui] [--skip-tests]

# Default values
CLEAN_BUILD=false
PACKAGE=false
OUTPUT_DIR="/output"
WITH_AASDK=false
AASDK_BRANCH="main"
ENABLE_SLIM_UI=false
SKIP_TESTS=false
COMPONENT="all"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Auto-detect build type based on git branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    BUILD_TYPE="release"
else
    BUILD_TYPE="debug"
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        release|Release|RELEASE)
            BUILD_TYPE="release"
            shift
            ;;
        debug|Debug|DEBUG)
            BUILD_TYPE="debug"
            shift
            ;;
        --component)
            COMPONENT="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --package)
            PACKAGE=true
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --with-aasdk)
            WITH_AASDK=true
            shift
            ;;
        --aasdk-branch)
            AASDK_BRANCH="$2"
            shift 2
            ;;
        --enable-slim-ui)
            ENABLE_SLIM_UI=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [release|debug] [OPTIONS]"
            echo ""
            echo "Build types:"
            echo "  release        Build release version (default on main/master)"
            echo "  debug          Build debug version with symbols (default on other branches)"
            echo ""
            echo "Options:"
            echo "  --component    Component to build (all|core|ui|tests) [default: all]"
            echo "  --clean        Clean build directory before building"
            echo "  --package      Create DEB and TGZ packages after building"
            echo "  --output-dir   Directory to copy packages (default: /output)"
            echo "  --with-aasdk   Clone AASDK branch and build/install it"
            echo "  --aasdk-branch Branch to use for AASDK (default: main)"
            echo "  --enable-slim-ui Enable slim AndroidAuto UI build"
            echo "  --skip-tests   Skip running tests"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 release --package"
            echo "  $0 debug --component core --clean"
            echo "  $0 release --with-aasdk --package"
            echo "  $0 debug --enable-slim-ui"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate component
if [[ "$COMPONENT" != "all" && "$COMPONENT" != "core" && "$COMPONENT" != "ui" && "$COMPONENT" != "tests" ]]; then
    echo "Error: Invalid component '$COMPONENT'. Must be 'all', 'core', 'ui', or 'tests'."
    exit 1
fi

# Detect architecture
TARGET_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH 2>/dev/null || echo "amd64")

# Handle AASDK cloning and building if requested
if [ "$WITH_AASDK" = true ]; then
    echo ""
    echo "Cloning AASDK ${AASDK_BRANCH} branch..."
    if [ -d "${SOURCE_DIR}/aasdk-build" ]; then
        rm -rf "${SOURCE_DIR}/aasdk-build"
    fi
    git clone --branch "${AASDK_BRANCH}" https://github.com/opencardev/aasdk.git "${SOURCE_DIR}/aasdk-build"
    cd "${SOURCE_DIR}/aasdk-build"
    echo "Building and installing AASDK..."
    chmod +x build.sh
    export TARGET_ARCH
    ./build.sh $BUILD_TYPE install --skip-protobuf --skip-absl
    cd "${SOURCE_DIR}"
    echo "AASDK build and install completed."
fi

# Determine build directory and CMake build type
if [ "$BUILD_TYPE" = "debug" ]; then
    BUILD_DIR="${SOURCE_DIR}/build-debug"
    CMAKE_BUILD_TYPE="Debug"
    echo "=== Building Crankshaft (${COMPONENT}) (Debug) ==="
else
    BUILD_DIR="${SOURCE_DIR}/build-release"
    CMAKE_BUILD_TYPE="Release"
    echo "=== Building Crankshaft (${COMPONENT}) (Release) ==="
fi

echo "Source directory: ${SOURCE_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo "Build type: ${CMAKE_BUILD_TYPE}"
echo "Component: ${COMPONENT}"
echo "Package: ${PACKAGE}"
echo "AASDK: ${WITH_AASDK} (branch: ${AASDK_BRANCH})"
echo "Slim UI: ${ENABLE_SLIM_UI}"

# Create logs directory
mkdir -p "${SOURCE_DIR}/logs"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo ""
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Create build directory
mkdir -p "${BUILD_DIR}"

echo "Target architecture: ${TARGET_ARCH}"

# Determine build targets
case "$COMPONENT" in
    core)
        BUILD_TARGETS="crankshaft-core"
        ;;
    ui)
        if [ "$ENABLE_SLIM_UI" = true ]; then
            BUILD_TARGETS="crankshaft-ui crankshaft-slim-ui"
        else
            BUILD_TARGETS="crankshaft-ui"
        fi
        ;;
    tests)
        BUILD_TARGETS="crankshaft-tests"
        ;;
    all)
        if [ "$ENABLE_SLIM_UI" = true ]; then
            BUILD_TARGETS="crankshaft-core crankshaft-ui crankshaft-slim-ui crankshaft-tests"
        else
            BUILD_TARGETS="crankshaft-core crankshaft-ui crankshaft-tests"
        fi
        ;;
esac

# Configure CMake
echo ""
echo "Configuring with CMake..."
CMAKE_ARGS=(
    -S "${SOURCE_DIR}"
    -B "${BUILD_DIR}"
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"
    -DENABLE_SLIM_UI="${ENABLE_SLIM_UI}"
    -DCRANKSHAFT_AASDK_BRANCH="${AASDK_BRANCH}"
    -DTARGET_ARCH="${TARGET_ARCH}"
)

# Run CMake configuration
cmake "${CMAKE_ARGS[@]}" > "${SOURCE_DIR}/logs/cmake.log" 2>&1

# Build
echo ""
echo "Building targets: ${BUILD_TARGETS}..."
NUM_CORES=$(nproc 2>/dev/null || echo 4)
cmake --build "${BUILD_DIR}" --target ${BUILD_TARGETS} -j"${NUM_CORES}" > "${SOURCE_DIR}/logs/build.log" 2>&1

echo ""
echo "✓ Build completed successfully"

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ] && [ "$COMPONENT" != "ui" ]; then
    echo ""
    echo "Running tests..."
    cd "${BUILD_DIR}"
    ctest --output-on-failure -j"${NUM_CORES}" > "${SOURCE_DIR}/logs/test.log" 2>&1 || true
    cd "${SOURCE_DIR}"
else
    if [ "$SKIP_TESTS" = true ]; then
        echo "Tests skipped (--skip-tests flag used)"
    fi
fi

# Package if requested
if [ "$PACKAGE" = true ]; then
    echo ""
    echo "Creating DEB and source packages..."
    cd "${BUILD_DIR}"
    cpack --config CPackConfig.cmake -G "DEB;TGZ" -V > "${SOURCE_DIR}/logs/cpack.log" 2>&1
    cd "${SOURCE_DIR}"
    
    # Copy packages to output directory
    if [ -n "$OUTPUT_DIR" ] && [ "$OUTPUT_DIR" != "${BUILD_DIR}" ]; then
        echo ""
        echo "Copying packages to ${OUTPUT_DIR}..."
        mkdir -p "${OUTPUT_DIR}"
        find "${BUILD_DIR}" -name "*.deb" -o -name "*.tar.gz" -exec cp -v {} "${OUTPUT_DIR}/" \;
        cp -r "${SOURCE_DIR}/logs" "${OUTPUT_DIR}/" 2>/dev/null || true
        echo ""
        echo "Packages in ${OUTPUT_DIR}:"
        ls -lh "${OUTPUT_DIR}"/*.{deb,tar.gz} 2>/dev/null || echo "No packages found"
    else
        echo ""
        echo "Packages in ${BUILD_DIR}:"
        find "${BUILD_DIR}" -name "*.deb" -o -name "*.tar.gz" -ls
    fi
fi

echo ""
echo "=== Build Summary ==="
echo "Build type: ${CMAKE_BUILD_TYPE}"
echo "Component: ${COMPONENT}"
echo "Build directory: ${BUILD_DIR}"

case "$COMPONENT" in
    core)
        if [ -f "${BUILD_DIR}/core/crankshaft-core" ]; then
            echo "Core binary: ${BUILD_DIR}/core/crankshaft-core"
        fi
        ;;
    ui)
        if [ -f "${BUILD_DIR}/ui/crankshaft-ui" ]; then
            echo "UI binary: ${BUILD_DIR}/ui/crankshaft-ui"
        fi
        if [ "$ENABLE_SLIM_UI" = true ] && [ -f "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" ]; then
            echo "Slim UI binary: ${BUILD_DIR}/ui-slim/crankshaft-slim-ui"
        fi
        ;;
    tests)
        echo "Tests built in: ${BUILD_DIR}/tests/"
        ;;
    all)
        echo "Binaries:"
        if [ -f "${BUILD_DIR}/core/crankshaft-core" ]; then
            echo "  Core: ${BUILD_DIR}/core/crankshaft-core"
        fi
        if [ -f "${BUILD_DIR}/ui/crankshaft-ui" ]; then
            echo "  UI: ${BUILD_DIR}/ui/crankshaft-ui"
        fi
        if [ "$ENABLE_SLIM_UI" = true ] && [ -f "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" ]; then
            echo "  Slim UI: ${BUILD_DIR}/ui-slim/crankshaft-slim-ui"
        fi
        ;;
esac

echo ""
echo "Done!"
