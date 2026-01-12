# Quick Commands Reference - Crankshaft Slim UI

**Last Updated**: 2026-01-12

---

## Build Commands

### Standard Debug Build
```bash
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_SLIM_UI=ON ..
make -j$(nproc)
```

### Standard Release Build
```bash
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SLIM_UI=ON ..
make -j$(nproc)
```

### Clean Build
```bash
rm -rf build
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_SLIM_UI=ON ..
make -j$(nproc)
```

---

## Testing Commands

### Run All Tests
```bash
cd build
ctest --output-on-failure
```

### Run Specific Test Suite
```bash
cd build
ctest -R test_audio_failure_scenarios --output-on-failure
```

### Run Tests with Verbose Output
```bash
cd build
ctest --verbose
```

---

## Code Quality Commands

### Format C++ Code
```bash
./scripts/format_cpp.sh fix
```

### Check Formatting
```bash
./scripts/format_cpp.sh check
```

### Lint C++ Code (clang-tidy)
```bash
./scripts/lint_cpp.sh clang-tidy
```

### Check C++ Code (cppcheck)
```bash
./scripts/lint_cpp.sh cppcheck
```

### Generate Coverage Report
```bash
./scripts/generate-coverage.sh
# Opens coverage-report/index.html when complete
```

---

## Packaging Commands

### Build DEB Package
```bash
# Ensure Release build exists first
./scripts/build-deb-slim-ui.sh
# Output: packages/crankshaft-slim-ui_${VERSION}_${ARCH}.deb
```

### Install DEB Package
```bash
sudo apt install ./packages/crankshaft-slim-ui_*.deb
# Or:
sudo dpkg -i ./packages/crankshaft-slim-ui_*.deb
sudo apt-get install -f  # Fix dependencies
```

### Uninstall Package
```bash
sudo apt remove crankshaft-slim-ui
```

### Purge Package (Remove configs)
```bash
sudo apt purge crankshaft-slim-ui
```

---

## Service Management

### Start Service
```bash
sudo systemctl start crankshaft-slim-ui
```

### Stop Service
```bash
sudo systemctl stop crankshaft-slim-ui
```

### Restart Service
```bash
sudo systemctl restart crankshaft-slim-ui
```

### Check Service Status
```bash
sudo systemctl status crankshaft-slim-ui
```

### Enable Service (Auto-start on Boot)
```bash
sudo systemctl enable crankshaft-slim-ui
```

### Disable Service
```bash
sudo systemctl disable crankshaft-slim-ui
```

### View Service Logs
```bash
# Follow logs in real-time
sudo journalctl -u crankshaft-slim-ui -f

# Last 100 lines
sudo journalctl -u crankshaft-slim-ui -n 100

# Since 10 minutes ago
sudo journalctl -u crankshaft-slim-ui --since "10 minutes ago"
```

---

## Development Commands

### Run Slim UI Directly (Debug)
```bash
./build/ui-slim/crankshaft-slim-ui
```

### Run with VNC Backend
```bash
./build/ui-slim/crankshaft-slim-ui -platform vnc:size=1024x600,port=5900
```

### Run with Debug Logging
```bash
QT_DEBUG_PLUGINS=1 QT_LOGGING_RULES='*=true' ./build/ui-slim/crankshaft-slim-ui
```

### Run with Slim UI Debug Mode
```bash
SLIM_UI_DEBUG=1 ./build/ui-slim/crankshaft-slim-ui
```

---

## Troubleshooting Commands

### Check Dependencies
```bash
ldd build/ui-slim/crankshaft-slim-ui
```

### Check Qt Version
```bash
qmake -query
```

### Check AASDK Installation
```bash
pkg-config --modversion aasdk
```

### Check Audio Backend
```bash
# PulseAudio
pactl info

# ALSA
aplay -l
```

### Check Display Backend
```bash
# List graphics devices
ls /sys/class/graphics/

# Check GPU memory (Raspberry Pi)
vcgencmd get_mem gpu
```

### Check User Groups
```bash
groups crankshaft
# Should include: video audio input render plugdev
```

### Check File Permissions
```bash
ls -lR /var/lib/crankshaft/
ls -lR /var/log/crankshaft/
```

---

## Documentation Commands

### Generate Doxygen Documentation
```bash
doxygen Doxyfile
# Output: docs/html/index.html
```

### View Coverage Report
```bash
cd coverage-report
python3 -m http.server 8080
# Open: http://localhost:8080
```

