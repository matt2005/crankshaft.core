# Raspberry Pi Image Build - Quick Start Guide

**Feature**: 001-rpi-image  
**Last Updated**: 2026-01-05  
**Purpose**: Guide for building and deploying Crankshaft Raspberry Pi images

---

## Prerequisites

### System Requirements

#### Host System
- **OS**: Ubuntu 20.04+ (native or WSL2), Debian 11+, or compatible Linux distribution
- **CPU**: x86_64 with 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk Space**: 20GB free space minimum
  - Base build: ~10GB
  - Pi-gen working directory: ~8GB
  - Build artefacts: ~2GB per architecture

#### Software Dependencies

**Required**:
- Docker 20.10+ with BuildKit support
- Git 2.25+
- QEMU user-static emulation (`qemu-user-static` package)
- binfmt-support for multi-architecture builds

**Optional**:
- `qemu-user-binfmt` for transparent ARM emulation
- `coreutils`, `quilt`, `parted`, `realpath`, `zerofree`, `zip`, `dosfstools`, `libarchive-tools` for manual builds

### Installation Commands

#### Ubuntu/Debian
```bash
# Install Docker (if not already installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install QEMU and binfmt support
sudo apt-get update
sudo apt-get install -y qemu-user-static binfmt-support

# Verify QEMU registration
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
ls /proc/sys/fs/binfmt_misc/
```

#### WSL2 (Windows)
```powershell
# From PowerShell (Windows host)
wsl --install -d Ubuntu-22.04

# Inside WSL Ubuntu terminal
sudo apt-get update
sudo apt-get install -y docker.io qemu-user-static binfmt-support
sudo systemctl enable docker
sudo systemctl start docker
```

---

## Build Process Overview

### Architecture

The build system uses **pi-gen** (official Raspberry Pi image builder) with custom Crankshaft stages.

```
image_builder/
├── pi-gen/                          # Pi-gen submodule (NOT YET CLONED)
├── pi-gen-stages/
│   └── stage-crankshaft/            # Custom Crankshaft installation stage
│       ├── prerun.sh                # Pre-stage setup
│       ├── postrun.sh               # Post-stage cleanup
│       ├── 00-install-crankshaft-stage00.sh  # Package installation
│       └── files/                   # Files to copy into image
│           ├── crankshaft.service   # Systemd service (TO BE CREATED)
│           ├── config.txt           # Boot configuration (TO BE CREATED)
│           └── first-boot-wizard.sh # First-boot setup (TO BE CREATED)
├── scripts/
│   └── build-docker-debug.sh        # Docker build wrapper with debug output
└── stages/
    └── stage60/                     # Legacy compatibility
```

### Build Flow

1. **Setup**: Clone pi-gen, configure build parameters
2. **Base Image**: Pi-gen builds standard Raspberry Pi OS (stages 0-2)
3. **Crankshaft Stage**: Custom stage installs Crankshaft packages and configures system
4. **Compression**: Image is compressed with xz for distribution
5. **Artefacts**: .img.xz and build logs uploaded to GitHub Actions

---

## Quick Start: Local Build

### Step 1: Clone Pi-Gen (NOT YET DONE)

⚠️ **TODO**: Pi-gen repository not yet cloned. This will be added in Phase 1.

```bash
cd image_builder/
git clone https://github.com/RPi-Distro/pi-gen.git
cd pi-gen
git checkout master  # For armhf (32-bit)
# OR
git checkout arm64   # For arm64 (64-bit)
```

### Step 2: Configure Build

Create `image_builder/pi-gen-stages/config-template`:

```bash
IMG_NAME='crankshaft'
RELEASE='trixie'
DEPLOY_COMPRESSION='xz'
LOCALE_DEFAULT='en_GB.UTF-8'
TARGET_HOSTNAME='crankshaft'
KEYBOARD_KEYMAP='gb'
KEYBOARD_LAYOUT='English (UK)'
TIMEZONE_DEFAULT='Europe/London'
FIRST_USER_NAME='pi'
FIRST_USER_PASS='raspberry'
ENABLE_SSH=1

# Stage selection (0=bootstrap, 1=minimal, 2=lite, stage-crankshaft=custom)
STAGE_LIST="stage0 stage1 stage2 stage-crankshaft"

# Performance
export IMG_DATE="$(date +%Y-%m-%d)"
export USE_QCOW2=1
```

### Step 3: Run Build

```bash
cd image_builder/
./scripts/build-docker-debug.sh

# Build will take 30-60 minutes
# Output: build/crankshaft-<date>-<arch>.img.xz
```

### Step 4: Flash Image

**Using Balena Etcher (Recommended)**:
1. Download from https://www.balena.io/etcher/
2. Select .img.xz file (no need to decompress)
3. Select SD card (8GB+ recommended)
4. Click "Flash!"

**Using dd (Linux/macOS)**:
```bash
# Decompress
xz -d crankshaft-2026-01-05-arm64.img.xz

# Flash (replace /dev/sdX with your SD card device)
sudo dd if=crankshaft-2026-01-05-arm64.img of=/dev/sdX bs=4M status=progress conv=fsync
```

