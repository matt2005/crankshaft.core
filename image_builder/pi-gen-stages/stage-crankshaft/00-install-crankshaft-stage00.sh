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

# Stage Crankshaft: Install Crankshaft infotainment system
# This script installs Crankshaft packages and configures the system

set -e

echo "Stage Crankshaft: Installing Crankshaft infotainment system"

# Use run_root function provided by pi-gen for chroot commands
# This allows us to run commands inside the rootfs

# Set up environment variables
export DEBIAN_FRONTEND=noninteractive

# Update package lists
run_root bash -c 'apt-get update'

# Add OpenCarDev APT repository if not already present
if ! grep -q "apt.opencardev.com" ${ROOTFS_DIR}/etc/apt/sources.list.d/* 2>/dev/null; then
    echo "Adding OpenCarDev APT repository..."
    
    # Download and install the repository key
    run_root bash -c 'apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x1234567890ABCDEF 2>/dev/null || true'
    
    # Add repository (use nightly for development, stable for releases)
    run_root bash -c 'echo "deb [arch=amd64,arm64,armhf] https://apt.opencardev.com/nightly jammy main" > /etc/apt/sources.list.d/crankshaft.sources'
    
    # Update package lists again with new repository
    run_root bash -c 'apt-get update'
else
    echo "OpenCarDev repository already configured"
fi

# Install Crankshaft packages
echo "Installing Crankshaft packages..."
run_root bash -c 'apt-get install -y crankshaft crankshaft-ui crankshaft-extensions || apt-get install -y crankshaft'

# Enable Crankshaft service to start on boot
echo "Enabling Crankshaft service..."
run_root bash -c 'systemctl enable crankshaft || true'

# Configure first-boot script for Crankshaft setup
echo "Creating first-boot setup script..."
cat > ${ROOTFS_DIR}/usr/local/bin/crankshaft-first-boot.sh << 'FIRSTBOOTSCRIPT'
#!/bin/bash
# Crankshaft first-boot configuration script

echo "Crankshaft first-boot setup..."

# Resize root filesystem to fill disk
/usr/lib/raspberrypi-sys-mods/imager_custom_yaml_to_pi4.sh || true

# Set locale and timezone
localectl set-locale LANG=en_GB.UTF-8
timedatectl set-timezone Europe/London

# Start Crankshaft services
systemctl start crankshaft || true

# Mark setup as complete
touch /etc/crankshaft-first-boot-complete

echo "Crankshaft first-boot setup complete"
FIRSTBOOTSCRIPT

run_root bash -c 'chmod +x /usr/local/bin/crankshaft-first-boot.sh'

# Create systemd service for first-boot execution
cat > ${ROOTFS_DIR}/etc/systemd/system/crankshaft-first-boot.service << 'FIRSTBOOTSERVICE'
[Unit]
Description=Crankshaft First Boot Setup
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/etc/crankshaft-first-boot-complete

[Service]
Type=oneshot
ExecStart=/usr/local/bin/crankshaft-first-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
FIRSTBOOTSERVICE

run_root bash -c 'systemctl daemon-reload'
run_root bash -c 'systemctl enable crankshaft-first-boot || true'

# Display installation summary
echo "Crankshaft installation complete!"
echo "Installed packages:"
run_root bash -c 'dpkg -l | grep crankshaft || echo "No crankshaft packages found"'
