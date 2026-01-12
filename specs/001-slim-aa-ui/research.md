# Research: Slim AndroidAuto UI Implementation

**Feature**: Slim AndroidAuto UI  
**Created**: 2026-01-10  
**Phase**: 0 - Research & Technology Selection

## Overview

This document consolidates research findings for implementing a lightweight AndroidAuto-focused UI that must run on Raspberry Pi 4 with VNC and EGLFS display support.

**IMPORTANT**: The slim UI leverages the existing Crankshaft **core** infrastructure rather than reimplementing services. The core provides:
- `AndroidAutoService`: AASDK integration, connection management, device detection
- `PreferencesService`: SQLite-backed key-value preferences
- `EventBus`: Publish/subscribe event system
- `AudioRouter`: Audio routing and stream management
- `Logger`: Structured logging
- `ServiceManager`: Service lifecycle management

The slim UI focuses on providing a minimal QML frontend that connects to these existing core services.

## Technical Context Research

### 1. UI Framework Selection

**Decision Required**: Choose UI framework for slim AndroidAuto interface

#### Option 1: Qt6 (QML + C++)
**Pros:**
- Already used in main Crankshaft project (existing expertise)
- Excellent EGLFS and VNC backend support via Qt Platform Abstraction (QPA)
- QML provides declarative, responsive UI with hardware acceleration
- Qt Multimedia for audio routing
- Mature AndroidAuto integration examples (openauto uses Qt5)
- Built-in i18n support via Qt Linguist
- Theme support through QML styling
- Touch input handling well-established

**Cons:**
- Larger memory footprint (~100-150MB base)
- Heavier dependencies
- May be overkill for minimal 2-screen UI

**Assessment**: **Best fit for this project** given existing codebase familiarity, proven AndroidAuto integration, and complete platform support.

#### Option 2: GTK4 + C
**Pros:**
- Lighter than Qt (~60-80MB)
- Good Linux ecosystem support
- Cairo/Pango for rendering
- Can run on EGLFS via Wayland compositor

**Cons:**
- No direct EGLFS backend (requires Wayland layer)
- Limited VNC support (requires additional setup)
- AndroidAuto integration unproven
- Touch optimization less mature than Qt
- Team has no existing expertise

**Assessment**: Not recommended - lacks proven AndroidAuto path and VNC/EGLFS requirements complicate deployment.

#### Option 3: SDL2 + Custom Rendering
**Pros:**
- Very lightweight (~20-30MB)
- Direct framebuffer access
- Works on EGLFS
- Simple event handling

**Cons:**
- No high-level UI toolkit (must build from scratch)
- No built-in responsive layout system
- No theme support out of box
- Would require significant UI framework development
- No AndroidAuto integration examples

**Assessment**: Too low-level for timeline - would require building UI framework from scratch.

#### Option 4: Electron/Node.js + Web Technologies
**Pros:**
- Familiar web technologies (HTML/CSS/JS)
- Responsive layouts native
- Fast prototyping

**Cons:**
- Massive memory footprint (200-300MB+)
- Poor performance on Pi 4
- Complex EGLFS/VNC setup
- AndroidAuto integration extremely difficult
- Violates 30% memory reduction goal

**Assessment**: Eliminated - fails performance requirements.

#### Option 5: Flutter
**Pros:**
- Modern reactive framework
- Good performance
- Hardware accelerated
- EGLFS support via embedder

**Cons:**
- No established AndroidAuto integration
- VNC support requires custom implementation
- Team has no Dart/Flutter expertise
- Unproven on Raspberry Pi for production automotive use

**Assessment**: Too risky for timeline - unproven AndroidAuto path.

**RECOMMENDATION**: **Qt6 with QML** - Only option meeting all requirements with proven AndroidAuto integration path and existing team expertise.

---

### 2. AndroidAuto Integration Strategy

**Decision**: Use existing core `AndroidAutoService` instead of direct AASDK integration

