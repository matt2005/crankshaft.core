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

# Default values
BUILD_TYPE="Debug"
COMPONENT="all"
BUILD_DIR="build"
CREATE_PACKAGE=false
INSTALL_DEPS=false
VERSION=""
ARCHITECTURE=""
SKIP_TESTS=false
# Build options
ENABLE_SLIM_UI_FLAG="OFF"
BUILD_AASDK=false
# Default Debian suite from host, fall back to trixie
DEBIAN_SUITE=${VERSION_CODENAME:-trixie}

# Dependency installation functions
install_core_deps() {
    echo "Installing core dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        pkg-config \
        lsb-release \
        python3 \
        python3-requests \
        libdbus-1-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-tools \
        qt6-connectivity-dev \
        qt6-qpa-plugins \
        libasound2-dev \
        libpulse-dev \
        file \
        dpkg-dev
    echo "Core dependencies installed successfully"
}

install_aasdk_deps() {
    echo "Installing AASDK dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        libusb-1.0-0-dev \
        libssl-dev \
        libprotobuf-dev \
        protobuf-compiler \
        libboost-system-dev \
        libboost-log-dev \
        libboost-thread-dev \
        libboost-all-dev
    echo "AASDK dependencies installed successfully"
}

install_ui_deps() {
    echo "Installing UI dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        qt6-base-dev \
        qt6-declarative-dev \
        qt6-tools-dev \
        qt6-websockets-dev \
        qt6-qpa-plugins \
        qml6-module-qtquick \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-layouts \
        qml6-module-qtquick-window \
        libgl1-mesa-dev \
        libvulkan-dev
    echo "UI dependencies installed successfully"
}

install_all_deps() {
    echo "Installing all dependencies..."
    install_core_deps
    install_aasdk_deps
    install_ui_deps
    echo "All dependencies installed successfully"
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Named parameters:
  --build-type TYPE      Build configuration (Debug|Release) [default: Debug]
  --component COMP       Component to build (all|core|ui|tests) [default: all]
  --package              Create DEB packages after building [default: false]
  --version VERSION      Override project version (default: from CMakeLists.txt)
  --debian-suite SUITE   Target Debian suite (trixie|bookworm) [default: trixie]
  --architecture ARCH    Target architecture (amd64|arm64|armhf) [default: auto-detect]
    --skip-tests           Skip running tests during build [default: false]
    --enable-slim-ui       Enable slim AndroidAuto UI build (ENABLE_SLIM_UI=ON)
    --build-aasdk         Build AASDK from submodule (default: false, use system packages)
  --install-deps         Install dependencies for the specified component
  --help                 Display this help message

Examples:
  $0                                      # Build all components in Debug mode
  $0 --build-type Release                 # Build all components in Release mode
  $0 --component ui --build-type Debug    # Build only UI in Debug mode
  $0 --build-type Release --package       # Build all in Release mode and create packages
  $0 --build-type Release --package --debian-suite trixie  # Package for trixie
  $0 --architecture amd64 --skip-tests    # Build for amd64 only, skip tests
  $0 --install-deps                       # Install all dependencies
  $0 --component core --install-deps      # Install only core dependencies
  $0 --build-aasdk --build-type Release   # Build with AASDK from submodule
EOF
    exit 1
}

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-type)
            if [[ $# -lt 2 ]]; then
                echo "Error: --build-type requires a value"
                usage
            fi
            BUILD_TYPE="$2"
            shift 2
            ;;
        --component)
            if [[ $# -lt 2 ]]; then
                echo "Error: --component requires a value"
                usage
            fi
            COMPONENT="$2"
            shift 2
            ;;
        --package)
            CREATE_PACKAGE=true
            shift
            ;;
        --version)
            if [[ $# -lt 2 ]]; then
                echo "Error: --version requires a value"
                usage
            fi
            VERSION="$2"
            shift 2
            ;;
        --debian-suite)
            if [[ $# -lt 2 ]]; then
                echo "Error: --debian-suite requires a value"
                usage
            fi
            DEBIAN_SUITE="$2"
            shift 2
            ;;
        --architecture)
            if [[ $# -lt 2 ]]; then
                echo "Error: --architecture requires a value"
                usage
            fi
            ARCHITECTURE="$2"
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
        --build-aasdk)
            BUILD_AASDK=true
            shift
            ;;
        --install-deps)
            INSTALL_DEPS=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Error: Unknown option '$1'"
            usage
            ;;
    esac
done

# Handle dependency installation
if [ "$INSTALL_DEPS" = true ]; then
    case "$COMPONENT" in
        all)
            install_all_deps
            ;;
        core)
            install_core_deps
            ;;
        ui)
            install_ui_deps
            ;;
        aasdk)
            install_aasdk_deps
            ;;
        *)
            echo "Error: Invalid component for dependency installation '$COMPONENT'."
            echo "Valid components: all, core, ui, aasdk"
            exit 1
            ;;
    esac
    exit 0
fi

# Validate build type
if [[ "$BUILD_TYPE" != "Debug" && "$BUILD_TYPE" != "Release" ]]; then
    echo "Error: Invalid build type '$BUILD_TYPE'. Must be 'Debug' or 'Release'."
    usage
