# Quickstart Guide: Slim AndroidAuto UI

**Feature**: Slim AndroidAuto UI  
**Target Audience**: Developers and early testers  
**Last Updated**: 2026-01-10

## Overview

The Slim AndroidAuto UI is a lightweight infotainment application providing AndroidAuto projection and minimal settings. This guide helps you build, install, and run the application.

---

## Prerequisites

### Hardware
- Raspberry Pi 4 (2GB+ RAM recommended)
- MicroSD card (16GB+, Class 10)
- Display (touchscreen recommended)
- USB cable or wireless network for AndroidAuto connection
- AndroidAuto-compatible Android device

### Software
- Raspberry Pi OS (Bookworm or later)
- Qt6 (Base, QML, Quick, Multimedia)
- AASDK library
- CMake 3.20+
- GCC 11+ or Clang 13+

---

## Installation

### Option 1: Install from Package (Recommended)

```bash
# Add OpenCarDev APT repository
curl -fsSL https://packages.opencardev.org/opencardev-apt.asc | sudo gpg --dearmor -o /usr/share/keyrings/opencardev-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/opencardev-archive-keyring.gpg] https://packages.opencardev.org/debian trixie nightly" | sudo tee /etc/apt/sources.list.d/opencardev.list

# Update package lists
sudo apt update

# Install slim UI package
sudo apt install crankshaft-slim-ui
```

### Option 2: Build from Source

#### Step 1: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Qt6
sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev

# Install AASDK (if not already installed)
sudo apt install libaasdk-dev

# Install build tools
sudo apt install cmake ninja-build git

# Install additional dependencies
sudo apt install libboost-all-dev libssl-dev libprotobuf-dev protobuf-compiler
```

#### Step 2: Clone Repository

```bash
git clone https://github.com/opencardev/crankshaft.core.git
cd crankshaft.core
git checkout 001-slim-aa-ui
```

#### Step 3: Build

```bash
# Create build directory
mkdir build && cd build

# Configure with CMake
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SLIM_UI=ON ..

# Build slim UI only
ninja crankshaft-slim-ui

# Or build everything
ninja
```

#### Step 4: Install

```bash
# Install to system (requires sudo)
sudo ninja install

# Or create DEB package
cpack -G DEB
sudo dpkg -i crankshaft-slim-ui_*.deb
```

---

## Configuration

### USB AndroidAuto Setup

#### Add udev Rules (Required for USB)

Create `/etc/udev/rules.d/51-android.rules`:

```bash
sudo nano /etc/udev/rules.d/51-android.rules
```

Add:
```
# Google/Android devices
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="plugdev"
```

Reload udev rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Wireless AndroidAuto Setup (Optional)

```bash
# Ensure Wi-Fi is enabled
sudo rfkill unblock wifi

# Configure network (automatic in most cases)
# Phone and Pi must be on same network
```

### Display Configuration

#### For Physical Display (EGLFS)
No configuration needed - EGLFS is the default.

#### For VNC Remote Access
```bash
# Run with VNC backend
crankshaft-slim-ui -platform vnc:size=1024x600,port=5900

# Connect with VNC client to: <raspberry-pi-ip>:5900
```

---

## Running the Application

### Manual Launch

```bash
# Standard launch (EGLFS on physical display)
crankshaft-slim-ui

# Launch with VNC for remote access
crankshaft-slim-ui -platform vnc:size=1024x600,port=5900

# Launch with debug output
QT_LOGGING_RULES="*.debug=true" crankshaft-slim-ui
```

### Systemd Service (Auto-start on Boot)

Create `/etc/systemd/system/crankshaft-slim-ui.service`:

```ini
[Unit]
Description=Crankshaft Slim AndroidAuto UI
After=graphical.target