#### Research Findings:

**Core AndroidAutoService Analysis:**
- Already wraps AASDK library with Qt-friendly interface
- Handles USB/wireless connection negotiation
- Provides ConnectionState enum and signals
- Device detection and management built-in
- Audio/video pipeline integration via MediaPipeline
- Thread-safe, service-based architecture

**Integration Approach:**
- **Use existing `AndroidAutoService` from core** - no need to reimplement AASDK integration
- Connect QML frontend to AndroidAutoService signals/slots
- Subscribe to EventBus for AA connection events
- Video projection: Already handled by core's MediaPipeline
- Audio routing: Already handled by core's AudioRouter
- Touch input: Forward from QML to AndroidAutoService methods

**Benefits of Using Core:**
- No duplicate AASDK integration code
- Proven, tested AndroidAuto implementation
- Consistent with main Crankshaft UI architecture
- Leverages existing service lifecycle management

---

### 3. Display Backend Support (EGLFS vs VNC)

**Decision**: Ensure both backends work without code changes

#### EGLFS (Embedded OpenGL Fullscreen):
- Direct framebuffer rendering via OpenGL ES
- Used for physical displays on Raspberry Pi
- Qt Platform Plugin: `-platform eglfs`
- Hardware accelerated
- Best performance

#### VNC (Virtual Network Computing):
- Network-based display protocol for remote access
- Qt Platform Plugin: `-platform vnc:size=1024x600,port=5900`
- Software rendering or hardware-accelerated depending on backend
- Essential for development and debugging

**Implementation Strategy:**
- Use Qt's QPA (Qt Platform Abstraction) - no code changes needed
- Runtime platform selection via command-line argument or environment variable
- Both backends supported natively by Qt6

**Testing Plan:**
- CI builds test on VNC backend (headless CI runners)
- Physical device testing on EGLFS
- Document platform selection in README/quickstart

---

### 4. Audio Routing Architecture

**Decision**: Support ALSA and PulseAudio with runtime detection (per clarification)

#### ALSA (Advanced Linux Sound Architecture):
- Low-level kernel sound system
- Direct hardware access
- Lower latency
- Common on minimal embedded systems

#### PulseAudio:
- Sound server sitting above ALSA
- Device abstraction and automatic routing
- Standard on Raspberry Pi OS Desktop
- Better for hotplug devices

**Implementation Strategy:**
- Qt Multimedia abstracts audio backends automatically
- QAudioSink/QAudioSource for playback/recording
- Runtime detection: Qt detects available backend automatically
- For AASDK: PCM data from AASDK → Qt audio buffer → system output
- Fallback chain: PulseAudio → ALSA → fail with error

**Configuration:**
- No hardcoded device names
- Use system defaults (Qt handles this)
- Log which backend is active for troubleshooting

---

### 5. Settings Persistence Strategy

**Decision**: Use existing core `PreferencesService` instead of custom JSON implementation

#### Research Findings:

**Core PreferencesService Analysis:**
- SQLite-backed key-value store
- In-memory caching for performance
- Built-in `preferenceChanged` signals
- Thread-safe operations
- Handles initialization, corruption recovery
- Location: Managed by PreferencesService (typically SQLite database)

**Integration Approach:**
- **Use existing `PreferencesService` from core** - no custom persistence needed
- Slim UI settings stored with prefixes: `slim_ui.display.brightness`, `slim_ui.audio.volume`, etc.
- Factory defaults provided on first access via `get(key, defaultValue)`
- QML backend wraps PreferencesService for property binding
- Automatic persistence on value changes

**Benefits of Using Core:**
- No need to implement JSON parsing/writing
- Corruption handling built-in
- Consistent with main Crankshaft settings
- Better performance (SQLite + caching vs JSON file I/O)
- Automatic signal emission on changes

---

### 6. Responsive Layout Strategy

