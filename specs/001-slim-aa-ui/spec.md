# Feature Specification: Slim AndroidAuto UI

**Feature Branch**: `001-slim-aa-ui`  
**Created**: 2026-01-10  
**Status**: Draft  
**Input**: User description: "Create a new slim UI in a separate folder. Make this UI support AA and Settings only."

## Clarifications

### Session 2026-01-10

- Q: Settings access method (button or gesture)? → A: On-screen button always visible (corner icon/button)
- Q: Multiple device connection behavior? → A: Show selection dialog for user to choose which device to connect
- Q: Corrupted settings recovery strategy? → A: Reset to factory defaults (brightness 50%, volume 50%, USB priority) and log recovery event
- Q: Display resolution handling strategy? → A: Fully responsive layout that adapts to any resolution dynamically
- Q: Audio routing architecture? → A: Support both ALSA and PulseAudio with runtime detection
- Q: Should spec document core library dependency? → A: Yes, add explicit requirement documenting facade pattern approach
- Q: Handle missing audio backend failure? → A: Log error, display on-screen notification, continue with video/touch only
- Q: Should slim UI implement extension framework now? → A: No, defer to future phase when extensibility is actually needed
- Q: Automatic or manual reconnection after disconnect? → A: Automatic retry with exponential backoff; show status; prompt user after ~30s
- Q: Logging verbosity (development vs production)? → A: Log state transitions and errors by default; enable verbose debugging via SLIM_UI_DEBUG=1 environment variable

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Launch and Connect to AndroidAuto (Priority: P1)

User starts the slim UI application and immediately connects their phone to begin AndroidAuto projection without navigating through unnecessary menus or features.

**Why this priority**: This is the core purpose of the slim UI - providing immediate access to AndroidAuto functionality. Without this working, the application provides no value.

**Independent Test**: Can be fully tested by launching the application and connecting an AndroidAuto-compatible device. Delivers immediate AndroidAuto projection capability.

**Acceptance Scenarios**:

1. **Given** the slim UI application is launched, **When** user connects an AndroidAuto-compatible device via USB or wireless, **Then** AndroidAuto projection starts automatically within 3 seconds
2. **Given** AndroidAuto is connected, **When** user interacts with the projected interface, **Then** touch inputs are accurately transmitted to the phone
3. **Given** AndroidAuto is running, **When** audio plays from the phone, **Then** audio is routed through the system audio output
4. **Given** no phone is connected, **When** the application launches, **Then** a clear prompt displays instructions for connecting a device

---

### User Story 2 - Access Basic Settings (Priority: P2)

User needs to adjust basic system configuration (display brightness, audio volume, connection preferences) without leaving the slim UI environment.

**Why this priority**: Essential for usability but not required for basic AndroidAuto functionality. Users need minimal configuration options to optimize their experience.

**Independent Test**: Can be tested by accessing the settings interface and modifying each available setting. Delivers standalone configuration capability.

**Acceptance Scenarios**:

1. **Given** the slim UI is running, **When** user taps the on-screen settings button, **Then** settings panel opens within 500ms
2. **Given** settings panel is open, **When** user adjusts display brightness, **Then** change is applied immediately and persisted
3. **Given** settings panel is open, **When** user adjusts audio volume, **Then** change takes effect immediately
4. **Given** settings are modified, **When** application restarts, **Then** previously saved settings are retained
5. **Given** settings panel is open, **When** user selects "back" or exit action, **Then** settings panel closes and returns to main view

---

### User Story 3 - Switch Between AA and Settings Views (Priority: P3)

User navigates between AndroidAuto projection and settings interface smoothly without application restart or interruption to the AndroidAuto connection.

**Why this priority**: Improves user experience but AndroidAuto can function without seamless switching. Users can tolerate brief disconnections for configuration changes.

**Independent Test**: Can be tested by switching between views multiple times while AndroidAuto is connected. Delivers smooth navigation experience.

**Acceptance Scenarios**:

1. **Given** AndroidAuto is actively projecting, **When** user opens settings, **Then** AndroidAuto continues running in background (audio uninterrupted)
2. **Given** settings panel is open, **When** user returns to AndroidAuto view, **Then** projection resumes immediately without reconnection
3. **Given** user is navigating between views, **When** switching occurs, **Then** transition completes in under 300ms
4. **Given** AndroidAuto is not connected, **When** user switches to settings, **Then** transition occurs normally without errors

---

### Edge Cases

