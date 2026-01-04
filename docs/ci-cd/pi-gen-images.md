# Pi-Gen Bootable Image Distribution

This document describes the automated Pi-gen workflow for building bootable Raspberry Pi images with Crankshaft pre-installed, covering manual triggers, customization, and deployment.

## Overview

The Pi-gen image build system creates bootable Raspberry Pi images based on official Raspberry Pi OS Lite with Crankshaft infotainment system pre-installed. Images are built for both ARM 32-bit (armhf) and ARM 64-bit (arm64) architectures.

## Image Specifications

### What's Included

Each image includes:
- **Raspberry Pi OS Lite** (trixie/bookworm) as base
- **Crankshaft** infotainment system
- **Crankshaft UI** components
- **Extensions framework** for plugin development
- **OpenCarDev APT repository** configured for updates
- **First-boot setup service** for initial configuration
- **SSH enabled** for remote access

### Image Variants

- **armhf** (32-bit): Raspberry Pi 3, 3B+, Raspberry Pi OS 32-bit
- **arm64** (64-bit): Raspberry Pi 4, 5, Raspberry Pi OS 64-bit

### Compression

Images are compressed with **xz** for smaller download sizes:
- Typical size: 800-1500 MB (compressed)
- Decompressed: 2-3 GB (expandable on boot)

## Manual Triggers

### Build Images for Development

```
Actions tab → build-pi-gen-lite → Run workflow
  version: DEV
  release: trixie
  auto_release: false
  attach-to-release: false
```

**Process**:
1. Checkout latest code from current branch
2. Fetch pi-gen repository
3. Build armhf image (ARM 32-bit)
4. Build arm64 image (ARM 64-bit) in parallel
5. Generate checksums and metadata
6. Upload artifacts (4-hour timeout)

**Output**: Artifacts available in Actions tab for 30 days

### Build and Auto-Attach to Release

```
Actions tab → build-pi-gen-lite → Run workflow
  version: v1.2.0
  release: trixie
  auto_release: true
  attach-to-release: true
```

**Process**: Same as above, then:
1. Generate release attachment metadata
2. Download artifacts
3. Compute checksums
4. Create release assets
5. Attach to GitHub release v1.2.0

**Output**: Images available in GitHub release assets

### Automatic Trigger from Release Workflow

When `release.yml` creates a stable release (non-prerelease):
1. Validates version (e.g., v1.2.0)
2. Creates GitHub release with DEBs
3. Publishes to stable APT channel
4. **Automatically triggers** pi-gen build with:
   - `version`: Extracted from release tag
   - `release`: trixie (default)
   - `attach-to-release`: true
   - `auto-release`: false (manual review)

**Process**: Images build automatically and attach to release assets within 4 hours

## Image Customization

### Debian Release Selection

```
Actions tab → build-pi-gen-lite → Run workflow
  release: bookworm (or trixie)
```

Supported Debian releases:
- **trixie** (default, latest)
- **bookworm** (stable, older)

Choose based on:
- **trixie**: Latest packages, features, but slightly less tested
- **bookworm**: Stable, well-tested, slightly older packages

### Custom Build Configuration

To modify image contents, edit `image_builder/pi-gen-stages/stage-crankshaft/`:

**APT Repository**: 
```bash
# In 00-install-crankshaft-stage00.sh
run_root bash -c 'echo "deb [arch=...] https://apt.opencardev.com/stable jammy main" > /etc/apt/sources.list.d/crankshaft.sources'
```

**Packages to Install**:
```bash
# In 00-install-crankshaft-stage00.sh
run_root bash -c 'apt-get install -y package1 package2 package3'
```

**First-Boot Scripts**:
```bash
# In 00-install-crankshaft-stage00.sh (FIRSTBOOTSCRIPT section)
# Add custom setup commands
```

**Service Configuration**:
```bash
# Enable/disable services
run_root bash -c 'systemctl enable service-name'
```

## Build Artifacts

### Generated Files

For each architecture (armhf, arm64):
- `crankshaft-<version>-<arch>-<date>.img.xz` - Compressed image
- `crankshaft-<version>-<arch>-<date>.img.xz.md5` - MD5 checksum
- `crankshaft-<version>-<arch>-<date>.img.xz.sha256` - SHA256 checksum
- `image-metadata.json` - Build metadata
- `SHA256SUMS` - All checksums in file

### Metadata JSON

Each build includes `image-metadata.json`:
```json
{
  "architecture": "arm64",
  "image_name": "crankshaft-1.2.0-2025-01-04-arm64-trixie-a1b2c3d.img.xz",
  "image_size_bytes": 1234567890,
  "image_size_human": "1.2G",
  "build_date": "2025-01-04",
  "version": "1.2.0",
  "debian_release": "trixie",
  "pi_gen_branch": "arm64",
  "git_commit": "a1b2c3d",
  "compression": "xz",
  "stages_included": ["stage0", "stage1", "stage2", "stage-crankshaft"],
  "build_run_id": "1234567890"
}
```

## Flashing Images

### Prerequisites

- **Raspberry Pi** (3, 3B+, 4, or 5)
- **MicroSD card** (16GB+ recommended)
- **Card reader/writer**
- **Flashing tool**: Raspberry Pi Imager, balena Etcher, or `dd`

### Using Raspberry Pi Imager (Recommended)

