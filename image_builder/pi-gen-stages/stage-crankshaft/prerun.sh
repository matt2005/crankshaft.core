#!/bin/bash
#
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

# Pre-run script for stage-crankshaft
# Sets up the APT repository before package installation

set -e

echo "Stage Crankshaft: Pre-run setup"

# Set root filesystem path (required by pi-gen)
if [ -z "$ROOTFS_DIR" ]; then
    ROOTFS_DIR="${STAGE_WORK_DIR}/rootfs"
fi

echo "Root filesystem directory: ${ROOTFS_DIR}"

# Verify root filesystem exists
if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "Error: Root filesystem directory not found: ${ROOTFS_DIR}"
    exit 1
fi

echo "Rootfs verified"

# ====================================================================
# APT REPOSITORY CONFIGURATION
# ====================================================================
echo "Configuring OpenCarDev APT repository..."

# Set default values if not provided by config
CRANKSHAFT_APT_REPO="${CRANKSHAFT_APT_REPO:-http://apt.opencardev.org/debian}"
CRANKSHAFT_APT_SUITE="${CRANKSHAFT_APT_SUITE:-trixie}"
CRANKSHAFT_APT_COMPONENT="${CRANKSHAFT_APT_COMPONENT:-nightly}"

echo "APT Repository: ${CRANKSHAFT_APT_REPO}"
echo "APT Suite: ${CRANKSHAFT_APT_SUITE}"
echo "APT Component: ${CRANKSHAFT_APT_COMPONENT}"

# Create APT sources list entry (will be used by 00-install-crankshaft script)
mkdir -p "${ROOTFS_DIR}/etc/apt/sources.list.d"
cat > "${ROOTFS_DIR}/etc/apt/sources.list.d/opencardev.list" << EOF
# OpenCarDev Crankshaft Package Repository
deb ${CRANKSHAFT_APT_REPO} ${CRANKSHAFT_APT_SUITE} ${CRANKSHAFT_APT_COMPONENT}
EOF

echo "APT sources configured"

# Add OpenCarDev GPG key (placeholder - will need actual key in production)
# TODO: Download and install actual GPG key when repository is live
# For now, create placeholder to prevent APT warnings
mkdir -p "${ROOTFS_DIR}/usr/share/keyrings"
echo "Placeholder for OpenCarDev GPG key - TODO: Add actual key" > "${ROOTFS_DIR}/usr/share/keyrings/opencardev-archive-keyring.gpg.placeholder"

# ====================================================================
# PACKAGE VALIDATION (PRE-FLIGHT CHECK)
# ====================================================================
echo "Validating Crankshaft package availability..."

# Set default package names if not provided
CRANKSHAFT_CORE_PKG="${CRANKSHAFT_CORE_PKG:-crankshaft-core}"
CRANKSHAFT_UI_PKG="${CRANKSHAFT_UI_PKG:-crankshaft-ui}"

echo "Expected packages:"
echo "  - ${CRANKSHAFT_CORE_PKG}"
echo "  - ${CRANKSHAFT_UI_PKG}"
echo "  - ${CRANKSHAFT_MEDIA_PKG:-crankshaft-media}"
echo "  - ${CRANKSHAFT_BLUETOOTH_PKG:-crankshaft-bluetooth}"
echo "  - ${CRANKSHAFT_RADIO_PKG:-crankshaft-radio}"

# Note: Actual package availability check will happen during 00-install-crankshaft
# This prerun just sets up the environment
echo "Package validation will occur during installation stage"

# ====================================================================
# ENVIRONMENT VALIDATION
# ====================================================================
echo "Validating build environment..."

# Check for required variables
if [ -z "$IMG_NAME" ]; then
    echo "Warning: IMG_NAME not set, defaulting to 'crankshaft'"
    export IMG_NAME='crankshaft'
fi

if [ -z "$RELEASE" ]; then
    echo "Warning: RELEASE not set, defaulting to 'trixie'"
    export RELEASE='trixie'
fi

echo "Build configuration:"
echo "  Image name: ${IMG_NAME}"
echo "  Release: ${RELEASE}"
echo "  Architecture: $(uname -m)"

echo "Stage Crankshaft pre-run complete"