**Decision**: Fully responsive layout adapting to any resolution (per clarification)

#### Qt QML Approach:
- Use Anchors for relative positioning
- Define breakpoints for layout changes if needed
- Scale fonts/elements proportionally
- Minimum resolution: 800x480 (common automotive display)
- Test resolutions: 800x480, 1024x600, 1280x720, 1920x1080

**Implementation Pattern:**
```qml
ApplicationWindow {
    width: Screen.width
    height: Screen.height
    
    // Use relative units
    Item {
        width: parent.width * 0.2
        height: parent.height * 0.1
    }
}
```

---

### 7. Multi-Device Selection UI

**Decision**: Device selection dialog when multiple AndroidAuto devices present (per clarification)

**UI Pattern:**
- Modal dialog with device list
- Each entry shows: device name, connection type (USB/Wireless), last connected indicator
- Timeout: auto-select if only one device after 3 seconds
- Cancel: return to waiting screen

**Implementation:**
- QML Dialog component
- Device list populated from AASDK device discovery
- Store last connected device in settings for prioritization

---

### 8. Dependency Management

**Core Dependencies:**
- Crankshaft Core library (AndroidAutoService, PreferencesService, EventBus, Logger, AudioRouter)
- Qt6 (Base, QML, Quick, Multimedia) - Already required by core
- Qt6 SQL - Required by PreferencesService
- AASDK library - Indirect dependency via core's AndroidAutoService

**New Dependencies:**
- None required - slim UI only adds QML frontend to existing core

**Build System:**
- CMake (consistent with main project)
- Link against `crankshaft-core` library
- Separate CMakeLists.txt in `ui-slim/` directory
- Generate standalone deb package with core library dependency

---

### 9. Project Structure

**Proposed Directory Layout:**
```
crankshaft-mvp/
├── core/                       # EXISTING: Core library (reused)
│   ├── services/
│   │   ├── android_auto/       # AndroidAutoService
│   │   ├── preferences/        # PreferencesService
│   │   ├── eventbus/           # EventBus
│   │   ├── logging/            # Logger
│   │   └── audio/              # AudioRouter
├── ui-slim/                    # NEW: Slim UI component
│   ├── CMakeLists.txt          # Links against crankshaft-core
│   ├── src/
│   │   ├── main.cpp            # Initializes core services
│   │   ├── AndroidAutoFacade.cpp   # QML bridge to AndroidAutoService
│   │   ├── AndroidAutoFacade.h
│   │   ├── PreferencesFacade.cpp   # QML bridge to PreferencesService
│   │   └── PreferencesFacade.h
│   ├── qml/
│   │   ├── main.qml
│   │   ├── AAProjectionView.qml
│   │   ├── SettingsPanel.qml
│   │   ├── DeviceSelectionDialog.qml
│   │   └── ConnectionStatusView.qml
│   ├── resources/
│   │   └── icons/
│   ├── translations/
│   │   └── slim-ui_en_GB.ts
│   └── tests/
│       ├── test_aa_facade.cpp
│       └── test_preferences_facade.cpp
```

**Rationale:**
- Reuses existing core library services (no duplication)
- Slim UI only contains QML frontend + thin C++ facades
- Clear separation from main UI (FR-001)
- Facade pattern isolates QML from core service implementation details
- Dramatically reduced code size (~500-800 LOC vs ~1500-2000 LOC)
- Testable facades with unit tests

---

### 10. Licensing & Feature Flags Integration

**Decision**: How to integrate with existing Crankshaft license tiers

**Approach:**
- Slim UI should honor Bronze/Silver/Gold/Platinum tiers
- For MVP: assume Platinum (all features enabled)
- For future: integrate with core licensing service via IPC or config file
- Feature gates:
  - Wireless AndroidAuto (Gold+)
  - Custom themes (Silver+)
  - All else available in Bronze

