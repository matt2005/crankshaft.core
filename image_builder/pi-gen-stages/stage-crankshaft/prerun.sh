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
