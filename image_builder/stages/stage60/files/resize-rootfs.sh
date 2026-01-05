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

# First-Boot Filesystem Resize Script
# Automatically expands rootfs to use full SD card capacity on first boot
# Based on raspi-config init_resize.sh

set -e

echo "Crankshaft: First-boot filesystem resize"

# Get root partition info
ROOT_PART=$(findmnt / -o source -n)
ROOT_DEV=$(lsblk -no pkname "${ROOT_PART}")

echo "Root partition: ${ROOT_PART}"
echo "Root device: ${ROOT_DEV}"

# Check if resize is needed
PART_NUM=$(echo "${ROOT_PART}" | grep -o "[0-9]*$")
PART_START=$(parted /dev/${ROOT_DEV} -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
PART_END=$(parted /dev/${ROOT_DEV} -ms unit s p | grep "^${PART_NUM}" | cut -f 3 -d: | sed 's/[^0-9]//g')
DISK_SIZE=$(parted /dev/${ROOT_DEV} -ms unit s p | head -n 1 | cut -f 2 -d: | sed 's/[^0-9]//g')

echo "Partition ${PART_NUM}: start=${PART_START}s, end=${PART_END}s"
echo "Disk size: ${DISK_SIZE}s"

# Calculate if expansion is needed (allow 1MB margin)
MARGIN=$((2048))  # 1MB in 512-byte sectors
if [ $((PART_END + MARGIN)) -ge ${DISK_SIZE} ]; then
    echo "Partition already uses full disk capacity - no resize needed"
    exit 0
fi

echo "Expanding partition to use full disk..."

# Resize partition
parted /dev/${ROOT_DEV} ---pretend-input-tty resizepart ${PART_NUM} 100% || {
    echo "Error: Failed to resize partition"
    exit 1
}

# Resize filesystem
resize2fs ${ROOT_PART} || {
    echo "Error: Failed to resize filesystem"
    exit 1
}

echo "Filesystem resize complete"

# Report new size
df -h / | grep -v Filesystem

exit 0
