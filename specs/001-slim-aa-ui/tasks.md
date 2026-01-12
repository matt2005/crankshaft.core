# Tasks: Slim AndroidAuto UI Implementation

**Feature**: Slim AndroidAuto UI  
**Branch**: `001-slim-aa-ui`  
**Created**: 2026-01-10  
**Specification**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Overview

Implementation tasks for a lightweight, standalone AndroidAuto-focused UI on Raspberry Pi 4. The slim UI leverages existing Crankshaft core services (AndroidAutoService, PreferencesService, EventBus, AudioRouter, Logger) via thin C++ facade classes, significantly reducing implementation scope to ~500-800 LOC C++ + ~500 LOC QML.

**MVP Scope**: User Stories 1 (Connect to AndroidAuto) and 2 (Settings) complete. User Story 3 (View switching) deferred to Phase 2 if needed.

---

## Phase 1: Setup & Project Initialization

### 1.1 Repository & Build Configuration

- [X] T001 Create ui-slim directory structure in crankshaft-mvp/ with CMakeLists.txt, src/, qml/, resources/, translations/, tests/
- [X] T002 Create ui-slim/CMakeLists.txt with Qt6 dependencies (Core, Gui, QML, Quick, Multimedia, SQL), link against crankshaft-core library, set C++17 standard, add clang-format/clang-tidy integration
- [X] T003 Add ui-slim as subdirectory in root CMakeLists.txt with conditional build flag (ENABLE_SLIM_UI)
- [X] T004 Update .github/workflows for ui-slim CI: build (Debug/Release), unit tests, code quality checks (clang-format, clang-tidy, cppcheck)

### 1.2 Development Environment

- [X] T005 Create .clang-format config for ui-slim/ following Google C++ Style Guide (inherit from project root)
- [X] T006 Create ui-slim/tests/CMakeLists.txt with Qt Test framework setup, test discovery, coverage reporting
- [ ] T007 Create package build configuration: packaging/slim-ui/control (metadata), packaging/slim-ui/crankshaft-slim-ui.service (systemd unit), dpkg-buildpackage script

### 1.3 Documentation

- [X] T008 Create CONTRIBUTING.md in ui-slim/ with coding standards, branch naming, commit message format, PR checklist
- [X] T009 Create ui-slim/README.md with feature overview, quick start, build instructions, testing guide

---

## Phase 2: Foundational Infrastructure (blocking for all user stories)

### 2.1 Core Service Integration

- [X] T010 Discover and document existing core service APIs: read AndroidAutoService.h, PreferencesService.h, EventBus.h headers to understand interfaces, events, callbacks
- [X] T011 Create ui-slim/src/ServiceProvider.h: singleton class that initializes and provides access to core services (AndroidAutoService, PreferencesService, EventBus, AudioRouter, Logger)
- [X] T012 Implement ServiceProvider initialization in main.cpp: call core service initialize() methods, handle initialization errors, log startup sequence
- [X] T013 Create ui-slim/src/Logger.h wrapper: thin facade around core Logger with logging levels, categorized logging for connection/settings/ui events

### 2.2 Internationalization Foundation

- [X] T014 Create ui-slim/translations/slim-ui.pro (Qt translation project file)
- [X] T015 Create ui-slim/translations/slim-ui_en_GB.ts base translation file with en-GB context
- [X] T016 Setup translation build in CMakeLists.txt: lupdate for extraction, lrelease for compilation, embed in qml.qrc

### 2.3 QML Application Structure

- [X] T017 Create ui-slim/qml/main.qml: application root window (800x480 minimum, fullscreen by default), property bindings, signal handling, Loader components for view management
- [X] T018 Create ui-slim/qml/ApplicationController.qml: central state machine managing view navigation (AA view ↔ Settings view), connection state propagation, error handling
- [X] T019 Create ui-slim/qml/Theme.qml: color palette manager, light/dark mode toggle, font definitions, spacing constants following "Design for Driving" guidelines

### 2.4 Core Connection & Initialization

