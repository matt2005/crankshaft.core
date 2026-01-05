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

# Post-run script for stage-crankshaft
# Performs final image configuration and generates metadata

set -e

echo "Stage Crankshaft: Post-run configuration"

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
      "repository": "https://github.com/opencardev/crankshaft-mvp"
    },
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
        echo "Warning: Failed to enable crankshaft.service - service may need manual enabling"
    }
    echo "Crankshaft service enabled for auto-start"
else
    echo "Warning: crankshaft.service file not found at ${STAGE_DIR}/files/crankshaft.service"
fi

# Copy boot configuration
if [ -f "${STAGE_DIR}/files/config.txt" ]; then
    cat "${STAGE_DIR}/files/config.txt" >> "${ROOTFS_DIR}/boot/config.txt"
    echo "Boot configuration appended to /boot/config.txt"
else
    echo "Warning: config.txt file not found at ${STAGE_DIR}/files/config.txt"
fi

# ====================================================================
# FIRST-BOOT FILESYSTEM RESIZE
# ====================================================================
echo "Configuring first-boot filesystem resize..."

# Copy resize script
if [ -f "${STAGE_DIR}/files/resize-rootfs.sh" ]; then
    install -m 755 "${STAGE_DIR}/files/resize-rootfs.sh" "${ROOTFS_DIR}/usr/local/bin/resize-rootfs.sh"
    echo "Resize script installed"
    
    # Create systemd service for one-time resize
    cat > "${ROOTFS_DIR}/etc/systemd/system/resize-rootfs.service" << 'EOF'
[Unit]
Description=Crankshaft First-Boot Filesystem Resize
DefaultDependencies=no
After=local-fs.target
Before=basic.target
ConditionPathExists=!/etc/crankshaft-resized

[Service]
Type=oneshot
ExecStart=/usr/local/bin/resize-rootfs.sh
ExecStartPost=/bin/touch /etc/crankshaft-resized
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=basic.target
EOF
    
    run_root systemctl enable resize-rootfs.service || {
        echo "Warning: Failed to enable resize-rootfs.service"
    }
    echo "First-boot resize service configured"
else
    echo "Warning: resize-rootfs.sh file not found at ${STAGE_DIR}/files/resize-rootfs.sh"
fi

# ====================================================================
# SSH CONFIGURATION
# ====================================================================
echo "Verifying SSH configuration..."

# SSH should be enabled by pi-gen's ENABLE_SSH=1
# Just verify the service exists
if run_root systemctl is-enabled ssh 2>/dev/null || run_root systemctl is-enabled sshd 2>/dev/null; then
    echo "SSH service is enabled (as expected for MVP debugging)"
else
    echo "Warning: SSH service not enabled - manual configuration may be required"
fi

# ====================================================================
# USER ACCOUNT VALIDATION
# ====================================================================
echo "Validating default user account..."

# Check if pi user exists with correct configuration
if run_root id -u pi >/dev/null 2>&1; then
    echo "User 'pi' exists"
    
    # Verify sudo privileges
    if run_root groups pi | grep -q sudo; then
        echo "User 'pi' has sudo privileges"
    else
        echo "Warning: User 'pi' does not have sudo privileges"
    fi
else
    echo "Warning: User 'pi' does not exist - this is unexpected"
fi

# Clean up logs and temporary files to reduce image size
echo "Cleaning up temporary files..."
run_root bash -c 'apt-get clean || true'
run_root bash -c 'rm -rf /tmp/* /var/tmp/* || true'
run_root bash -c 'truncate -s 0 /var/log/*log || true'

echo "Stage Crankshaft post-run complete"
