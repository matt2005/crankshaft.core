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

# Post-run script for stage60 (Crankshaft configuration)
# Performs final image configuration and generates metadata

set -e

echo "Stage 60: Post-run Crankshaft configuration"

# Set root filesystem path
if [ -z "$ROOTFS_DIR" ]; then
    ROOTFS_DIR="${STAGE_WORK_DIR}/rootfs"
fi

# Create OpenCarDev metadata directory
METADATA_DIR="${ROOTFS_DIR}/etc/opencardev"
mkdir -p "${METADATA_DIR}"

# Generate version information
cat > "${METADATA_DIR}/version.txt" << EOF
Crankshaft Infotainment System
Build Date: $(date -u +%Y-%m-%d)
Pi-Gen Branch: ${PI_GEN_BRANCH:-unknown}
Architecture: ${ARCHITECTURE:-unknown}
Debian Release: ${DEBIAN_RELEASE:-unknown}
EOF

# Generate SBOM metadata (simplified)
cat > "${METADATA_DIR}/manifest.json" << 'EOF'
{
  "name": "Crankshaft Pi Image",
  "version": "1.0",
  "components": [
    {
      "name": "Crankshaft",
      "type": "application",
      "repository": "https://github.com/opencardev/crankshaft"
    {
      "name": "Raspberry Pi OS Lite",
      "type": "os",
      "repository": "https://github.com/RPi-Distro/pi-gen"
    }
  ]
}
EOF

echo "Metadata generated"

# ====================================================================
# SYSTEMD SERVICE CONFIGURATION
# ====================================================================
echo "Enabling Crankshaft systemd service..."

# Copy systemd service file
if [ -f "${STAGE_DIR}/files/crankshaft.service" ]; then
    install -m 644 "${STAGE_DIR}/files/crankshaft.service" "${ROOTFS_DIR}/etc/systemd/system/crankshaft.service"
    echo "Systemd service file installed"
    
    # Enable service for auto-start
    run_root systemctl enable crankshaft.service || {
        echo "Warning: Failed to enable crankshaft.service"
    }
    echo "Crankshaft service enabled for auto-start"
else
    echo "Warning: crankshaft.service file not found"
fi

# Copy boot configuration
if [ -f "${STAGE_DIR}/files/config.txt" ]; then
    cat "${STAGE_DIR}/files/config.txt" >> "${ROOTFS_DIR}/boot/config.txt"
    echo "Boot configuration appended"
else
    echo "Warning: config.txt file not found"
fi

# ====================================================================
# FIRST-BOOT FILESYSTEM RESIZE
# ====================================================================
echo "Configuring first-boot filesystem resize..."

# Copy resize script
if [ -f "${STAGE_DIR}/files/resize-rootfs.sh" ]; then
    install -m 755 "${STAGE_DIR}/files/resize-rootfs.sh" "${ROOTFS_DIR}/usr/local/sbin/resize-rootfs.sh"
    echo "Resize script installed"
else
    echo "Warning: resize-rootfs.sh not found"
fi

# Create first-boot resize service
cat > "${ROOTFS_DIR}/etc/systemd/system/resize-rootfs.service" << 'EOF'
[Unit]
Description=Resize root filesystem on first boot
Before=multi-user.target
ConditionPathExists=!/etc/crankshaft-resized

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/resize-rootfs.sh
ExecStartPost=/bin/touch /etc/crankshaft-resized
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable first-boot resize service
run_root systemctl enable resize-rootfs.service || {
    echo "Warning: Failed to enable resize-rootfs.service"
}

echo "First-boot filesystem resize configured"

# ====================================================================
# FINAL CLEANUP
# ====================================================================
echo "Running final cleanup..."

# Ensure SSH is enabled
run_root systemctl is-enabled ssh || run_root systemctl enable ssh

# Verify user account
run_root grep "^pi:" /etc/passwd || echo "Warning: pi user not found"

# Clean package manager cache
run_root apt-get clean || true
run_root rm -rf /var/lib/apt/lists/* || true

echo "Stage 60 post-run configuration complete"