- What happens when AndroidAuto device disconnects unexpectedly during projection? System displays reconnection prompt within 2 seconds
- How does the system handle multiple AndroidAuto-compatible devices connected simultaneously? System presents selection dialog for user to choose which device to connect
- What happens when settings are accessed while AndroidAuto is initializing connection? Settings panel opens normally; connection continues in background
- How does the system respond to corrupted or missing settings configuration files? System resets to factory defaults (brightness 50%, volume 50%, USB priority) and logs recovery event
- What happens when system resources are limited (low memory/CPU)? System logs resource warnings and may delay non-critical operations
- How does the application handle display resolution changes during runtime? Fully responsive layout automatically adapts to new resolution without restart
- What happens if audio backend (ALSA/PulseAudio) is unavailable or non-functional? System logs error, displays on-screen notification ("Audio unavailable - video projection active"), and continues with video/touch enabled; user can view AndroidAuto content and send touch input but cannot hear audio or send voice commands

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a separate UI application isolated from the main Crankshaft UI codebase
- **FR-002**: System MUST integrate with AASDK library for AndroidAuto connectivity and projection
- **FR-003**: System MUST support both USB and wireless AndroidAuto connections
- **FR-004**: System MUST automatically detect and initiate AndroidAuto connection when compatible device is connected
- **FR-005**: System MUST display AndroidAuto projection output in full-screen or designated viewport
- **FR-006**: System MUST correctly route touch input from the UI to the connected AndroidAuto device
- **FR-007**: System MUST route audio output from AndroidAuto to the system audio device using ALSA or PulseAudio with runtime detection
- **FR-008**: System MUST provide audio input (microphone) to AndroidAuto for voice commands using ALSA or PulseAudio with runtime detection
- **FR-009**: System MUST include a settings interface accessible via on-screen button (corner icon) that remains visible during AndroidAuto projection
- **FR-010**: System MUST persist settings between application restarts using configuration files; reset to factory defaults if corrupted (brightness 50%, volume 50%, USB priority) and log recovery event with timestamp and reason
- **FR-011**: Settings MUST include display brightness control (0-100% range)
- **FR-012**: Settings MUST include audio volume control (0-100% range)
- **FR-013**: Settings MUST include AndroidAuto connection preferences (USB/wireless priority)
- **FR-014**: System MUST display connection status (searching, connecting, connected, disconnected)
- **FR-015**: System MUST gracefully handle AndroidAuto disconnection and implement automatic reconnection with exponential backoff (1s, 2s, 4s, 8s delays); display "Reconnecting..." status during retry attempts; after ~30 seconds of continuous failures, prompt user for manual intervention
- **FR-022**: When multiple AndroidAuto-compatible devices are connected simultaneously, system MUST present selection dialog for user to choose which device to connect
- **FR-023**: System MUST support fully responsive layout that dynamically adapts to any display resolution without requiring restart
- **FR-016**: System MUST log AndroidAuto connection events for troubleshooting
- **FR-017**: System MUST support light and dark theme modes for the settings interface
- **FR-018**: System MUST support extension framework integration in future phases when extensibility is needed; MVP phase focuses on core 2-screen functionality (AndroidAuto + Settings) without plugin mechanism
- **FR-019**: System MUST build as a standalone executable separate from main Crankshaft UI
- **FR-020**: System MUST support deployment on Raspberry Pi 4 with Raspberry Pi OS
- **FR-021**: System MUST build a separate deb file for apt
- **FR-024**: System MUST use existing Crankshaft core library services (AndroidAutoService, PreferencesService, EventBus, AudioRouter, Logger) via thin C++ facade classes to eliminate code duplication and ensure consistency with main Crankshaft UI
- **FR-025**: System MUST gracefully degrade when audio subsystem is unavailable: log error, display user notification ("Audio unavailable - video projection active"), and allow video/touch functionality to continue
- **FR-026**: System MUST log AndroidAuto connection state transitions, errors, and application lifecycle events by default; enable verbose debug-level logging via `SLIM_UI_DEBUG=1` environment variable (logs include method calls, signal emissions, detailed state changes)

## Constitution Check *(mandatory)*

### Impacted Constitution Principles

- **Code Quality**: Slim UI must follow project coding standards (Google C++ Style Guide, QML best practices)
- **Testing**: Unit tests required for settings persistence, connection state management
- **UX**: Must provide responsive, modern, and clean interface following "Design for Driving" guidelines  
- **Performance**: Must minimize resource usage to run efficiently on Raspberry Pi 4
- **Observability**: Must log connection events and errors for debugging

### Measurable Acceptance Criteria

- Code passes clang-format, clang-tidy, and cppcheck validation (linked to Code Quality)
- Automated tests achieve >80% code coverage for settings and connection modules (linked to Testing)
- UI responds to touch input within 100ms (linked to UX and Performance)
- Memory usage remains under 150MB during active AndroidAuto projection (linked to Performance)
- All connection state changes are logged with timestamps (linked to Observability)

### Key Entities *(include if feature involves data)*

- **SlimUI Application**: The standalone executable that provides the minimal interface, manages AndroidAuto connection lifecycle, and coordinates between projection and settings views
- **AndroidAuto Connection**: Represents the active connection to a user's phone, including connection type (USB/wireless), connection state, and device identification
- **Settings Configuration**: Persistent storage of user preferences including display brightness, audio volume, connection preferences, and theme selection
- **Projection Surface**: The display area where AndroidAuto content is rendered, supporting full-screen or windowed modes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can launch the slim UI and connect AndroidAuto within 5 seconds of device connection
- **SC-002**: System maintains stable AndroidAuto projection for continuous 2-hour sessions without crashes
- **SC-003**: Settings changes are persisted with 100% reliability across application restarts
- **SC-004**: Application memory footprint is at least 30% lower than full Crankshaft UI during AndroidAuto projection
- **SC-005**: Touch input latency is consistently under 100ms during AndroidAuto projection
- **SC-006**: Application successfully builds and runs on Raspberry Pi 4 (both 32-bit and 64-bit OS variants)
- **SC-007**: Users can access settings within 1 second from any application state
- **SC-008**: AndroidAuto disconnection is detected and handled within 2 seconds with clear user feedback
