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
set -u

# Script to build Crankshaft consistently across Docker and local environments
# Usage: ./build.sh [release|debug] [--component COMPONENT] [--clean] [--package] [--with-aasdk]

# Default values
BUILD_TYPE="debug"
COMPONENT="all"
CLEAN_BUILD=false
CREATE_PACKAGE=false
WITH_AASDK=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR=""
SKIP_TESTS=false
ENABLE_SLIM_UI_FLAG="OFF"
SKIP_MDI=false
AASDK_BRANCH_OVERRIDE=""
AASDK_STANDARD_OVERRIDE=""
CXX_STANDARD_OVERRIDE=""
AASDK_DIR_OVERRIDE=""
EXTRA_CMAKE_ARGS=()

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
            if [[ $# -lt 2 ]]; then
                echo "Error: --component requires a value"
                exit 1
            fi
            COMPONENT="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --package)
            CREATE_PACKAGE=true
            shift
            ;;
        --with-aasdk)
            WITH_AASDK=true
            shift
            ;;
        --aasdk-branch)
            if [[ $# -lt 2 ]]; then
                echo "Error: --aasdk-branch requires a value (main|newdev)"
                exit 1
            fi
            AASDK_BRANCH_OVERRIDE="$2"
            shift 2
            ;;
        --aasdk-standard)
            if [[ $# -lt 2 ]]; then
                echo "Error: --aasdk-standard requires a value (17|20)"
                exit 1
            fi
            AASDK_STANDARD_OVERRIDE="$2"
            shift 2
            ;;
        --cxx-standard)
            if [[ $# -lt 2 ]]; then
                echo "Error: --cxx-standard requires a value (17|20)"
                exit 1
            fi
            CXX_STANDARD_OVERRIDE="$2"
            shift 2
            ;;
        --cmake-args)
            if [[ $# -lt 2 ]]; then
                echo "Error: --cmake-args requires a value"
                exit 1
            fi
            read -r -a EXTRA_CMAKE_ARGS <<< "$2"
            shift 2
            ;;
        --aasdk-dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: --aasdk-dir requires a value (path to AASDK CMake directory)"
                exit 1
            fi
            AASDK_DIR_OVERRIDE="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --enable-slim-ui)
            ENABLE_SLIM_UI_FLAG="ON"
            shift
            ;;
        --skip-mdi)
            SKIP_MDI=true
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
            echo "  --package      Create DEB packages after building"
            echo "  --with-aasdk   Clone AASDK branch and build/install it"
            echo "  --aasdk-branch Branch to use for AASDK (main|newdev)"
            echo "  --aasdk-standard C++ standard for AASDK (17|20)"
            echo "  --cxx-standard C++ standard for Crankshaft (17|20)"
            echo "  --aasdk-dir    Path to AASDK CMake directory (e.g., /usr/local/lib/cmake/aasdk)"
            echo "  --cmake-args   Extra CMake arguments (quoted string)"
            echo "  --skip-tests   Skip running tests"
            echo "  --enable-slim-ui Enable slim AndroidAuto UI build"
            echo "  --skip-mdi     Skip Material Design Icons download (faster build)"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 release --package"
            echo "  $0 debug --component core --clean"
            echo "  $0 release --with-aasdk --package"
            echo "  $0 release --aasdk-branch newdev --cxx-standard 17"
            echo "  $0 debug --aasdk-dir /usr/local/lib/cmake/aasdk"
            echo "  $0 debug --cmake-args \"-Daasdk_DIR=/usr/local/lib/cmake/aasdk\""}
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

# Detect architecture early for AASDK
TARGET_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH 2>/dev/null || echo "amd64")

detect_aasdk_branch() {
    local header=""
    for candidate in /usr/include/aasdk/Version.hpp /usr/local/include/aasdk/Version.hpp; do
        if [ -f "$candidate" ]; then
            header="$candidate"
            break
        fi
    done

    if [ -n "$header" ]; then
        local branch
        branch=$(grep -E 'GIT_BRANCH' "$header" | sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        if [ -n "$branch" ] && [ "$branch" != "unknown" ]; then
            if [[ "$branch" == *"newdev"* ]]; then
                echo "newdev"
                return
            fi
        fi
    fi

    echo "main"
}

resolve_aasdk_settings() {
    local branch="$AASDK_BRANCH_OVERRIDE"
    local standard="$AASDK_STANDARD_OVERRIDE"

    if [ -z "$branch" ]; then
        branch=$(detect_aasdk_branch)
    fi

    if [ -z "$standard" ]; then
        if [ "$branch" = "newdev" ]; then
            standard="17"
        else
            standard="20"
        fi
    fi

    echo "$branch" "$standard"
}

read -r RESOLVED_AASDK_BRANCH RESOLVED_AASDK_STANDARD < <(resolve_aasdk_settings)

if [ -n "$CXX_STANDARD_OVERRIDE" ]; then
    RESOLVED_CXX_STANDARD="$CXX_STANDARD_OVERRIDE"
else
    RESOLVED_CXX_STANDARD="$RESOLVED_AASDK_STANDARD"
fi

# Handle AASDK cloning and building if requested
if [ "$WITH_AASDK" = true ]; then
    echo ""
    echo "Cloning AASDK ${RESOLVED_AASDK_BRANCH} branch..."
    if [ -d "${SOURCE_DIR}/aasdk-build" ]; then
        rm -rf "${SOURCE_DIR}/aasdk-build"
    fi
    git clone --branch "${RESOLVED_AASDK_BRANCH}" https://github.com/opencardev/aasdk.git "${SOURCE_DIR}/aasdk-build"
    cd "${SOURCE_DIR}/aasdk-build"
    echo "Building and installing AASDK..."
    chmod +x build.sh
    export TARGET_ARCH="$TARGET_ARCH"
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
echo "Package: ${CREATE_PACKAGE}"
echo "AASDK branch: ${RESOLVED_AASDK_BRANCH}"
echo "AASDK standard: ${RESOLVED_AASDK_STANDARD}"
echo "Crankshaft C++ standard: ${RESOLVED_CXX_STANDARD}"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo ""
    echo "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Create build directory

# Detect architecture
TARGET_ARCH=$(dpkg-architecture -qDEB_HOST_ARCH 2>/dev/null || echo "amd64")
echo "Target architecture: ${TARGET_ARCH}"

find_cross_compiler() {
    local prefix="$1"
    local compiler=""
    
    # First try the base name (might be a symlink to latest)
    if command -v "${prefix}gcc" &> /dev/null && [ -x "$(command -v "${prefix}gcc")" ]; then
        compiler="$(command -v "${prefix}gcc")"
    else
        # Find all versioned compilers and pick the latest that actually exists and is executable
        local candidates=()
        for candidate in $(ls /usr/bin/${prefix}gcc-* 2>/dev/null | sort -V); do
            if [ -x "$candidate" ]; then
                candidates+=("$candidate")
            fi
        done
        if [ ${#candidates[@]} -gt 0 ]; then
            compiler="${candidates[-1]}"
        fi
    fi
    
    if [ -n "$compiler" ] && [ -x "$compiler" ]; then
        echo "$compiler"
        return 0
    else
        return 1
    fi
}

setup_cross_compilation() {
    if [ "$TARGET_ARCH" != "amd64" ]; then
        echo "Setting up cross-compilation for ${TARGET_ARCH}..."
        
        case $TARGET_ARCH in
            arm64)
                local c_compiler=$(find_cross_compiler "aarch64-linux-gnu-")
                if [ $? -eq 0 ]; then
                    CMAKE_ARGS+=(-DCMAKE_C_COMPILER="$c_compiler")
                    CMAKE_ARGS+=(-DCMAKE_CXX_COMPILER="${c_compiler/gcc/g++}")
                fi
                ;;
            armhf)
                local c_compiler=$(find_cross_compiler "arm-linux-gnueabihf-")
                if [ $? -eq 0 ]; then
                    CMAKE_ARGS+=(-DCMAKE_C_COMPILER="$c_compiler")
                    CMAKE_ARGS+=(-DCMAKE_CXX_COMPILER="${c_compiler/gcc/g++}")
                fi
                ;;
        esac
    fi
}

# Determine build targets
case "$COMPONENT" in
    core)
        BUILD_TARGETS="crankshaft-core"
        ;;
    ui)
        if [ "$ENABLE_SLIM_UI_FLAG" = "ON" ]; then
            BUILD_TARGETS="crankshaft-ui crankshaft-slim-ui"
        else
            BUILD_TARGETS="crankshaft-ui"
        fi
        ;;
    tests)
        BUILD_TARGETS="crankshaft-tests"
        ;;
    all)
        if [ "$ENABLE_SLIM_UI_FLAG" = "ON" ]; then
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
    -DENABLE_SLIM_UI="${ENABLE_SLIM_UI_FLAG}"
    -DCRANKSHAFT_AASDK_BRANCH="${RESOLVED_AASDK_BRANCH}"
    -DCRANKSHAFT_AASDK_STANDARD="${RESOLVED_AASDK_STANDARD}"
    -DCRANKSHAFT_CXX_STANDARD="${RESOLVED_CXX_STANDARD}"
)

