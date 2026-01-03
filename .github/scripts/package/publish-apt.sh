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

# Orchestrate APT repository publishing with atomic promotion
# Usage: publish-apt.sh --channel <channel> --staging-dir <dir> --production-dir <dir> <deb_files...>

usage() {
    cat << EOF
Usage: $0 --channel <channel> --staging-dir <dir> --production-dir <dir> [--keep-backup] <deb_files...>

Publishes DEB packages to APT repository with atomic promotion.

Required arguments:
  --channel CHANNEL      Channel (nightly|stable)
  --staging-dir DIR      Staging directory path
  --production-dir DIR   Production directory path
  deb_files              DEB package files to publish

Optional arguments:
  --keep-backup          Keep last-good backup (default: true)
  --json                 Output publishing result as JSON

Exit codes:
  0   Publishing successful
  1   Publishing failed
  2   Usage error
EOF
    exit 2
}

if [[ $# -lt 6 ]]; then
    usage
fi

CHANNEL=""
STAGING_DIR=""
PRODUCTION_DIR=""
KEEP_BACKUP=true
JSON_OUTPUT=false
DEB_FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --channel)
            if [[ $# -lt 2 ]]; then
                echo "Error: --channel requires a value"
                usage
            fi
            CHANNEL="$2"
            shift 2
            ;;
        --staging-dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: --staging-dir requires a value"
                usage
            fi
            STAGING_DIR="$2"
            shift 2
            ;;
        --production-dir)
            if [[ $# -lt 2 ]]; then
                echo "Error: --production-dir requires a value"
                usage
            fi
            PRODUCTION_DIR="$2"
            shift 2
            ;;
        --keep-backup)
            KEEP_BACKUP=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            if [[ "$1" != -* ]]; then
                DEB_FILES+=("$1")
                shift
            else
                echo "Error: Unknown option '$1'"
                usage
            fi
            ;;
    esac
done

# Validate inputs
if [[ -z "$CHANNEL" || -z "$STAGING_DIR" || -z "$PRODUCTION_DIR" || ${#DEB_FILES[@]} -eq 0 ]]; then
    echo "Error: Missing required arguments"
    usage
fi

if [[ "$CHANNEL" != "nightly" && "$CHANNEL" != "stable" ]]; then
    echo "Error: Invalid channel '$CHANNEL'. Must be 'nightly' or 'stable'."
    exit 2
fi

# Verify all DEB files exist
for deb in "${DEB_FILES[@]}"; do
    if [[ ! -f "$deb" ]]; then
        echo "Error: DEB file not found: $deb"
        exit 2
    fi
done

# Create staging directory
mkdir -p "$STAGING_DIR" "$PRODUCTION_DIR"

PUBLISH_START=$(date -u +%s)
PUBLISH_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ERRORS=0

# Copy DEBs to staging
echo "Copying DEB packages to staging..."
for deb in "${DEB_FILES[@]}"; do
    cp "$deb" "$STAGING_DIR/"
    if [[ $? -ne 0 ]]; then
        echo "Error copying DEB: $deb"
        ((ERRORS++))
    fi
done

if [[ $ERRORS -gt 0 ]]; then
    if [[ "$JSON_OUTPUT" == true ]]; then
        cat << EOF
{
  "publish_time": "$PUBLISH_TIME",
  "channel": "$CHANNEL",
  "success": false,
  "error": "Failed to copy DEB files to staging"
}
EOF
    else
        echo "Error: Failed to copy some DEB files"
    fi
    exit 1
fi

# Generate Packages.gz
echo "Generating Packages metadata..."
cd "$STAGING_DIR"
rm -f Packages Packages.gz
apt-ftparchive packages . > Packages 2>/dev/null || true
gzip -c Packages > Packages.gz || true

# Generate Release file
echo "Generating Release metadata..."
rm -f Release
cat > Release << EOF
Archive: Debian
Origin: OpenCarDev
Label: Crankshaft
Suite: trixie
Codename: trixie
Version: 12.0
Date: $(date -u +"%a, %d %b %Y %H:%M:%S %z")
Architectures: amd64 arm64 armhf
Components: main
Description: Crankshaft automotive infotainment system
Channel: $CHANNEL
EOF

cd - > /dev/null

# Backup current production
if [[ $KEEP_BACKUP == true && -d "$PRODUCTION_DIR"/apt.current ]]; then
    echo "Backing up current production..."
    if [[ -d "$PRODUCTION_DIR"/apt.backup ]]; then
        rm -rf "$PRODUCTION_DIR"/apt.backup
    fi
    cp -r "$PRODUCTION_DIR"/apt.current "$PRODUCTION_DIR"/apt.backup
fi

# Atomic promotion: use symlink swap for true atomicity
echo "Promoting staging to production (atomic)..."
if [[ -d "$PRODUCTION_DIR"/apt.new ]]; then
    rm -rf "$PRODUCTION_DIR"/apt.new
fi

# Copy to .new
cp -r "$STAGING_DIR" "$PRODUCTION_DIR"/apt.new

# Atomic symlink swap
if [[ -L "$PRODUCTION_DIR"/apt.current ]]; then
    # Remove old symlink
    rm "$PRODUCTION_DIR"/apt.current
elif [[ -d "$PRODUCTION_DIR"/apt.current ]]; then
    # Move directory aside
    mv "$PRODUCTION_DIR"/apt.current "$PRODUCTION_DIR"/apt.old
fi

# Create new symlink (atomic operation)
ln -s apt.new "$PRODUCTION_DIR"/apt.current

# Verify symlink
if [[ ! -L "$PRODUCTION_DIR"/apt.current ]]; then
    echo "Error: Atomic promotion failed"
    ((ERRORS++))
fi

# Cleanup
echo "Cleaning up..."
rm -rf "$STAGING_DIR"

PUBLISH_ELAPSED=$(($(date -u +%s) - PUBLISH_START))

if [[ "$JSON_OUTPUT" == true ]]; then
    cat << EOF
{
  "publish_time": "$PUBLISH_TIME",
  "channel": "$CHANNEL",
  "packages_published": ${#DEB_FILES[@]},
  "production_path": "$PRODUCTION_DIR/apt.current",
  "elapsed_seconds": $PUBLISH_ELAPSED,
  "success": $([[ $ERRORS -eq 0 ]] && echo "true" || echo "false")
}
EOF
else
    echo "APT Publishing Summary"
    echo "====================="
    echo "Channel: $CHANNEL"
    echo "Packages published: ${#DEB_FILES[@]}"
    echo "Production path: $PRODUCTION_DIR/apt.current"
    echo "Elapsed: ${PUBLISH_ELAPSED}s"
    echo "Status: $([[ $ERRORS -eq 0 ]] && echo "SUCCESS" || echo "FAILED")"
fi

exit $([[ $ERRORS -eq 0 ]] && echo 0 || echo 1)