[Service]
Type=simple
User=pi
Environment="QT_QPA_PLATFORM=eglfs"
Environment="QT_QPA_EGLFS_ALWAYS_SET_MODE=1"
ExecStart=/usr/bin/crankshaft-slim-ui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable crankshaft-slim-ui
sudo systemctl start crankshaft-slim-ui
```

Check status:
```bash
sudo systemctl status crankshaft-slim-ui
```

View logs:
```bash
sudo journalctl -u crankshaft-slim-ui -f
```

---

## First-Time Usage

### Connecting AndroidAuto Device

1. **Enable AndroidAuto on Phone**
   - Install AndroidAuto app from Google Play Store
   - Enable Developer Mode on phone
   - Enable USB debugging (for initial setup)

2. **USB Connection**
   - Connect phone to Raspberry Pi USB port
   - Phone should prompt to allow AndroidAuto
   - Slim UI should detect device and connect automatically

3. **Wireless Connection**
   - Connect phone and Pi to same Wi-Fi network
   - USB connection required for initial wireless pairing
   - After pairing, wireless connection available

4. **Multiple Devices**
   - If multiple AndroidAuto devices connected, selection dialog appears
   - Choose device to connect
   - Last connected device prioritized in future sessions

### Accessing Settings

1. Tap the settings icon in the corner of the screen
2. Adjust brightness, volume, connection preferences
3. Changes save automatically
4. Tap back/close to return to AndroidAuto view

---

## Troubleshooting

### AndroidAuto Not Connecting

**Symptom**: Stuck on "Searching for devices"

**Solutions**:
1. Check USB cable quality (use high-quality USB 2.0/3.0 cable)
2. Verify udev rules installed correctly
3. Check phone has AndroidAuto enabled
4. Try different USB port on Raspberry Pi
5. Check logs: `journalctl -u crankshaft-slim-ui -f`

**Error Dialog Handling**: If the connection fails, an error dialog will appear with:
- **Connection Failed**: Check USB connection and try again
- **Device Not Recognized**: Phone may not support AndroidAuto
- **Authentication Failed**: Verify phone authorization settings
- **Retry Button**: Available for transient failures (USB glitches, timing issues)
- **OK Button**: Dismisses error, returns to device search screen

### Black Screen on Launch

**Symptom**: Application starts but display is black

**Solutions**:
1. Verify Qt6 installed correctly: `dpkg -l | grep qt6`
2. Check display backend: `ls /sys/class/graphics/`
3. Try VNC mode to isolate display issue
4. Check GPU memory allocation: `vcgencmd get_mem gpu` (should be 256+)

### Touch Input Not Working

**Symptom**: Cannot interact with projected AndroidAuto interface

**Solutions**:
1. Verify touchscreen detected: `xinput list` or `evtest`
2. Check Qt recognizing touch device
3. Test with mouse input first
4. Review touch calibration

### Audio Not Working

**Symptom**: No audio output from AndroidAuto

**Solutions**:
1. Check audio device: `aplay -l`
2. Test audio playback: `speaker-test -c2`
3. Verify PulseAudio/ALSA configuration
4. Check audio routing in settings
5. Verify phone sending audio (test with another app)

**Note**: The Slim UI includes graceful audio degradation (FR-025). If the audio backend (PulseAudio/ALSA) is unavailable at startup:
- An error dialog will appear: "Audio backend unavailable. Video projection will continue without audio."
- Video projection continues normally
- Audio functionality automatically recovers when the backend becomes available

### High Memory Usage

**Symptom**: System becomes sluggish, OOM errors

**Solutions**:
1. Check memory: `free -h`
2. Increase GPU memory split: Edit `/boot/config.txt`, add `gpu_mem=256`
3. Reduce resolution if using high-res display
4. Ensure no other memory-intensive apps running

### Settings Not Persisting

**Symptom**: Settings reset on each launch

**Solutions**:
1. Check config directory exists: `ls ~/.config/crankshaft/`
2. Verify write permissions: `touch ~/.config/crankshaft/test.txt`
3. Check logs for save errors
4. Manually create directory: `mkdir -p ~/.config/crankshaft/`

---

## Configuration Files

### Settings Location
- Path: `~/.config/crankshaft/slim-ui-settings.json`
- Format: JSON
- Editable: Yes (application must be stopped)

### Example Settings File
```json
{
  "version": "1.0.0",
  "display": {
    "brightness": 75
  },
  "audio": {
    "volume": 60
  },
  "connection": {
    "preference": "USB",
    "last_device_id": "device:12:34:56:78:90:ab"
  },
  "theme": {
    "mode": "DARK"
  }
}
```

### Factory Reset
```bash
# Remove settings file
rm ~/.config/crankshaft/slim-ui-settings.json