# Skip MDI download if requested
if [ "$SKIP_MDI" = true ]; then
    CMAKE_ARGS+=(-DFORCE_GENERATE_MDI_MAPPINGS=OFF)
fi

# Add AASDK directory override if specified
if [ -n "${AASDK_DIR_OVERRIDE}" ]; then
    CMAKE_ARGS+=(-Daasdk_DIR="${AASDK_DIR_OVERRIDE}" -DAASDK_DIR="${AASDK_DIR_OVERRIDE}")
fi

CMAKE_ARGS+=("${EXTRA_CMAKE_ARGS[@]}")

setup_cross_compilation

# Run CMake configuration
cmake "${CMAKE_ARGS[@]}"

# Build
echo ""
echo "Building targets: ${BUILD_TARGETS}..."
NUM_CORES=$(nproc 2>/dev/null || echo 4)
cmake --build "${BUILD_DIR}" --target ${BUILD_TARGETS} -j"${NUM_CORES}"

echo ""
echo "✓ Build completed successfully"

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ] && [ "$COMPONENT" != "ui" ]; then
    echo ""
    echo "Running tests..."
    cd "${BUILD_DIR}"
    ctest --output-on-failure -j"${NUM_CORES}" || true
    cd "${SOURCE_DIR}"
else
    if [ "$SKIP_TESTS" = true ]; then
        echo "Tests skipped (--skip-tests flag used)"
    fi
fi

# Package if requested
if [ "$CREATE_PACKAGE" = true ]; then
    echo ""
    echo "Creating DEB packages..."
    cd "${BUILD_DIR}"
    cpack --config CPackConfig.cmake -G DEB -V
    cd "${SOURCE_DIR}"
    
    echo ""
    echo "Packages in ${BUILD_DIR}:"
    ls -lh "${BUILD_DIR}"/*.deb 2>/dev/null || echo "No packages found"
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
        if [ "$ENABLE_SLIM_UI_FLAG" = "ON" ] && [ -f "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" ]; then
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
        if [ "$ENABLE_SLIM_UI_FLAG" = "ON" ] && [ -f "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" ]; then
            echo "  Slim UI: ${BUILD_DIR}/ui-slim/crankshaft-slim-ui"
        fi
        ;;
esac

echo ""
echo "Done!"