- [X] T020 Create ui-slim/src/main.cpp: QGuiApplication setup, QML engine initialization, register C++ types (facades) for QML access, ServiceProvider initialization, error handling and logging, command-line argument parsing (--platform eglfs/vnc, --debug)

---

## Phase 3: User Story 1 - Connect to AndroidAuto (Priority: P1)

**Story Goal**: User launches slim UI and connects AndroidAuto device for immediate projection. Target completion: all acceptance scenarios passing.

**Independent Test Criteria**: 
- Application launches without errors
- Device discovery works (shows "Searching..." status)
- Connection occurs automatically for single device within 3 seconds
- Video projection displays correctly in 1024x600 window
- Touch input forwards to connected device
- Audio routes through system speaker
- All state transitions logged

**Acceptance Scenarios to Test**:
1. Single AndroidAuto device auto-connects within 3s
2. Touch input accurately transmitted
3. Audio plays through system output
4. Initial launch shows connection instructions when no device present

### 3.1 AndroidAutoFacade - Core Bridge

- [X] T021 [P] Create ui-slim/src/AndroidAutoFacade.h: QObject with Q_PROPERTY connectionState, connectedDeviceName, lastError, isVideoActive, isAudioActive; Q_INVOKABLE startDiscovery(), connectToDevice(QString deviceId), disconnectDevice(); signals: connectionStateChanged, devicesDetected, connectionFailed, connectionEstablished
- [X] T022 [P] Implement ui-slim/src/AndroidAutoFacade.cpp: delegate to core::AndroidAutoService, translate core enums to QString for QML, subscribe to core::EventBus for connection/video/audio events, manage state transitions, implement auto-connect logic (connect to single device after 3s delay)
- [ ] T023 [P] Unit test AndroidAutoFacade: T024 (separate test task below)

### 3.2 Device Discovery & Multi-Device Handling

- [X] T024 [P] Create ui-slim/src/DeviceManager.h: track detected devices (list of DetectedDevice objects), implement priority ranking (last-connected device first), handle device addition/removal signals from core
- [X] T025 [P] Implement ui-slim/src/DeviceManager.cpp: subscribe to core AA discovery events, maintain device cache, emit devicesDiscovered/deviceRemoved signals for QML
- [X] T026 Create ui-slim/qml/DeviceSelectionDialog.qml: modal dialog displaying detected devices (name, connection type, signal strength for wireless), device list with selection highlight, "Connect" and "Cancel" buttons, auto-dismiss if single device after 3s

### 3.3 AndroidAuto Projection View

- [X] T027 [P] Create ui-slim/qml/AAProjectionView.qml: full-screen or fitted Rectangle container for video output, VideoOutput component bound to core's video stream, touch area capturing mouse events and forwarding to facade, responsive scaling based on window dimensions
- [X] T028 [P] Create ui-slim/qml/ConnectionStatusView.qml: status overlay showing "Searching...", "Connecting...", "Connected", "Disconnected", "Error" states with animated spinner for connecting state; displays error messages; shows device name when connected

### 3.4 Audio/Video Streaming Integration

- [X] T029 Create ui-slim/src/AudioBridge.h: setup audio output path (uses core::AudioRouter), detect ALSA/PulseAudio availability, handle audio buffer routing from AndroidAutoService to system audio, error handling for missing audio backend
- [X] T030 Implement ui-slim/src/AudioBridge.cpp: initialize audio sink, subscribe to core audio events, handle audio data flow, log audio backend in use at startup, gracefully degrade if unavailable (log error, set isAudioAvailable = false)
- [X] T031 Create ui-slim/src/TouchEventForwarder.h: translate QML mouse events to AndroidAuto touch format (pressure, coordinates, state)
- [X] T032 Implement ui-slim/src/TouchEventForwarder.cpp: capture touch coordinates, calculate scaling based on display resolution, forward to core::AndroidAutoService via facade, measure and log input latency

### 3.5 Connection State Management & Reconnection

