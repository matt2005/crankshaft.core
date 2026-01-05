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

# Crankshaft Package Installation Script
# Installs Crankshaft core and base extensions from OpenCarDev APT repository

set -e

# This script runs inside the chroot environment via pi-gen's run_chroot

echo "===================================================================="
echo "Crankshaft Package Installation"
echo "===================================================================="

# Update package lists
echo "Updating package lists..."
apt-get update

# Install basic dependencies
echo "Installing base dependencies..."
apt-get install -y \
    wget \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates

# Add OpenCarDev APT repository GPG key
# TODO: Replace with actual GPG key when repository is live
echo "Adding OpenCarDev GPG key (placeholder)..."
# wget -qO - https://apt.opencardev.org/debian/opencardev-archive-keyring.gpg | apt-key add -

# Update package lists with new repository
echo "Refreshing package lists..."
apt-get update || {
    echo "Warning: APT update failed - OpenCarDev repository may not be available yet"
    echo "This is expected for MVP development - packages will be installed when repository is live"
    echo "Proceeding with base system installation..."
}

# Install Qt6 and multimedia dependencies
echo "Installing Qt6 and multimedia libraries..."
apt-get install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtmultimedia \
    libqt6multimedia6 \
    libqt6multimediawidgets6 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-alsa \
    gstreamer1.0-pulseaudio

# Install Bluetooth support
echo "Installing Bluetooth support..."
apt-get install -y \
    bluez \
    bluez-tools \
    pulseaudio-module-bluetooth

# Install audio system (PipeWire for Pi 4/5, PulseAudio fallback)
echo "Installing audio system..."
if [ "${CRANKSHAFT_AUDIO_SYSTEM}" = "pipewire" ]; then
    echo "Installing PipeWire (modern audio system)..."
    apt-get install -y \
        pipewire \
        pipewire-pulse \
        pipewire-audio-client-libraries \
        wireplumber
else
    echo "Installing PulseAudio (fallback for Pi 3/Zero 2)..."
    apt-get install -y \
        pulseaudio \
        pulseaudio-utils \
        pavucontrol
fi

# Install network management
echo "Installing network management..."
apt-get install -y \
    network-manager \
    network-manager-gnome

# Install Crankshaft packages (when available)
echo "Installing Crankshaft packages..."
# TODO: Uncomment when packages are available in repository
# apt-get install -y \
#     ${CRANKSHAFT_CORE_PKG:-crankshaft-core} \
#     ${CRANKSHAFT_UI_PKG:-crankshaft-ui} \
#     ${CRANKSHAFT_MEDIA_PKG:-crankshaft-media} \
#     ${CRANKSHAFT_BLUETOOTH_PKG:-crankshaft-bluetooth} \
#     ${CRANKSHAFT_RADIO_PKG:-crankshaft-radio}

echo "Crankshaft packages will be installed when OpenCarDev repository is live"
echo "For MVP development, using placeholder binaries"

# Create placeholder directories
mkdir -p /usr/lib/crankshaft
mkdir -p /usr/lib/crankshaft/extensions
mkdir -p /etc/crankshaft

# Create placeholder config
cat > /etc/crankshaft/config.ini << EOF
[General]
Theme=dark
Language=en_GB

[Display]
Platform=eglfs
Resolution=1920x1080

[Audio]
System=${CRANKSHAFT_AUDIO_SYSTEM:-pipewire}
DefaultSink=hdmi

[Network]
AutoConnect=true
EOF

# Clean up APT cache to reduce image size
echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "===================================================================="
echo "Crankshaft Package Installation Complete"
echo "===================================================================="

exit 0
