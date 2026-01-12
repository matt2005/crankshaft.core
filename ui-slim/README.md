# Crankshaft Slim AndroidAuto UI

A lightweight, responsive user interface for Crankshaft automotive infotainment system, providing AndroidAuto connectivity and basic settings management on Raspberry Pi 4.

## Features

✅ **AndroidAuto Integration**
- Automatic device discovery and connection
- Full-screen video projection with touch input
- Audio streaming via ALSA/PulseAudio
- Graceful audio failure handling
- Automatic reconnection with exponential backoff

✅ **Settings Management**
- Display brightness control (0-100%)
- Audio volume adjustment (0-100%)
- Connection preference (USB/Wireless)
- Light/dark theme support
- Persistent settings with corruption recovery

✅ **Responsive Design**
- Supports multiple resolutions (800x480 default, 1024x600, 1280x720, 1920x1080)
- Touch-optimised controls (44pt minimum touch targets)
- Follows "Design for Driving" guidelines

✅ **Error Handling & Recovery**
- Centralised error management with user-friendly messages
- Severity levels (Info, Warning, Error, Critical)
- Automatic retry for recoverable errors
- Comprehensive logging with context

✅ **Platform Support**
- Raspberry Pi 4 (32-bit and 64-bit, Trixie)
- EGLFS backend (physical display)
- VNC backend (remote access)
- <150MB memory footprint during projection

## Quick Start

### Prerequisites

- CMake 3.16+
- Qt 6.2+
- Crankshaft core library
- Raspberry Pi OS Trixie (or compatible Linux distro)

### Building

```bash
# Clone the repository
git clone https://github.com/opencardev/crankshaft-mvp.git
cd crankshaft-mvp

# Configure with slim UI enabled
cmake -S . -B build -DENABLE_SLIM_UI=ON

# Build
cmake --build build -j$(nproc)

# Run tests
ctest --test-dir build --output-on-failure

# Run application (desktop testing via VNC)
./build/ui-slim/crankshaft-slim-ui -platform vnc:port=5900
```

### Installing on Raspberry Pi

```bash
# Build release package
cmake --build build --target package

# Install DEB package
sudo dpkg -i build/crankshaft-slim-ui_*.deb

# Start service
sudo systemctl start crankshaft-slim-ui

# View logs
journalctl -u crankshaft-slim-ui -f
```

## Architecture

The slim UI uses a **facade pattern** for clean separation between QML frontend and Crankshaft core services:

```
QML Frontend
    ↓ (Qt QML)
C++ Facades (Thin Wrappers)
    ├─ AndroidAutoFacade → core::AndroidAutoService
    ├─ PreferencesFacade → core::PreferencesService
    ├─ AudioBridge → core::AudioRouter
    ├─ ErrorHandler → Centralized error management
    └─ ViewNavigationController → View state transitions
    ↓ (Delegates to)
Crankshaft Core Services
    ├─ AndroidAutoService (AASDK integration)
    ├─ PreferencesService (SQLite settings)
    ├─ EventBus (Pub/sub events)
    └─ AudioRouter (Backend management)
```

## Project Structure

```
ui-slim/
├── src/                    # C++ facade implementations
│   ├── main.cpp           # Application entry point
│   ├── ServiceProvider.h/cpp
│   ├── Logger.h/cpp
│   ├── AndroidAutoFacade.h/cpp
│   ├── PreferencesFacade.h/cpp
│   ├── AudioBridge.h/cpp
│   ├── ErrorHandler.h/cpp
│   └── ...
├── qml/                   # QML user interface
│   ├── main.qml
│   ├── ApplicationController.qml
│   ├── ViewNavigationController.qml
│   ├── Theme.qml
│   ├── AAProjectionView.qml
│   ├── SettingsPanel.qml
│   ├── ErrorDialog.qml
│   └── ...
├── translations/          # i18n support
│   └── slim-ui_en_GB.ts
├── tests/                # Unit and integration tests
│   └── CMakeLists.txt
├── resources/            # Icons, stylesheets, media
├── CMakeLists.txt       # Build configuration
├── CONTRIBUTING.md      # Contributing guidelines
└── README.md           # This file
```