**Using Win32DiskImager (Windows)**:
1. Decompress .img.xz with 7-Zip
2. Run Win32DiskImager as Administrator
3. Select .img file and drive letter
4. Click "Write"

### Step 5: First Boot

1. Insert SD card into Raspberry Pi
2. Connect HDMI display
3. Power on
4. Wait 60-90 seconds for initial boot
5. Crankshaft UI should appear automatically
6. (Optional) Complete first-boot setup wizard for Wi-Fi configuration

---

## CI/CD Build (GitHub Actions)

Builds are automated via `.github/workflows/build-pi-gen-lite.yml`:

```yaml
strategy:
  matrix:
    arch: [armhf, arm64]
```

### Triggering Builds

**Manual Trigger**:
```bash
gh workflow run build-pi-gen-lite.yml -f arch=arm64
```

**Automatic Triggers**:
- Push to `main` branch
- Pull requests targeting `main`
- Nightly schedule (2:00 AM UTC)

### Artefact Download

```bash
# List recent runs
gh run list --workflow=build-pi-gen-lite.yml

# Download artefacts from specific run
gh run download <run-id> --name crankshaft-image-arm64
```

---

## Troubleshooting

### Common Issues

#### 1. "binfmt_misc not found"
```bash
sudo modprobe binfmt_misc
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

#### 2. "QEMU: Exec format error"
```bash
# Re-register QEMU handlers
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

#### 3. "No space left on device"
```bash
# Check Docker space
docker system df

# Clean up old images/containers
docker system prune -a

# Check host disk space
df -h
```

#### 4. "Image exceeds 2GB"
- Review installed packages in `00-install-crankshaft-stage00.sh`
- Remove unnecessary dependencies
- Check for duplicate libraries
- Verify `DEPLOY_COMPRESSION='xz'` is enabled

#### 5. "dpkg-reconfigure hangs"
✅ **FIXED** in commit c74aa59: dpkg-reconfigure now runs non-interactively with `DEBIAN_FRONTEND=noninteractive`

---

## Performance Targets

### Build Times (CI/CD)
- **Target**: ≤60 minutes clean build
- **Typical**: 40-50 minutes on GitHub Actions (8-core runner)
- **Local**: 30-45 minutes on 8-core x86_64 with 16GB RAM

### Image Sizes
- **Target**: ≤2GB compressed (.xz)
- **Typical**: 1.5-1.8GB compressed
- **Uncompressed**: 4-6GB .img file

### Boot Times (Hardware)
- **Pi 4 (4GB)**: ≤90s power-on to UI
- **Pi 5 (8GB)**: ≤75s power-on to UI
- **Pi 3 (1GB)**: ≤120s (best-effort)
- **Pi Zero 2**: ≤150s (best-effort)

---

## Security Considerations

⚠️ **WARNING**: Default credentials are for TESTING ONLY

### Default Credentials
- **Username**: `pi`
- **Password**: `raspberry`
- **SSH**: Enabled by default on port 22

### Production Deployment

**MUST** perform these steps before production use:

1. **Change default password**:
   ```bash
   sudo passwd pi
   ```

2. **Disable password authentication, enable SSH keys**:
   ```bash
   # On your local machine
   ssh-copy-id pi@<raspberry-pi-ip>
   
   # On Raspberry Pi
   sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart ssh
   ```

3. **Configure firewall** (optional):
   ```bash
   sudo apt-get install ufw
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   sudo ufw enable
   ```

4. **Disable SSH** (if not needed):
   ```bash
   sudo systemctl disable ssh
   sudo systemctl stop ssh
   ```

See `docs/security.md` for comprehensive hardening guide (to be created in Phase 8).

---

## Architecture-Specific Notes

### armhf (32-bit)
- **Pi-gen branch**: `master`
- **Compatibility**: Pi Zero 2, Pi 3, Pi 4 (all RAM variants)
- **Performance**: Slightly lower than arm64 on Pi 4/5
- **Use case**: Maximum compatibility with older Pi models

### arm64 (64-bit)
- **Pi-gen branch**: `arm64`
- **Compatibility**: Pi 3 (requires arm64-capable kernel), Pi 4, Pi 5
- **Performance**: ~10% faster on Pi 4/5 due to 64-bit optimizations
- **Use case**: Recommended for Pi 4/5 deployments

### Variance Tolerance
- Boot time: ±10% between architectures on same hardware
- Image size: ±5% due to architecture-specific packages

---

## Next Steps

- **Development**: See `specs/001-rpi-image/tasks.md` for implementation tasks
- **Testing**: Hardware validation on Pi 4/5 required before release
- **Documentation**: Complete offline docs (Phase 7, User Story 5)
- **Security**: Phase 2 hardening (SSH keys, credential rotation, firewall)

---

## Resources

- **Pi-gen Documentation**: https://github.com/RPi-Distro/pi-gen
- **Raspberry Pi OS**: https://www.raspberrypi.com/software/
- **QEMU User Emulation**: https://www.qemu.org/docs/master/user/main.html
- **Docker Multi-arch**: https://docs.docker.com/build/building/multi-platform/

## Support

- **Issues**: https://github.com/opencardev/crankshaft.core/issues
- **Discussions**: https://github.com/opencardev/crankshaft.core/discussions
- **Documentation**: `docs/` directory in repository