**Implementation:**
- Read license tier from shared config or core service
- Gate features in QML based on tier
- Log tier on startup for troubleshooting

---

## Best Practices from Technology Choices

### Qt6 + QML Best Practices:
1. **Separation**: Keep business logic in C++, UI in QML
2. **Performance**: Use Loaders for conditional UI elements
3. **Memory**: Minimize QML component tree depth
4. **Touch**: Ensure 44x44pt minimum touch targets
5. **Theming**: Use Qt Quick Controls 2 styling system
6. **Logging**: Use qDebug() with categories for structured output

### AndroidAuto Integration Best Practices:
1. **Core Delegation**: Delegate all AA logic to `AndroidAutoService` - no direct AASDK calls
2. **Event Subscription**: Subscribe to core's EventBus for AA events (connection, video, audio, errors)
3. **Facade Pattern**: Keep facades thin - only translate Qt signals/properties, no business logic
4. **Thread Safety**: Core handles threading - facades run on Qt main thread
5. **State Sync**: Update QML properties when core service state changes via EventBus

### Raspberry Pi Optimization Best Practices:
1. **GPU**: Enable VC4 graphics driver for hardware acceleration
2. **Memory**: Set GPU memory split appropriately (256MB recommended)
3. **CPU**: Use Release builds for deployment (Debug for development)
4. **Storage**: Use SD card with good random I/O performance
5. **Thermal**: Monitor CPU temperature, throttle if needed

---

## Patterns for Key Integration Points

### Pattern 1: Facade to Core Service
```cpp
// AndroidAutoFacade bridges QML to core service
class AndroidAutoFacade : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString connectionState READ connectionState NOTIFY connectionStateChanged)
private:
    AndroidAutoService* m_coreService; // Core service reference
    
    void onCoreStateChanged(ConnectionState state) {
        // Convert core enum to QString for QML
        emit connectionStateChanged();
    }
};
```

### Pattern 2: Touch Event Forwarding (via Facade)
```qml
MouseArea {
    anchors.fill: parent
    onPressed: aaFacade.sendTouchEvent("down", mouse.x, mouse.y)
    onReleased: aaFacade.sendTouchEvent("up", mouse.x, mouse.y)
}

// Facade delegates to core
void AndroidAutoFacade::sendTouchEvent(QString type, int x, int y) {
    m_coreService->sendTouchInput(type.toStdString(), x, y);
}
```

### Pattern 3: EventBus Subscription for Core Events
```cpp
// Subscribe to AA events from core
void AndroidAutoFacade::init() {
    auto* eventBus = EventBus::instance();
    connect(eventBus, &EventBus::messagePublished, this,
        [this](QString topic, QVariant payload) {
            if (topic == "aa.connection.stateChanged") {
                updateConnectionState();
            }
        });
}
```

---

## Open Questions / Decisions Deferred to Implementation

None remaining - all technical clarifications resolved.

---

## Summary of Recommendations

| Decision Area | Recommendation | Rationale |
|--------------|----------------|-----------|
| **UI Framework** | Qt6 with QML | Proven, complete platform support, existing expertise |
| **AA Integration** | Use core's AndroidAutoService | AASDK already integrated in core - no duplication needed |
| **Display Backends** | EGLFS + VNC via Qt QPA | No code changes needed, runtime selection |
| **Audio** | Use core's AudioRouter | Core handles ALSA/PulseAudio routing automatically |
| **Settings Storage** | Use core's PreferencesService | SQLite-backed, already handles corruption/caching |
| **Layout** | Responsive QML with anchors | Native QML capability, no library needed |
| **Build System** | CMake, link against crankshaft-core | Reuses existing core library |
| **Package** | Separate DEB with core dependency | Allows independent installation/updates |

---

## Next Steps

Proceed to **Phase 1: Design & Contracts**
- Define data models
- Create API contracts (internal service interfaces)
- Generate quickstart guide
- Update agent context