## Documentation

- **[Specification](../specs/001-slim-aa-ui/spec.md)** - Complete feature requirements
- **[Implementation Plan](../specs/001-slim-aa-ui/plan.md)** - Architecture and design
- **[Tasks](../specs/001-slim-aa-ui/tasks.md)** - Detailed task breakdown (90 tasks)
- **[Data Model](../specs/001-slim-aa-ui/data-model.md)** - Entity definitions
- **[API Contracts](../specs/001-slim-aa-ui/contracts/)** - Interface specifications
- **[Contributing](CONTRIBUTING.md)** - Development guidelines

## Testing

```bash
# Run all tests
ctest --test-dir build --output-on-failure

# Run specific test
ctest --test-dir build -R test_android_auto_facade --output-on-failure

# Generate coverage report
cmake --build build --target coverage

# Test on Raspberry Pi with EGLFS
./build/ui-slim/crankshaft-slim-ui

# Test via VNC (remote access)
./build/ui-slim/crankshaft-slim-ui -platform vnc:port=5900
```

## Code Quality

```bash
# Format code
./scripts/format_cpp.sh fix

# Check formatting
./scripts/format_cpp.sh check

# Static analysis
./scripts/lint_cpp.sh clang-tidy
./scripts/lint_cpp.sh cppcheck

# Check license headers
./scripts/check_license_headers.sh
```

## Success Criteria

- ✅ Connect to AndroidAuto within 5 seconds
- ✅ Stable 2+ hour projection sessions
- ✅ 100% settings persistence
- ✅ <150MB memory during projection (30% reduction)
- ✅ <100ms touch input latency
- ✅ Runs on Pi 4 (32-bit and 64-bit, Trixie)
- ✅ Settings accessible within 1 second
- ✅ Disconnection detected within 2 seconds

## Known Limitations

- **Not in MVP**: View switching while AA connected (deferred to Phase 2+ of future release)
- **Not in MVP**: Advanced extensibility features
- **Audio**: Gracefully degraded if both ALSA and PulseAudio unavailable (silent mode with logging)

## Troubleshooting

### Application won't start

```bash
# Enable debug logging
QT_DEBUG_PLUGINS=1 SLIM_UI_DEBUG=1 ./build/ui-slim/crankshaft-slim-ui

# Check service logs
journalctl -u crankshaft-slim-ui -e
```

### No audio output

- Verify ALSA/PulseAudio is configured: `pactl list short sinks`
- Check audio routing: `amixer scontrols`
- Enable debug logging: `SLIM_UI_DEBUG=1`

### Settings not persisting

- Verify Crankshaft core library is initialised
- Check SQLite database: `sqlite3 ~/.local/share/crankshaft/preferences.db`
- Review core service logs

### VNC connection issues

- Verify port 5900 is not in use: `netstat -tuln | grep 5900`
- Try different port: `./build/ui-slim/crankshaft-slim-ui -platform vnc:port=5901`
- Check VNC client compatibility

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Coding standards and style guidelines
- Branch naming conventions
- Commit message format
- Pull request checklist
- Testing requirements

## License

Licensed under the GNU General Public License v3.0 or later. See LICENSE file for details.

All code must include appropriate license headers. See project guidelines for templates.

## Support

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check [specs/001-slim-aa-ui/](../specs/001-slim-aa-ui/)
- **Task Tracking**: See [tasks.md](../specs/001-slim-aa-ui/tasks.md) for implementation progress

## Roadmap

**Phase 1-4 (MVP)**: Core features (connection, settings, themes)  
**Phase 5-6 (Release)**: Testing, validation, deployment  
**Phase 2+ (Future)**: View switching, advanced extensibility, wireless features

---

**Status**: 🔨 Under Development (Phase 1)  
**Target Release**: Q1 2025  
**Build Command**: `cmake -S . -B build -DENABLE_SLIM_UI=ON && cmake --build build`