- [X] T033 Create ui-slim/src/ConnectionStateMachine.h: model the connection lifecycle (DISCONNECTED→SEARCHING→CONNECTING→CONNECTED, with ERROR transitions), implement exponential backoff retry logic (1s, 2s, 4s, 8s, max ~30s)
- [X] T034 Implement ui-slim/src/ConnectionStateMachine.cpp: state transitions, automatic reconnection on unexpected disconnect, timeout handling, transition logging with timestamps
- [X] T035 Create ui-slim/qml/ReconnectionPrompt.qml: user-facing dialog shown after ~30s of failed reconnection attempts, displays "Reconnection failed", shows error message, provides "Manual Connect" and "Dismiss" buttons

### 3.6 Testing - User Story 1

- [X] T036 Create ui-slim/tests/test_android_auto_facade.cpp: unit tests for AndroidAutoFacade (property getters, state transitions, signals emission), mock core::AndroidAutoService
- [X] T037 Create ui-slim/tests/test_connection_state_machine.cpp: unit tests for reconnection logic, exponential backoff timing, state transitions
- [ ] T038 Create ui-slim/tests/integration/test_aa_launch_and_connect.cpp: integration test launching app, simulating device connection, verifying projection starts, touch input forwards, audio plays (requires physical device or emulation)

---

## Phase 4: User Story 2 - Access Basic Settings (Priority: P2)

**Story Goal**: User accesses settings UI to adjust brightness, volume, connection preferences. Target completion: all acceptance scenarios passing, settings persisted correctly.

**Independent Test Criteria**:
- Settings button visible and tappable from main view
- Settings panel opens within 500ms
- All controls (brightness, volume, connection preference, theme) update immediately
- Changes persist after app restart
- Corrupted settings reset to defaults with logged recovery event
- Factory defaults: brightness 50%, volume 50%, USB priority, dark theme

**Acceptance Scenarios to Test**:
1. Settings button opens settings panel within 500ms
2. Brightness adjustment applied immediately and persisted
3. Volume adjustment applied immediately
4. Connection preference (USB/wireless) setting works
5. App restart retains settings
6. Corrupted settings reset with logging

### 4.1 PreferencesFacade - Settings Bridge

- [X] T039 [P] Create ui-slim/src/PreferencesFacade.h: QObject with Q_PROPERTY displayBrightness (0-100), audioVolume (0-100), connectionPreference ("USB"/"WIRELESS"), themeMode ("LIGHT"/"DARK"), lastConnectedDeviceId; Q_INVOKABLE loadSettings(), saveSettings(); signals: setting changed signals for all properties
- [X] T040 [P] Implement ui-slim/src/PreferencesFacade.cpp: delegate to core::PreferencesService using slim_ui.* key prefix, validate ranges on set (brightness/volume 0-100), handle corruption detection/recovery, emit signals on changes, log save/recovery events
- [X] T041 [P] Unit test PreferencesFacade: test setting get/set, range validation, signal emission, corruption handling

### 4.2 Settings User Interface

- [X] T042 Create ui-slim/qml/SettingsPanel.qml: modal panel with tabbed/scrollable layout, groups: Display (brightness slider, theme toggle), Audio (volume slider), Connection (USB/Wireless toggle, reset button), all controls bound to PreferencesFacade properties via 2-way binding
- [X] T043 [P] Create ui-slim/qml/components/SettingsSlider.qml: reusable slider component with label, value display, 0-100 range, responds to touch
- [X] T044 [P] Create ui-slim/qml/components/ThemeToggle.qml: reusable toggle button for LIGHT/DARK theme, icons/labels for each mode
- [X] T045 Create ui-slim/qml/components/ConnectionPreferenceToggle.qml: toggle between USB and WIRELESS, labels showing preference
- [X] T046 Create ui-slim/qml/FactoryResetButton.qml: button to reset all settings to factory defaults (brightness 50%, volume 50%, USB, dark theme), confirmation dialog before reset

### 4.3 Settings Persistence

