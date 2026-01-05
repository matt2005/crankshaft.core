#!/bin/bash -e

if [ ! -d "${ROOTFS_DIR}" ]; then
	copy_previous
fi

# Configure apt for better mirror reliability and retry behavior
echo "Configuring apt for better mirror reliability..."
cat > "${ROOTFS_DIR}/etc/apt/apt.conf.d/99build-reliability" << 'EOF'
# Build reliability configuration for better mirror handling
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::ftp::Timeout "30";
APT::Get::fix-missing "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

echo "APT configuration added for build reliability"

# ====================================================================
# CRANKSHAFT APT REPOSITORY CONFIGURATION
# ====================================================================
echo "Configuring OpenCarDev APT repository..."

# Set default values if not provided by config
CRANKSHAFT_APT_REPO="${CRANKSHAFT_APT_REPO:-http://apt.opencardev.org/debian}"
CRANKSHAFT_APT_SUITE="${CRANKSHAFT_APT_SUITE:-trixie}"
CRANKSHAFT_APT_COMPONENT="${CRANKSHAFT_APT_COMPONENT:-nightly}"

echo "APT Repository: ${CRANKSHAFT_APT_REPO}"
echo "APT Suite: ${CRANKSHAFT_APT_SUITE}"
echo "APT Component: ${CRANKSHAFT_APT_COMPONENT}"

# Create APT sources list entry for Crankshaft packages
mkdir -p "${ROOTFS_DIR}/etc/apt/sources.list.d"
cat > "${ROOTFS_DIR}/etc/apt/sources.list.d/opencardev.list" << EOF
# OpenCarDev Crankshaft Package Repository
deb ${CRANKSHAFT_APT_REPO} ${CRANKSHAFT_APT_SUITE} ${CRANKSHAFT_APT_COMPONENT}
EOF

echo "APT sources configured for Crankshaft"

# Add OpenCarDev GPG key (placeholder - will need actual key in production)
mkdir -p "${ROOTFS_DIR}/usr/share/keyrings"
echo "Placeholder for OpenCarDev GPG key - TODO: Add actual key" > "${ROOTFS_DIR}/usr/share/keyrings/opencardev-archive-keyring.gpg.placeholder"