# Restart application
# Settings will reset to defaults
```

---

## Performance Tuning

### Raspberry Pi 4 Optimization

Edit `/boot/config.txt`:
```ini
# Increase GPU memory
gpu_mem=256

# Enable hardware acceleration
dtoverlay=vc4-kms-v3d

# Disable screen blanking
consoleblank=0

# Overclock (optional, voids warranty)
over_voltage=2
arm_freq=1750
```

Reboot after changes:
```bash
sudo reboot
```

---

## Getting Help

### Community Support
- GitHub Issues: https://github.com/opencardev/crankshaft.core/issues
- Discord: https://discord.gg/opencardev
- Forum: https://forum.opencardev.org

### Reporting Bugs

Include:
1. Raspberry Pi model and OS version
2. Application version: `crankshaft-slim-ui --version`
3. Phone model and Android version
4. Connection type (USB/wireless)
5. Logs: `journalctl -u crankshaft-slim-ui --since "10 minutes ago"`

### Feature Requests
- Submit via GitHub Issues with [Feature Request] tag
- Describe use case and expected behavior

---

## Development

### Building for Development

```bash
# Debug build with symbols
cmake -GNinja -DCMAKE_BUILD_TYPE=Debug -DBUILD_SLIM_UI=ON ..
ninja crankshaft-slim-ui

# Run from build directory
./ui-slim/crankshaft-slim-ui
```

### Running Tests

```bash
# Run all tests
ctest --output-on-failure

# Run slim UI tests only
ctest -R slim-ui --output-on-failure
```

### Code Formatting

```bash
# Format C++ code
./scripts/format_cpp.sh fix

# Check formatting
./scripts/format_cpp.sh check
```

### Error Handling Integration

The Slim UI includes a centralized error handling system for developers extending the application:

**C++ Backend** (`ui-slim/src/ErrorHandler.h/cpp`):
```cpp
// Report an error with automatic user notification
_errorHandler->reportError(
    ErrorHandler::ErrorCode::ConnectionFailed,
    ErrorHandler::Severity::Error,
    "Could not establish connection"
);

// Check if an error code supports retry
if (_errorHandler->isRetryable(ErrorHandler::ErrorCode::ConnectionFailed)) {
    // Show retry button in error dialog
}
```

**QML Frontend** (`ui-slim/qml/ErrorDialog.qml`):
```qml
// Error dialog is automatically shown via signal connection
Connections {
    target: _errorHandler
    function onErrorOccurred(code, severity, message) {
        errorDialog.showError(code, severity, message);
    }
}

// Manual error display (if needed)
errorDialog.showError(
    ErrorHandler.ErrorCode.SettingsLoadFailed,
    ErrorHandler.Severity.Warning,
    "Could not load saved settings"
);
```

**Available Error Codes**:
- `ConnectionFailed`: AndroidAuto connection error (retryable)
- `DeviceNotFound`: No compatible devices detected
- `AuthenticationFailed`: Phone authorization failed
- `AudioBackendUnavailable`: Audio system unavailable (non-fatal)
- `SettingsLoadFailed`: Settings corruption (retryable with factory reset)
- `SettingsSaveFailed`: Cannot persist settings
- `InvalidConfiguration`: Configuration error
- `InternalError`: Unexpected application error

**Severity Levels**:
- `Info`: Informational notification (blue icon)
- `Warning`: Non-critical issue (yellow icon)
- `Error`: Recoverable error (orange icon)
- `Critical`: Fatal error requiring user action (red icon)

---

## What's Next

After getting the slim UI running:
1. Explore settings customization
2. Test different display resolutions
3. Try wireless AndroidAuto (if supported)
4. Report any issues or feedback
5. Contribute improvements!

For the complete feature specification and implementation details, see:
- [Feature Specification](spec.md)
- [Implementation Plan](plan.md)