---

## Git Workflow

### Create Feature Branch
```bash
git checkout -b feature/my-feature
```

### Commit Changes
```bash
git add .
git commit -m "feat: Add feature description"
```

### Push Branch
```bash
git push origin feature/my-feature
```

### Update from Main
```bash
git fetch origin
git rebase origin/main
```

---

## File Locations

### Executables
```
build/ui-slim/crankshaft-slim-ui       # Debug executable
/usr/bin/crankshaft-slim-ui            # Installed executable
```

### Configuration
```
~/.config/crankshaft/slim-ui-settings.json   # User settings
/etc/crankshaft/                             # System config
```

### Logs
```
/var/log/crankshaft/slim-ui.log        # Application logs
sudo journalctl -u crankshaft-slim-ui  # Systemd logs
```

### Data
```
/var/lib/crankshaft/slim-ui/           # Application data
/var/cache/crankshaft/                 # QML cache
```

### Service
```
/usr/lib/systemd/system/crankshaft-slim-ui.service
```

### Documentation
```
/usr/share/doc/crankshaft-slim-ui/README.md
/usr/share/doc/crankshaft-slim-ui/quickstart.md
/usr/share/doc/crankshaft-slim-ui/LICENSE
```

---

## Quick Fixes

### Build Fails with Missing Qt6
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev
```

### Build Fails with Missing AASDK
```bash
# Check if AASDK is installed
pkg-config --modversion aasdk

# If not, install from packages or build from source
sudo apt install libaasdk-dev
```

### Service Fails to Start
```bash
# Check service status
sudo systemctl status crankshaft-slim-ui

# Check logs
sudo journalctl -u crankshaft-slim-ui -n 50

# Check user exists
id crankshaft

# Check permissions
sudo ls -l /usr/bin/crankshaft-slim-ui
```

### Audio Not Working
```bash
# Check audio devices
aplay -l

# Check PulseAudio
pactl info

# Test audio
speaker-test -c2

# Check service audio access
sudo usermod -a -G audio crankshaft
```

### Display Not Working
```bash
# Check graphics
ls /sys/class/graphics/

# Check GPU memory (Raspberry Pi)
vcgencmd get_mem gpu
# Should be 256+

# Try VNC backend
./build/ui-slim/crankshaft-slim-ui -platform vnc:size=1024x600,port=5900
```

---

## Performance Profiling

### Memory Usage
```bash
# While running
ps aux | grep crankshaft-slim-ui

# Detailed memory map
pmap $(pgrep crankshaft-slim-ui)

# Valgrind (memory leaks)
valgrind --leak-check=full ./build/ui-slim/crankshaft-slim-ui
```

### CPU Usage
```bash
# Real-time monitoring
top -p $(pgrep crankshaft-slim-ui)

# Detailed profiling
perf record -g ./build/ui-slim/crankshaft-slim-ui
perf report
```

---

## Useful Aliases

Add to `~/.bashrc`:
```bash
# Crankshaft Slim UI aliases
alias cs-build='cd ~/crankshaft-mvp && ./scripts/build.sh --build-type Debug'
alias cs-test='cd ~/crankshaft-mvp/build && ctest --output-on-failure'
alias cs-run='cd ~/crankshaft-mvp && ./build/ui-slim/crankshaft-slim-ui'
alias cs-log='sudo journalctl -u crankshaft-slim-ui -f'
alias cs-status='sudo systemctl status crankshaft-slim-ui'
alias cs-restart='sudo systemctl restart crankshaft-slim-ui'
```

---

## Environment Variables

### Debug Logging
```bash
export SLIM_UI_DEBUG=1
export QT_DEBUG_PLUGINS=1
export QT_LOGGING_RULES='*=true'
```

### Display Backend
```bash
export QT_QPA_PLATFORM=eglfs         # Physical display
export QT_QPA_PLATFORM=vnc           # VNC backend
export QT_QPA_PLATFORM=xcb           # X11 (development)
```

### QML Development
```bash
export QML_DISABLE_DISK_CACHE=1      # Disable QML cache
export QT_QUICK_CONTROLS_STYLE=Basic # Force Basic style
```

---

For more information, see:
- [Quickstart Guide](../specs/001-slim-aa-ui/quickstart.md)
- [README](../ui-slim/README.md)
- [Code Review Checklist](CODE_REVIEW_CHECKLIST.md)