1. Launch Raspberry Pi Imager
2. **Operating System** → **Custom** → Select `.img.xz` file
3. **Storage** → Select SD card
4. **Next** → Configure options if desired
5. **Write** → Wait for completion (10-15 minutes)

### Using balena Etcher

1. Launch balena Etcher
2. **Flash from file** → Select `.img.xz` file
3. **Select target** → Choose SD card
4. **Flash** → Wait for completion

### Using `dd` (Linux/Mac)

```bash
# Identify SD card device
lsblk  # Linux
diskutil list  # Mac

# Decompress and flash (example /dev/sdb)
xz -d crankshaft-1.2.0-2025-01-04-arm64-trixie-a1b2c3d.img.xz
sudo dd if=crankshaft-1.2.0-2025-01-04-arm64-trixie-a1b2c3d.img of=/dev/sdb bs=4M status=progress
sudo sync
```

### Verify Checksum

Before flashing, verify image integrity:

```bash
# Download SHA256SUMS from release assets
sha256sum -c SHA256SUMS

# Or manually
sha256sum crankshaft-1.2.0-2025-01-04-arm64-trixie-a1b2c3d.img.xz
# Compare with SHA256SUMS file
```

## First Boot

After flashing and booting Raspberry Pi:

1. **Wait for first-boot setup** (2-3 minutes)
   - Filesystem automatically expanded
   - Locale and timezone configured
   - Crankshaft services started

2. **Access via SSH** (if required):
   ```bash
   ssh pi@raspberrypi.local
   # Password: raspberry (default, change immediately)
   ```

3. **Crankshaft is running** on HDMI output (if display connected)
   - Default resolution: 1024x600
   - QT6-based UI
   - WebSocket event bus active

4. **Update packages** (recommended):
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

## Troubleshooting

### Build Timeout

**Issue**: Build exceeds 4-hour timeout

**Solutions**:
1. Reduce image size (remove packages)
2. Build on faster hardware
3. Increase timeout in workflow (edit build-pi-gen-lite.yml)
4. Check build logs for specific bottlenecks

### Image Won't Boot

**Issue**: SD card boots to blank screen or loops

**Solutions**:
1. Verify checksum matches SHA256SUMS
2. Re-flash using different tool
3. Try with fresh SD card
4. Check Raspberry Pi power supply (≥3A)
5. Connect display before power-on

### Crankshaft Not Running

**Issue**: Crankshaft UI doesn't appear on display

**Solutions**:
1. Wait 3-5 minutes for first-boot setup
2. SSH in and check service status:
   ```bash
   systemctl status crankshaft
   journalctl -u crankshaft -n 50
   ```
3. Verify display connection and resolution
4. Check APT repository is reachable:
   ```bash
   apt update
   ```

### APT Repository Not Found

**Issue**: Package installation fails, APT repo errors

**Solutions**:
1. Verify internet connection: `ping apt.opencardev.com`
2. Check configured repository:
   ```bash
   cat /etc/apt/sources.list.d/crankshaft.sources
   ```
3. Update package lists:
   ```bash
   sudo apt update
   ```
4. Manually add repository if missing:
   ```bash
   echo "deb [arch=arm64] https://apt.opencardev.com/stable jammy main" | sudo tee /etc/apt/sources.list.d/crankshaft.sources
   sudo apt update
   ```

## Advanced Topics

### Building Custom Stages

To add custom software/configuration:

1. Create `image_builder/pi-gen-stages/stage-custom/` directory
2. Add scripts:
   - `prerun.sh` - Setup before installation
   - `00-install-packages.sh` - Main installation
   - `postrun.sh` - Cleanup after installation
3. Update workflow config `STAGE_LIST="stage0 stage1 stage2 stage-crankshaft stage-custom"`
4. Rebuild images

### Cross-Compilation for Unsupported Architectures

Current support: armhf (32-bit), arm64 (64-bit)

To add arm64-only (aarch64):
1. Modify `build-pi-gen-lite.yml` matrix
2. Add pi-gen branch configuration
3. Test on hardware before release

### Docker Build Troubleshooting

Build uses Docker containers for isolation:

```bash
# Check docker environment
docker version
docker info

# View build logs
docker logs <container-id>

# Manual build (for debugging)
cd pi-gen
./build-docker.sh
```

## Security Considerations

- **Default password** (`raspberry`) must be changed immediately
- **SSH key-based auth** recommended for remote access
- **Regular updates** via APT repository
- **SBOM tracking** for vulnerability management
- **Images are not signed** - verify checksums after download

## Performance Optimization

### Parallel Architecture Builds

Both armhf and arm64 images build simultaneously:
- Reduces total build time by ~2 hours
- Requires sufficient disk space (~20GB)
- Both images attached to same release

### Compression Optimization

Images use xz compression level 9:
- Maximum compression ratio
- Slightly slower decompression (acceptable for one-time operation)
- Typical decompression: 10-15 minutes on Raspberry Pi 4

### Image Size Reduction

To reduce image size:
1. Remove unnecessary packages in stage-crankshaft
2. Use bookworm instead of trixie (slightly older, smaller)
3. Disable unused features in Crankshaft config
4. Clean apt cache and logs

## Additional Resources

- [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/)
- [Pi-Gen Repository](https://github.com/RPi-Distro/pi-gen)
- [Crankshaft Documentation](../README.md)
- [Build Logs](../LOGS.md)
- [Release Process](./release-process.md)