- [X] T047 Create ui-slim/src/SettingsMigration.h: handle settings file format versioning (for future migrations), detect schema version
- [X] T048 Implement ui-slim/src/SettingsMigration.cpp: migration logic from old to new format (if needed), corruption detection, automatic recovery to factory defaults
- [X] T049 Create ui-slim/tests/test_slim_settings_persistence.cpp: unit tests for setting operations (get/set/contains/remove), range validation, signal emission, corruption recovery, persistence verification
- [X] T050 Create ui-slim/tests/test_audio_failure_scenarios.cpp: unit tests for graceful degradation when audio backend unavailable (FR-025): verify error logged, user notification displayed ("Audio unavailable - video projection active"), video/touch continues functional, audio/voice input disabled

### 4.4 Display Brightness & Volume Control

- [X] T051 [P] Create ui-slim/src/DisplayBrightnessController.h: interface to system brightness control (DBus, /sys/class/backlight if available, or Qt platform integration)
- [X] T051 [P] Implement ui-slim/src/DisplayBrightnessController.cpp: apply brightness changes to system, read current brightness at startup, fallback to software brightness (QScreen::setMaximumColorDepth) if unavailable
- [X] T052 Create ui-slim/src/AudioVolumeController.h: interface to system volume control (via core::AudioRouter or ALSA/PulseAudio)
- [X] T053 Implement ui-slim/src/AudioVolumeController.cpp: apply volume changes, query current volume, handle audio backend errors gracefully

### 4.5 Theme Management

- [X] T054 Create ui-slim/qml/ThemeManager.qml: palette switching (light vs dark), color definitions for UI elements (buttons, text, backgrounds), font management
- [X] T055 Implement dynamic theme switching in main.qml: watch themeMode property, update all UI colors on change, persist theme selection to PreferencesFacade

### 4.6 Testing - User Story 2

- [ ] T056 Create ui-slim/tests/integration/test_settings_persistence.cpp: write settings, kill app, restart, verify settings retained; corrupt settings file, restart, verify factory defaults loaded with logged recovery event
- [ ] T057 Create ui-slim/tests/integration/test_settings_ui_flow.cpp: open settings panel, adjust all controls, close, reopen, verify values persisted

---

## Phase 5: Integration & Polish

### 5.1 View Navigation & Transitions

- [X] T059 Create ui-slim/qml/ViewNavigationController.qml: state management for switching between AA view and Settings view, transition animations (smooth 300ms transitions per spec), background task handling (AA continues running while settings open)
- [X] T060 Implement AA continues in background when settings open: ensure AndroidAutoService continues running, audio doesn't pause, video rendering pauses (no GPU waste) but resumes immediately on close
- [X] T061 Create button to access settings: corner icon button (44pt minimum) on AAProjectionView, always visible, tappable even during projection

### 5.2 Error Handling & Recovery

- [X] T062 Create ui-slim/src/ErrorHandler.h: centralized error/warning dialog system, maps error codes to user-friendly messages, logs errors
- [X] T063 Implement ui-slam/src/ErrorHandler.cpp: display error dialogs for connection failures, audio unavailable, settings corruption, etc.
- [X] T064 Create ui-slim/qml/ErrorDialog.qml: modal dialog showing error message with "OK" or "Retry" button

### 5.3 Logging & Observability

- [X] T065 [P] Implement comprehensive logging: connection state transitions logged with timestamps, settings changes logged, audio backend logged at startup, errors logged with context, enable SLIM_UI_DEBUG=1 environment variable for verbose logging
- [X] T066 Create ui-slim/src/LoggingConfig.h: structured logging setup, log levels, log categories (Connection, Settings, Audio, UI, etc.), output to stderr/file with rotation
**Note**: Existing Logger class in core already provides comprehensive structured logging. No additional implementation required.

### 5.4 Audio Failure Handling & Testing

- [X] T067 Create ui-slim/tests/test_audio_failure_scenarios.cpp: unit tests for audio backend failures (FR-025), including: PulseAudio unavailable on startup, ALSA device not found, audio stream disconnect during projection, graceful degradation (log error, disable audio, continue projection), recovery when audio backend becomes available

