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

# DEB package build script for crankshaft-slim-ui

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
PACKAGE_DIR="${PROJECT_ROOT}/packages"
PACKAGING_DIR="${PROJECT_ROOT}/packaging/ui-slim"

# Version detection
if [ -f "${PROJECT_ROOT}/VERSION" ]; then
    VERSION="$(cat "${PROJECT_ROOT}/VERSION")"
else
    VERSION="0.1.0"
fi

# Git commit (if available)
if command -v git >/dev/null 2>&1 && [ -d "${PROJECT_ROOT}/.git" ]; then
    GIT_COMMIT="$(git rev-parse --short=8 HEAD 2>/dev/null || echo "unknown")"
    GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
else
    GIT_COMMIT="unknown"
    GIT_BRANCH="unknown"
fi

# Architecture detection
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "${ARCH}" in
    x86_64|amd64) DEB_ARCH="amd64" ;;
    aarch64|arm64) DEB_ARCH="arm64" ;;
    armv7l|armhf) DEB_ARCH="armhf" ;;
    *) DEB_ARCH="${ARCH}" ;;
esac

# Package name
PACKAGE_NAME="crankshaft-slim-ui_${VERSION}_${DEB_ARCH}"
PACKAGE_BUILD_DIR="${BUILD_DIR}/${PACKAGE_NAME}"

echo "=========================================="
echo "Building DEB package for crankshaft-slim-ui"
echo "=========================================="
echo "Version: ${VERSION}"
echo "Git Commit: ${GIT_COMMIT}"
echo "Git Branch: ${GIT_BRANCH}"
echo "Architecture: ${DEB_ARCH}"
echo "Package: ${PACKAGE_NAME}.deb"
echo "=========================================="
echo ""

# Check if build directory exists
if [ ! -d "${BUILD_DIR}" ]; then
    echo "Error: Build directory not found: ${BUILD_DIR}"
    echo "Please run CMake build first:"
    echo "  mkdir -p build && cd build"
    echo "  cmake -DCMAKE_BUILD_TYPE=Release .."
    echo "  make -j$(nproc)"
    exit 1
fi

# Check if executable exists
if [ ! -f "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" ]; then
    echo "Error: crankshaft-slim-ui executable not found"
    echo "Please build the project first"
    exit 1
fi

# Clean previous package build
if [ -d "${PACKAGE_BUILD_DIR}" ]; then
    echo "Cleaning previous package build..."
    rm -rf "${PACKAGE_BUILD_DIR}"
fi

# Create package structure
echo "Creating package directory structure..."
mkdir -p "${PACKAGE_BUILD_DIR}/DEBIAN"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/bin"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/lib/systemd/system"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/share/crankshaft/slim-ui"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui"
mkdir -p "${PACKAGE_BUILD_DIR}/var/lib/crankshaft/slim-ui"
mkdir -p "${PACKAGE_BUILD_DIR}/var/log/crankshaft"
mkdir -p "${PACKAGE_BUILD_DIR}/etc/crankshaft"

# Copy executable
echo "Copying executable..."
cp "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" "${PACKAGE_BUILD_DIR}/usr/bin/"
chmod 755 "${PACKAGE_BUILD_DIR}/usr/bin/crankshaft-slim-ui"

# Strip debug symbols for release
if [ "${CMAKE_BUILD_TYPE:-Release}" = "Release" ]; then
    echo "Stripping debug symbols..."
    strip "${PACKAGE_BUILD_DIR}/usr/bin/crankshaft-slim-ui" || true
fi

# Copy systemd service
echo "Copying systemd service..."
cp "${PACKAGING_DIR}/crankshaft-slim-ui.service" "${PACKAGE_BUILD_DIR}/usr/lib/systemd/system/"
chmod 644 "${PACKAGE_BUILD_DIR}/usr/lib/systemd/system/crankshaft-slim-ui.service"

# Copy QML files (if present)
if [ -d "${PROJECT_ROOT}/ui-slim/qml" ]; then
    echo "Copying QML files..."
    cp -r "${PROJECT_ROOT}/ui-slim/qml" "${PACKAGE_BUILD_DIR}/usr/share/crankshaft/slim-ui/"
fi

# Copy documentation
echo "Copying documentation..."
if [ -f "${PROJECT_ROOT}/specs/001-slim-aa-ui/quickstart.md" ]; then
    cp "${PROJECT_ROOT}/specs/001-slim-aa-ui/quickstart.md" "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui/quickstart.md"
fi
if [ -f "${PROJECT_ROOT}/ui-slim/README.md" ]; then
    cp "${PROJECT_ROOT}/ui-slim/README.md" "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui/README.md"
fi
if [ -f "${PROJECT_ROOT}/LICENSE" ]; then
    cp "${PROJECT_ROOT}/LICENSE" "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui/LICENSE"
fi

# Create changelog
echo "Creating changelog..."
cat > "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui/changelog" <<EOF
crankshaft-slim-ui (${VERSION}) unstable; urgency=medium

  * Release ${VERSION}
  * Commit: ${GIT_COMMIT}
  * Branch: ${GIT_BRANCH}
  * AndroidAuto projection support
  * Minimal settings interface
  * Error handling system
  * Graceful audio degradation
  * Multi-resolution support (800x480 to 1920x1080)
  * EGLFS and VNC backend support

 -- OpenCarDev Team <maintainers@opencardev.org>  $(date -R)