fi

# Validate Debian suite
if [[ "$DEBIAN_SUITE" != "trixie" && "$DEBIAN_SUITE" != "bookworm" ]]; then
    echo "Error: Invalid Debian suite '$DEBIAN_SUITE'. Must be 'trixie' or 'bookworm'."
    usage
fi

# Validate architecture
if [[ -n "$ARCHITECTURE" && "$ARCHITECTURE" != "amd64" && "$ARCHITECTURE" != "arm64" && "$ARCHITECTURE" != "armhf" ]]; then
    echo "Error: Invalid architecture '$ARCHITECTURE'. Must be 'amd64', 'arm64', or 'armhf'."
    usage
fi

# Set architecture-specific CMake flags if specified
ARCH_CMAKE_FLAGS=""
if [[ -n "$ARCHITECTURE" ]]; then
    case "$ARCHITECTURE" in
        amd64)
            ARCH_CMAKE_FLAGS="-DCMAKE_SYSTEM_PROCESSOR=x86_64"
            ;;
        arm64)
            ARCH_CMAKE_FLAGS="-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64"
            ;;
        armhf)
            ARCH_CMAKE_FLAGS="-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7l"
            ;;
    esac
fi

# Validate component
if [[ "$COMPONENT" != "all" && "$COMPONENT" != "core" && "$COMPONENT" != "ui" && "$COMPONENT" != "tests" ]]; then
    echo "Error: Invalid component '$COMPONENT'. Must be 'all', 'core', 'ui', or 'tests'."
    usage
fi

# Determine build targets
case "$COMPONENT" in
    core)
        BUILD_TARGETS="crankshaft-core"
        ;;
    ui)
        BUILD_TARGETS="crankshaft-ui crankshaft-ui-slim"
        ;;
    tests)
        BUILD_TARGETS="crankshaft-tests"
        ;;
    all)
        BUILD_TARGETS="crankshaft-core crankshaft-ui crankshaft-ui-slim"
        ;;
esac

echo "Building Crankshaft MVP: Component=${COMPONENT}, Build Type=${BUILD_TYPE}, Architecture=${ARCHITECTURE:-auto}"

# Create build directory
mkdir -p "${BUILD_DIR}"

# Configure
echo "Configuring CMake..."
if [ -n "$VERSION" ]; then
    echo "Using custom version: $VERSION"
    cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DCMAKE_PROJECT_VERSION="${VERSION}" -DDEBIAN_SUITE="${DEBIAN_SUITE}" -DENABLE_SLIM_UI="${ENABLE_SLIM_UI_FLAG}" -DBUILD_AASDK="${BUILD_AASDK}" $ARCH_CMAKE_FLAGS
else
    cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DDEBIAN_SUITE="${DEBIAN_SUITE}" -DENABLE_SLIM_UI="${ENABLE_SLIM_UI_FLAG}" -DBUILD_AASDK="${BUILD_AASDK}" $ARCH_CMAKE_FLAGS
fi

# Build (parallel targets: core, ui, ui-slim)
echo "Building targets: ${BUILD_TARGETS}..."
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" --target ${BUILD_TARGETS} -j"$(nproc)"

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ] && [ "$COMPONENT" != "ui" ]; then
    echo ""
    echo "Running tests..."
    cd "${BUILD_DIR}"
    ctest --output-on-failure -j"$(nproc)" || true
    cd ..
else
    if [ "$SKIP_TESTS" = true ]; then
        echo "Tests skipped (--skip-tests flag used)"
    fi
fi

echo ""
echo "Build complete!"
case "$COMPONENT" in
    core)
        echo "Executable: ${BUILD_DIR}/core/crankshaft-core"
        ;;
    ui)
        echo "Executable: ${BUILD_DIR}/ui/crankshaft-ui"
        ;;
    tests)
        if [ "$SKIP_TESTS" = false ]; then
            echo "Tests: ${BUILD_DIR}/tests/test_eventbus"
            echo "Tests: ${BUILD_DIR}/tests/test_websocket"
        fi
        ;;
    all)
        echo "Executables:"
        echo "  Core:  ${BUILD_DIR}/core/crankshaft-core"
        echo "  UI:    ${BUILD_DIR}/ui/crankshaft-ui"
        if [ "$SKIP_TESTS" = false ]; then
            echo "  Tests: ${BUILD_DIR}/tests/test_eventbus"
            echo "  Tests: ${BUILD_DIR}/tests/test_websocket"
        fi
        ;;
esac

# Create packages if requested
if [ "$CREATE_PACKAGE" = true ]; then
    echo ""
    echo "Creating DEB packages (binary)..."
    cd "${BUILD_DIR}"
    cpack --config CPackConfig.cmake -G DEB -V
    cd ..
    
    echo ""
    echo "Creating source tarball package..."
    cd "${BUILD_DIR}"
    cpack --config CPackSourceConfig.cmake -G TGZ -V
    cd ..
    
    echo ""
    echo "Packages created in ${BUILD_DIR}:"
    ls -lh "${BUILD_DIR}"/*.deb "${BUILD_DIR}"/*.tar.gz 2>/dev/null || echo "No packages found"
fi