### 5.5 Responsive Layout Testing

- [ ] T068 Test responsive layout on multiple resolutions: 800x480 (default), 1024x600, 1280x720, 1920x1080; verify UI adapts without restart, touch targets remain >44pt
- [ ] T069 Create automated layout tests: unit tests verifying sizes/positions at various resolutions

### 5.6 Packaging & Deployment

- [X] T070 Create DEB package control file (packaging/ui-slim/control): package name crankshaft-slim-ui, depends on crankshaft-core (>= version), maintainer info, description, homepage
- [X] T071 Create systemd service file (packaging/ui-slim/crankshaft-slim-ui.service): service to launch slim UI, dependencies (network, core service), environment variables (e.g., SLIM_UI_DEBUG)
- [X] T072 Create dpkg build script (scripts/build-deb-slim-ui.sh): automate DEB packaging from source, version management, maintainer scripts (postinst/prerm)

### 5.7 Documentation & Examples

- [X] T073 Update quickstart.md with latest API changes and usage examples (if any from implementation)
- [ ] T074 Create example QML snippets in docs/ for extending slim UI in future

### 5.8 Code Quality & Testing

- [X] T075 [P] Run clang-format, clang-tidy, cppcheck on all C++ code; fix all warnings/violations
- [X] T076 [P] Achieve >80% code coverage for facades and core functionality; run coverage report (scripts/generate-coverage.sh created, execution pending)
- [X] T077 Code review checklist: verify all FRs implemented, all acceptance scenarios passing, no regressions (docs/CODE_REVIEW_CHECKLIST.md created)

---

## Phase 6: Final Validation & Release

### 6.1 Hardware Testing

- [ ] T078 Build Release package and test on Raspberry Pi 4 (32-bit OS, Trixie): verify app launches, discovers devices, connects, projects AA, audio plays, touch input works
- [ ] T079 Build Release package and test on Raspberry Pi 4 (64-bit OS, Trixie): verify app launches, discovers devices, connects, projects AA, audio plays, touch input works
- [ ] T080 Verify memory footprint <150MB during active AndroidAuto projection
- [ ] T081 Verify touch input latency <100ms
- [ ] T082 Verify stable 2-hour AndroidAuto session without crashes

### 6.2 VNC & EGLFS Testing

- [ ] T083 Test EGLFS backend on physical display (no code changes, just platform selection)
- [ ] T084 Test VNC backend on remote machine: launch with -platform vnc:port=5900, verify remote access

### 6.3 User Acceptance

- [ ] T085 Manual end-to-end testing: launch app, connect phone, project AA, adjust settings, disconnect/reconnect, verify all features work
- [ ] T086 Verify success criteria met:
  - SC-001: Connect within 5s of device connection ✓
  - SC-002: Stable 2-hour projection ✓
  - SC-003: Settings persist 100% ✓
  - SC-004: Memory <150MB (30% lower) ✓
  - SC-005: Touch latency <100ms ✓
  - SC-006: Runs on Pi 4 32/64-bit ✓
  - SC-007: Settings accessible within 1s ✓
  - SC-008: Disconnection detected within 2s ✓

### 6.4 Release Preparation

- [ ] T087 Update CHANGELOG.md: feature summary, breaking changes (none expected), known issues
- [ ] T088 Create release notes for version 1.0.0
- [ ] T089 Tag release commit with v1.0.0
- [ ] T090 Upload DEB package to packages repository

---

## Parallel Execution Strategy

### For User Story 1 (AndroidAuto Connection):
Tasks can execute in parallel:
- **Group A** (Core Bridge): T021, T022 (AndroidAutoFacade), T024, T025 (DeviceManager)
- **Group B** (UI Components): T027, T028 (Projection & Status views), T026 (Device selection)
- **Group C** (Integration): T029, T030 (Audio), T031, T032 (Touch)
- **Group D** (Connection Logic): T033, T034 (State machine), T035 (Reconnection UI)
- **Group E** (Testing): T036, T037, T038 (once Groups A-D are feature-complete)