EOF
gzip -9 "${PACKAGE_BUILD_DIR}/usr/share/doc/crankshaft-slim-ui/changelog"

# Generate control file
echo "Generating control file..."
INSTALLED_SIZE="$(du -sk "${PACKAGE_BUILD_DIR}" | cut -f1)"
cat > "${PACKAGE_BUILD_DIR}/DEBIAN/control" <<EOF
Package: crankshaft-slim-ui
Version: ${VERSION}
Architecture: ${DEB_ARCH}
Maintainer: OpenCarDev Team <maintainers@opencardev.org>
Depends: crankshaft-core (>= 0.1.0), qt6-base-dev (>= 6.2), qt6-declarative-dev (>= 6.2), qt6-multimedia-dev (>= 6.2), libqt6sql6-sqlite, libaasdk (>= 5.2.0), gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-libav, alsa-utils, pulseaudio
Recommends: qt6-qpa-plugins, gstreamer1.0-alsa, gstreamer1.0-pulseaudio
Suggests: tigervnc-standalone-server, x11vnc
Section: x11
Priority: optional
Homepage: https://github.com/opencardev/crankshaft.core
Installed-Size: ${INSTALLED_SIZE}
Description: Slim AndroidAuto UI for Raspberry Pi
 Crankshaft Slim UI provides a lightweight AndroidAuto projection interface
 designed for embedded automotive infotainment systems running on Raspberry Pi.
 .
 Features: AndroidAuto projection (USB and wireless), minimal settings interface,
 responsive QML-based interface, multiple display backend support (EGLFS, VNC),
 graceful audio backend degradation, touch input forwarding, error handling,
 memory efficient (<150MB during active projection).
EOF

# Copy maintainer scripts
echo "Copying maintainer scripts..."
if [ -f "${PACKAGING_DIR}/postinst" ]; then
    cp "${PACKAGING_DIR}/postinst" "${PACKAGE_BUILD_DIR}/DEBIAN/"
    chmod 755 "${PACKAGE_BUILD_DIR}/DEBIAN/postinst"
fi
if [ -f "${PACKAGING_DIR}/prerm" ]; then
    cp "${PACKAGING_DIR}/prerm" "${PACKAGE_BUILD_DIR}/DEBIAN/"
    chmod 755 "${PACKAGE_BUILD_DIR}/DEBIAN/prerm"
fi

# Create conffiles (configuration files that shouldn't be overwritten)
echo "Creating conffiles..."
cat > "${PACKAGE_BUILD_DIR}/DEBIAN/conffiles" <<EOF
/usr/lib/systemd/system/crankshaft-slim-ui.service
EOF

# Set permissions
echo "Setting permissions..."
find "${PACKAGE_BUILD_DIR}" -type d -exec chmod 755 {} \;
find "${PACKAGE_BUILD_DIR}" -type f -exec chmod 644 {} \;
chmod 755 "${PACKAGE_BUILD_DIR}/usr/bin/crankshaft-slim-ui"
if [ -f "${PACKAGE_BUILD_DIR}/DEBIAN/postinst" ]; then
    chmod 755 "${PACKAGE_BUILD_DIR}/DEBIAN/postinst"
fi
if [ -f "${PACKAGE_BUILD_DIR}/DEBIAN/prerm" ]; then
    chmod 755 "${PACKAGE_BUILD_DIR}/DEBIAN/prerm"
fi

# Build package
echo ""
echo "Building DEB package..."
mkdir -p "${PACKAGE_DIR}"
dpkg-deb --build --root-owner-group "${PACKAGE_BUILD_DIR}" "${PACKAGE_DIR}/${PACKAGE_NAME}.deb"

# Verify package
echo ""
echo "Verifying package..."
dpkg-deb --info "${PACKAGE_DIR}/${PACKAGE_NAME}.deb"
echo ""
dpkg-deb --contents "${PACKAGE_DIR}/${PACKAGE_NAME}.deb" | head -n 20

# Lintian check (if available)
if command -v lintian >/dev/null 2>&1; then
    echo ""
    echo "Running lintian checks..."
    lintian "${PACKAGE_DIR}/${PACKAGE_NAME}.deb" || true
fi

echo ""
echo "=========================================="
echo "Package built successfully!"
echo "=========================================="
echo "Location: ${PACKAGE_DIR}/${PACKAGE_NAME}.deb"
echo "Size: $(du -h "${PACKAGE_DIR}/${PACKAGE_NAME}.deb" | cut -f1)"
echo ""
echo "To install:"
echo "  sudo apt install ${PACKAGE_DIR}/${PACKAGE_NAME}.deb"
echo ""
echo "Or:"
echo "  sudo dpkg -i ${PACKAGE_DIR}/${PACKAGE_NAME}.deb"
echo "  sudo apt-get install -f  # Fix dependencies if needed"
echo "=========================================="