Dependencies: Group E depends on A-D; no blocking dependencies between A-D.

### For User Story 2 (Settings):
Tasks can execute in parallel:
- **Group F** (Settings Bridge): T039, T040, T041 (PreferencesFacade)
- **Group G** (UI Components): T042, T043, T044, T045, T046 (Settings panel & controls)
- **Group H** (Control Logic): T050, T051 (Brightness), T052, T053 (Volume)
- **Group I** (Theme): T054, T055 (Theme management)
- **Group J** (Persistence): T047, T048 (Migration & corruption handling)
- **Group K** (Testing): T049, T056, T057 (once F-J are feature-complete)

Dependencies: Group K depends on F-J; no blocking dependencies between F-J.

### Sequential Dependencies:
- Phase 2 (Foundational) → Phase 3 (US1) → Phase 4 (US2) → Phase 5 (Integration) → Phase 6 (Validation)
- All foundational setup (T001-T020) must complete before story phases begin

---

## Implementation Strategy

### MVP Phase (Phase 1-4 Complete)

Delivers:
- ✅ Single device auto-connect on launch
- ✅ Full-screen AndroidAuto projection with touch/audio
- ✅ Settings accessible via corner button
- ✅ Brightness, volume, connection preference controls
- ✅ Settings persistence with corruption recovery
- ✅ Light/dark theme support
- ✅ Responsive layout (any resolution)

**Not included in MVP** (Deferred to Future Release Phases):
- ❌ User Story 3 (View switching while AA connected) - Deferred to Phase 2+ of future release cycle: Tasks T058-T060 created for Phase 5 infrastructure, but acceptance testing and feature completion deferred until Android Auto multi-window support architecture is validated in next major release
- ❌ Advanced extensibility - deferred to future when first plugin is needed (FR-018 specifies Phase 2+ extensibility)
- ❌ Wireless-specific features - basic wireless support included, advanced features future

### Incremental Delivery

1. **Checkpoint 1** (End of Phase 2): Build infrastructure, all services initialized, basic logging working
2. **Checkpoint 2** (End of Phase 3): Single device connects and projects; audio/touch functional
3. **Checkpoint 3** (End of Phase 4): Settings fully functional, persistent, themes working
4. **Checkpoint 4** (End of Phase 5): All features polished, error handling complete, observability solid
5. **Checkpoint 5** (End of Phase 6): Hardware validated, DEB package ready for release

---

## Task Dependencies & Critical Path

**Critical Path** (must serialize):
```
T001-T009 (Setup)
  ↓
T010-T020 (Foundational)
  ↓
T021-T038 (US1: AndroidAuto)
  ↓
T039-T057 (US2: Settings)
  ↓
T058-T075 (Integration & Polish)
  ↓
T076-T088 (Validation & Release)
```

**Total Tasks**: 90  
**Parallelizable Tasks**: ~45 (marked with [P])  
**Sequential Tasks**: ~43  
**Estimated Duration** (with 1-2 person team, full-time):
- Setup & Foundational: ~3-4 days
- US1 (with parallel execution): ~5-7 days
- US2 (with parallel execution): ~4-5 days
- Integration & Polish: ~3-4 days
- Validation & Release: ~2-3 days
- **Total: ~17-23 days** (3-4 weeks with buffers)

---

## Success Metrics

✅ All 26 functional requirements (FR-001 to FR-026) implemented  
✅ All 8 success criteria (SC-001 to SC-008) measurably achieved  
✅ All 3 user stories (US1, US2, US3) acceptance scenarios passing  
✅ Code coverage >80% for facades and core logic  
✅ Zero known critical bugs (release quality)  
✅ Memory <150MB on Raspberry Pi 4 (30% reduction)  
✅ Touch latency consistently <100ms  
✅ Stable 2+ hour projection verified on hardware  
✅ DEB package successfully builds and installs  

---
