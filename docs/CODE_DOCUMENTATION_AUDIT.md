# Code Documentation Audit Report

**Generated**: 2025-01-15
**Project**: Crankshaft Automotive Infotainment System
**Scope**: Comprehensive audit of core, UI, and slim-ui subsystems

## Executive Summary

This document provides a comprehensive audit of the Crankshaft codebase to ensure all logic is properly documented with explanations, scenario examples, and design rationale.

---

## 1. Core Architecture Overview

### 1.1 System Topology

The Crankshaft Core application follows a layered architecture:

```
┌─────────────────────────────────────────────────────────┐
│                   UI Layer (QML/C++)                     │
│           (ui/, ui-slim/, ui/qml/)                       │
└────────────────────┬────────────────────────────────────┘
                     │ WebSocket (wss://)
┌────────────────────▼────────────────────────────────────┐
│              Core Application Layer                      │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Event Bus (Pub/Sub)                                  │ │
│ │ ServiceManager (lifecycle management)                │ │
│ │ WebSocketServer (event relay)                        │ │
│ │ ProfileManager (device configurations)               │ │
│ └──────────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Service Layer                              │
│ ┌──────────────┬──────────────┬───────────────────────┐ │
│ │ AndroidAuto  │ Audio        │ Video                 │ │
│ ├──────────────┼──────────────┼───────────────────────┤ │
│ │ WiFi Manager │ Media        │ Bluetooth             │ │
│ ├──────────────┼──────────────┼───────────────────────┤ │
│ │ CAN Bus      │ Diagnostics  │ Extensions            │ │
│ └──────────────┴──────────────┴───────────────────────┘ │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              HAL Layer (Hardware Abstraction)            │
│ ┌──────────────┬──────────────┬───────────────────────┐ │
│ │ Audio HAL    │ Video HAL    │ Wireless HAL          │ │
│ ├──────────────┼──────────────┼───────────────────────┤ │
│ │ Transport    │ Multimedia   │ Functional Devices    │ │
│ └──────────────┴──────────────┴───────────────────────┘ │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│         Linux Kernel / Hardware                         │
│ (ALSA, V4L2, USB, GPIO, I2C, CAN)                       │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Key Components

#### EventBus (Event-Driven Architecture)
- **File**: `core/services/eventbus/EventBus.h`
- **Purpose**: Central message hub using Pub/Sub pattern
- **Pattern**: Singleton with thread-safe mutex protection
- **Mechanism**: Qt signals/slots for in-process communication
- **Design Rationale**: Enables loose coupling between services and UI

**Scenario Example**: AndroidAuto service receives USB connection event
1. HAL detects USB device connected
2. AndroidAutoService emits `messagePublished("android_auto/device_connected", {...})`
3. EventBus forwards signal to all subscribers
4. WebSocketServer broadcasts to connected UI clients
5. UI updates display showing device ready

#### WebSocketServer (Bi-directional Communication)
- **File**: `core/services/websocket/WebSocketServer.h`
- **Purpose**: Real-time event relay between core and UI via WebSocket
- **Protocol**: JSON-based messages over wss:// (SSL/TLS)
- **Connection**: One-to-many (server broadcasts, clients subscribe)
- **Security**: Certificate-based TLS encryption

**Scenario Example**: UI requests AudioAuto service restart
1. UI sends JSON: `{action: "restart_service", service: "AndroidAuto"}`
2. WebSocketServer receives and parses message
3. ServiceManager.restartService("AndroidAuto") is called
4. Service stops, reinitialises, starts
5. WebSocketServer broadcasts service status update back to UI
6. UI reflects new status in real-time

#### ServiceManager (Lifecycle Management)
- **File**: `core/services/service_manager/ServiceManager.h`
- **Purpose**: Start, stop, reload services based on profiles
- **Coordination**: Orchestrates multiple services with dependency tracking
- **Lifecycle States**: Not Started → Running → Stopping → Stopped

**Scenario Example**: User switches to "Off-Road" profile
1. ProfileManager notifies active profile change
2. ServiceManager.reloadServices() called
3. Services not in new profile are stopped gracefully
4. Services in new profile are started with new configs
5. WebSocketServer publishes "profile_switched" event
6. UI reflects new interface layout for off-road mode

#### ProfileManager (Device Configuration)
- **File**: `core/services/profile/ProfileManager.h`
- **Purpose**: Manages device-specific configurations (profiles)
- **Profile Types**: HostProfile, DeviceProfile
- **Storage**: JSON files in `/etc/crankshaft/profiles/`

**Scenario Example**: Multi-display setup on Raspberry Pi 4
- Profile defines 2 displays:
  - Display 0 (primary): Android Auto navigation (1024x600)
  - Display 1 (secondary): Media controls (800x480)
- Each display has independent QML UI instance
- Events published to shared EventBus, each UI subscribes to relevant topics
- Services publish display-specific events (e.g., "display:0/media_update")

---

## 2. Core Services

### 2.1 AndroidAuto Service

**File**: `core/services/android_auto/AndroidAutoService.h`

**Purpose**: Integration with Android devices via USB/wireless

**Architecture**:
- Wraps AASDK library for protocol handling
- Uses MediaPipeline for audio/video streaming
- Publishes events for UI binding

**Key Events Emitted**:
- `android_auto/device_connected`: Device ready for projection
- `android_auto/device_disconnected`: Device disconnected
- `android_auto/projection_started`: Screen mirroring active
- `android_auto/projection_stopped`: Screen mirroring ended
- `android_auto/audio_focus_changed`: Audio routing updated

**Scenario: Android Auto Projection Workflow**
```
Time  Event                          Component             UI State
─────────────────────────────────────────────────────────────────────
0ms   USB device connected           HAL/AASDK            "Waiting..."
50ms  device_connected published     AndroidAutoService   "Tap to start"
100ms User taps "Start Projection"   QML Button           "Starting..."
150ms MediaPipeline starts           MediaPipeline        "Connecting..."
200ms Audio/video stream begins      AudioHAL/VideoHAL    "Streaming"
250ms projection_started published   AndroidAutoService   "Active"

Error Scenario: Device disconnects mid-projection
───────────────────────────────────────────────────────
Time  Event                           Component
─────────────────────────────────────────────────────
0ms   USB disconnect detected         HAL
20ms  device_disconnected published   AndroidAutoService
40ms  MediaPipeline stops             MediaPipeline
60ms  Audio/video halted              HAL
80ms  UI returns to home screen       QML binding
```

### 2.2 Audio Service

**File**: `core/hal/multimedia/AudioHAL.h`

**Purpose**: Abstracts audio subsystem (ALSA on Linux)

**Audio Routes**:
- `Default`: Speaker output
- `Headset`: Wired headphones
- `Bluetooth`: BT speaker/headset
- `Auxiliary`: AUX input

**Implementation**:
- Uses ALSA (Advanced Linux Sound Architecture)
- Supports 16/24/32-bit PCM
- Configurable sample rates: 44.1kHz, 48kHz, 96kHz
- Multi-stream mixing via AudioMixer

**Scenario: Bluetooth Headset Connection**
```
1. BluetoothHAL detects headset connection
   - Publishes: "bluetooth/device_connected"
2. AudioService receives event
   - Sets audioRoute = Bluetooth
   - Reconfigures ALSA to route to BT device
   - Publishes: "audio/route_changed"
3. UI receives event
   - Updates icon showing BT device active
   - May display volume control
4. Media playback continues uninterrupted
   - Audio switches from speaker to BT device
5. When headset disconnects
   - Falls back to speaker automatically
   - Publishes: "audio/route_changed"
```

### 2.3 Video/Multimedia Pipeline

**File**: `core/hal/multimedia/MediaPipeline.h`, `VideoHAL.h`

**Purpose**: Coordinate video decoding and display

**Video Codec Support**:
- H.264 (AVC) - most common
- H.265 (HEVC) - future support
- VP9 - for WebRTC

**Streaming Architecture**:
```
Input Stream (h264) → Decoder (GStreamer/HW) → Renderer (QML) → Display

Configuration:
├─ Resolution: 720p, 1080p, 2K
├─ Frame Rate: 30fps, 60fps
├─ Bitrate: Adaptive
└─ Latency: <200ms (critical for driving)
```

**Scenario: Android Auto Video Stream**
```
AASDK provides H.264 frames → GStreamerVideoDecoder → QML VideoOutput

Adaptive Bitrate (if network degrades):
- Initially: 1080p 60fps 5Mbps
- Network jitter detected
- Throttle to: 720p 30fps 2Mbps
- Network recovers
- Resume: 1080p 60fps 5Mbps

Error Recovery (frame loss):
- Decoder detects corrupted frame
- Publishes: "video/frame_error"
- Requests keyframe from source
- Resume smooth playback
```

### 2.4 Transport Layer

**File**: `core/hal/transport/Transport.h`, `UARTTransport.h`

**Purpose**: Abstraction for various data transports

**Supported Transports**:
- **USB**: For AndroidAuto/Wireless AndroidAuto handshake
- **UART**: For car integration (steering wheel, climate controls)
- **CAN Bus**: For OBD-II diagnostics
- **Custom**: Extensible interface

**Scenario: UART Communication with Vehicle**
```
Raw UART bytes from vehicle → Transport layer parser → Structured events

Example: Steering wheel button press
─────────────────────────────────────
1. Vehicle CAN bus → UART interface (filtered/translated)
2. Raw bytes: 0x02, 0x14, 0x03
3. Parser identifies: Button ID=0x14 (Next Track), State=Press
4. Publishes: "vehicle/button_pressed" {buttonId: 20, buttonName: "NextTrack"}
5. Media service receives event → skips to next track
6. Feedback published: "media/track_changed"
```

---

## 3. UI Architecture (ui/)

### 3.1 QML Architecture

**Files**: `ui/qml/` (QML UI components)

**Structure**:
```
ui/qml/
├── Pages/           # Full-screen pages (home, media, nav, etc)
├── Components/      # Reusable widgets (buttons, sliders, cards)
├── Layouts/         # Layout containers (grid, stack, etc)
├── Controls/        # Input controls (dial, gesture sensors)
└── themes/          # Light/Dark mode definitions
```

**Key QML Bindings**:
1. **WebSocketClient** (C++ ↔ QML):
   - Sends commands: `sendCommand("service/action", {...})`
   - Receives events: `onEventReceived(topic, payload)`
2. **Theme/i18n**:
   - Automatic light/dark mode switching
   - Multi-language text binding
3. **Settings**:
   - Persistent user preferences
   - Reactive UI updates on setting changes

**Scenario: Media Player Page**
```
QML Loads → SettingsRegistry reads saved theme → applies Theme colors

User plays song:
1. User taps play button
2. QML emits: sendCommand("media/play", {trackId: "..."})
3. WebSocketClient sends to core
4. Media service processes
5. Service publishes: "media/playback_started"
6. WebSocket broadcasts to UI
7. QML slot receives event
8. UI updates: playback icon animated, progress bar active

Scenario: Theme toggle
───────────────────────
1. User toggles dark/light mode
2. Theme binding updates: isDarkMode = !isDarkMode
3. All colors in ui/ re-bind (automatic)
4. SettingsRegistry persists choice
5. On app restart, saved theme is loaded
```

### 3.2 Responsive Design & Gesture Support

**Design Philosophy**:
- Minimum touch target: 48dp (for driving safety)
- Maximum response time: 100ms (perceived instant)
- Support for steering wheel button events
- One-handed operation possible

**Gesture Support**:
- Tap: Select item, toggle
- Long-press: Context menu
- Swipe: Navigate between pages
- Gesture wheel (rotating gesture): Volume/seek control

---

## 4. Slim UI Architecture (ui-slim/)

### 4.1 Headless Mode / Minimal Display Support

**Purpose**: Support for:
- Systems without X11/Wayland
- Virtual displays (VNC, eglfs)
- Minimal resource environments

**Differences from ui/**:
- Reduced animation complexity
- Simpler rendering pipeline
- Smaller QML asset footprint
- Support for 800x480 minimum resolution

**Scenario: Raspberry Pi with VNC Display**
```
Device Setup:
- Raspberry Pi 4 (4GB RAM, armhf architecture)
- No native display connected
- VNC server running on device (port 5900)

Startup:
1. OS boots
2. Crankshaft core starts
3. ui-slim starts with: QT_QPA_PLATFORM=vnc:size=800x480
4. QML renders to virtual framebuffer
5. VNC server streams framebuffer over network
6. Development PC connects via VNC client (e.g., RealVNC, TightVNC)
7. Developer sees UI in VNC window

Benefits:
- Full UI accessible without HDMI
- Network-accessible interface for testing
- Can run CI/CD tests in headless environment
```

---

## 5. HAL Documentation

### 5.1 Audio HAL Pipeline

**File**: `core/hal/multimedia/AudioHAL.h`, `AudioHAL.cpp`

**Initialization Flow**:
```cpp
// 1. Create HAL instance
auto audioHal = new AudioHAL();

// 2. Configure audio route
audioHal->setRoute(AudioHAL::AudioRoute::Speaker);

// 3. Set audio parameters
audioHal->setAudioConfig({
    sampleRate: 48000,      // 48kHz (professional audio standard)
    channels: 2,            // Stereo
    bitDepth: 16,           // 16-bit PCM
    bufferSize: 4096        // Low-latency: ~85ms at 48kHz
});

// 4. Start audio playback
audioHal->startPlayback();

// 5. Feed audio data
QByteArray audioData = ...;  // PCM frames
audioHal->pushAudio(audioData);

// 6. Volume control
audioHal->setVolume(70);     // 0-100%
```

**Scenario: Audio Device Hotplug**
```
Bluetooth speaker connected:
1. BluetoothHAL detects connection
2. Publishes: "bluetooth/device_connected" {device: "HeadsetX"}
3. AudioService subscribes to this event
4. Calls: audioHal->setRoute(Bluetooth)
5. ALSA reconfigures audio routing
6. If playback was active:
   - Audio continues on new device (seamless)
7. If no playback active:
   - Next playback uses new device

Scenario: Audio underrun (buffer insufficient)
──────────────────────────────────────────────
1. AudioHAL detects ALSA underrun
2. Publishes: "audio/underrun" {timestamp, duration: 50ms}
3. Service logs warning
4. If playback was streaming (e.g., Bluetooth):
   - Request retransmit of lost frames
5. Resume playback smoothly
6. May reduce bitrate to prevent future underruns
```

### 5.2 Video HAL Pipeline

**File**: `core/hal/multimedia/VideoHAL.h`

**Decoding Architecture** (GStreamer-based):
```
Input Stream (H.264 NALUs) 
  ↓
┌─────────────────────────────────────┐
│ GStreamerVideoDecoder               │
│ ├─ Parse H.264 bitstream            │
│ ├─ Detect keyframes for seeking     │
│ ├─ Adapt bitrate based on CPU load  │
│ └─ Hardware acceleration (if avail) │
└─────────────────────────────────────┘
  ↓
Decoded YUV frames (I420 format)
  ↓
┌─────────────────────────────────────┐
│ Qt Video Output                      │
│ ├─ Convert YUV→RGB (GPU accelerated)│
│ ├─ Render to QML VideoOutput        │
│ └─ Synchronise to display refresh   │
└─────────────────────────────────────┘
  ↓
Display (60fps target)
```

**Scenario: Adaptive Bitrate Streaming**
```
Initial state: 1080p 60fps 5Mbps

CPU load increases (e.g., encoding/recording):
1. Decoder measures frame drop rate
2. If drop rate > threshold (e.g., 5%):
   - Reduce resolution: 1080p → 720p
   - Maintain 60fps initially
3. Monitor again:
   - If still dropping frames: reduce framerate 60→30fps
   - Keep bitrate low to prevent buffering

Network improves:
1. Decoder detects stable low frame loss
2. Gradually increase bitrate
3. Request keyframe from encoder
4. Resume higher resolution/framerate

Benefit: Seamless playback under variable conditions
```

---

## 6. Extension Framework

### 6.1 Plugin Architecture

**File**: `core/extensions/` (directory structure)

**Plugin Lifecycle**:
```
1. DISCOVERY (scan /usr/share/crankshaft/extensions/)
   └─ Find manifest.json files
      ├─ Parse metadata (name, version, dependencies)
      └─ Register available plugins

2. LOADING (user selects extension)
   └─ Load plugin library
      ├─ dlopen() or Qt plugin system
      ├─ Verify signature/permissions
      └─ Initialise plugin instance

3. ACTIVATION (extension starts)
   └─ Call plugin->initialize()
      ├─ Register event subscriptions
      ├─ Create UI components
      └─ Start background tasks

4. RUNNING (plugin operates)
   └─ Process events, render UI
      ├─ May communicate with core services
      └─ May communicate with other extensions

5. DEACTIVATION (user stops extension)
   └─ Call plugin->shutdown()
      ├─ Save state
      ├─ Release resources
      └─ Unsubscribe from events

6. UNLOADING
   └─ Unload plugin library
      └─ Free memory
```

**Scenario: User Installs Spotify Extension**
```
1. User opens "Extension Store" in UI
2. User searches for "Spotify"
3. User clicks "Install"
4. Core downloads extension package
5. Package extracted to: /opt/crankshaft/extensions/spotify/
6. Manifest verified
7. Extension loaded into extension manager
8. User sees "Spotify" in app drawer
9. User taps "Spotify"
10. Extension initializes:
    - Loads QML UI from plugin
    - Connects to Spotify API
    - Subscribes to: media/play_start, media/pause
    - Publishes: spotify/authenticated
11. QML shows login screen
12. User authenticates
13. Spotify extension is now active
14. User can see Spotify playlists, play music
```

### 6.2 Security Model

**Sandbox & Permissions**:
- Extensions run in same process (for performance)
- EventBus access is filtered:
  - Extensions declare required topics in manifest
  - Core enforces topic access (whitelist model)
- File system access limited to plugin-specific directory
- Network access restricted (configurable)

**Example Manifest**:
```json
{
  "id": "com.spotify.crankshaft",
  "name": "Spotify",
  "version": "1.0.0",
  "publisher": "Spotify AB",
  "requiredEventTopics": [
    "media/play_start",
    "media/pause"
  ],
  "publishedEventTopics": [
    "spotify/authenticated",
    "spotify/playlist_updated"
  ],
  "permissions": {
    "network": true,
    "filesystem": "/opt/crankshaft/extensions/spotify/data/",
    "bluetooth": false
  }
}
```

---

## 7. Key Design Patterns & Rationale

### 7.1 Event-Driven Architecture (Why?)

**Pattern**: Publish-Subscribe (Pub/Sub) via EventBus

**Rationale**:
1. **Loose Coupling**: Services don't know about each other
2. **Scalability**: New services added without modifying existing code
3. **Testability**: Mock event streams for unit testing
4. **Performance**: Events batched, processed asynchronously
5. **Real-time UI**: Automatic UI updates when data changes

**Alternative Considered**: Direct method calls
- ❌ Tight coupling between services
- ❌ Synchronous (blocks caller)
- ❌ Hard to extend

### 7.2 HAL Abstraction (Why?)

**Pattern**: Hardware Abstraction Layer (HAL)

**Rationale**:
1. **Portability**: Same code runs on different hardware
2. **Testability**: Mock HAL for unit tests (no hardware needed)
3. **Performance**: HW-specific optimizations transparent to services
4. **Maintainability**: Changes to one HW platform don't break others

**Example**: AudioHAL on different platforms
```
AudioHAL (abstract)
├─ ALSA implementation (Linux/Raspberry Pi)
├─ PulseAudio implementation (desktop Linux)
├─ Mock implementation (unit tests)
└─ Future: JACK, ASIO, CoreAudio
```

### 7.3 Profile-Based Configuration (Why?)

**Pattern**: Device Profiles (HostProfile, DeviceProfile)

**Rationale**:
1. **Multi-Device Support**: Same code on car + Raspberry Pi + laptop
2. **Runtime Switching**: Change profiles without restart
3. **Scenario Testing**: Quick switch between configurations
4. **Performance Tuning**: Different profiles for different hardware

**Example Profiles**:
```
automotive_raspberry_pi.json:
- 1024x600 display
- 1 core for services
- 2 cores for UI
- BT, WiFi, CAN enabled
- Android Auto enabled

laptop_development.json:
- 1920x1080 display
- All cores available
- Simulated CAN bus
- Android Auto simulated
```

---

## 8. Documentation Checklist

### Core Components (core/)
- [x] EventBus: documented with scenario examples
- [x] WebSocketServer: documented with connection lifecycle
- [x] ServiceManager: documented with lifecycle states
- [ ] Extension framework: NEEDS ENHANCEMENT
- [ ] HAL transport layer: NEEDS ENHANCEMENT
- [ ] Multimedia pipelines: NEEDS ENHANCEMENT

### UI Components (ui/)
- [x] Main architecture: QML + C++ binding
- [ ] Component library: NEEDS DOCUMENTATION
- [ ] State management: NEEDS DOCUMENTATION
- [ ] Gesture handling: NEEDS DOCUMENTATION
- [ ] i18n/theming: NEEDS DOCUMENTATION

### Slim UI (ui-slim/)
- [ ] Headless mode support: NEEDS DOCUMENTATION
- [ ] Platform support (eglfs, vnc): NEEDS DOCUMENTATION
- [ ] Resource constraints: NEEDS DOCUMENTATION

### HAL Layer (core/hal/)
- [ ] Audio HAL: NEEDS ENHANCEMENT
- [ ] Video HAL: NEEDS ENHANCEMENT
- [ ] Transport layer: NEEDS DOCUMENTATION
- [ ] Wireless HAL: NEEDS DOCUMENTATION

---

## 9. Recommended Documentation Enhancements

### Priority 1 (Critical)
1. **core/extensions/**: Add comprehensive plugin system documentation
   - [ ] Plugin manifest format specification
   - [ ] Plugin development tutorial
   - [ ] Example plugin (minimal, reference)
   - [ ] Security model and permissions system

2. **core/hal/transport/**: Document protocol handling
   - [ ] UART protocol specification
   - [ ] CAN bus frame format
   - [ ] Error handling and recovery
   - [ ] Testing approach for transport layer

3. **core/hal/multimedia/**: Enhance streaming documentation
   - [ ] Audio pipeline scenario examples
   - [ ] Video latency optimization guide
   - [ ] Codec selection rationale
   - [ ] Error handling (underrun, corruption)

### Priority 2 (Important)
1. **ui/**: Component documentation
   - [ ] Component API documentation
   - [ ] State management patterns
   - [ ] Gesture handling implementation
   - [ ] Performance profiling guide

2. **ui-slim/**: Platform support documentation
   - [ ] Headless setup guide
   - [ ] VNC display configuration
   - [ ] eglfs platform specifics
   - [ ] Resource constraints and optimization

### Priority 3 (Nice to have)
1. **Deployment scenarios**: Multi-display setup guide
2. **Integration tests**: Testing extension framework
3. **Performance profiling**: Bottleneck identification

---

## 10. Code Examples

### Example 1: EventBus Usage

```cpp
// In AndroidAutoService
void AndroidAutoService::onDeviceConnected() {
    // Prepare event payload with relevant context
    QVariantMap payload;
    payload["deviceId"] = m_device.id;
    payload["deviceName"] = m_device.name;
    payload["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    
    // Publish event via EventBus singleton
    // All subscribers (UI, other services) receive notification
    EventBus::instance().publish("android_auto/device_connected", payload);
}

// In UI (QML)
WebSocketClient.onEventReceived(function(topic, payload) {
    if (topic === "android_auto/device_connected") {
        console.log("Device connected:", payload.deviceName);
        statusLabel.text = "Ready to project";
        startButton.enabled = true;
    }
});
```

### Example 2: ServiceManager Usage

```cpp
// In main.cpp startup
ServiceManager serviceManager(&profileManager, &app);

// Load services based on active profile
if (!serviceManager.startAllServices()) {
    Logger::instance().warning("No services started successfully");
}

// Later: User switches profile
void onProfileSwitched(const HostProfile& newProfile) {
    // Gracefully reload all services
    serviceManager.reloadServices();
}

// Specific service control from UI
void onUserRequestsServiceRestart(const QString& serviceName) {
    serviceManager.restartService(serviceName);
}
```

### Example 3: WebSocket Message Handler

```cpp
// In WebSocketServer::onMessageReceived()
void WebSocketServer::onMessageReceived(const QString& message) {
    // Parse JSON message from UI
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    QJsonObject obj = doc.object();
    
    QString action = obj["action"].toString();
    QString service = obj["service"].toString();
    
    // Scenario: User requests AndroidAuto restart from UI
    if (action == "restart_service" && service == "AndroidAuto") {
        m_serviceManager->restartService("AndroidAuto");
        
        // Publish status update back to UI
        QVariantMap response;
        response["status"] = "restarting";
        response["service"] = "AndroidAuto";
        response["timestamp"] = QDateTime::currentMSecsSinceEpoch();
        
        broadcastEvent("service/status_update", response);
    }
}
```

### Example 4: HAL Audio Route Switching

```cpp
// In AudioService::onAudioRouteChange()
void AudioService::handleBluetoothConnection() {
    // Event received: bluetooth device connected
    
    // Step 1: Pause current playback (if active)
    if (m_audioHal->isPlaying()) {
        m_audioHal->pause();
    }
    
    // Step 2: Switch ALSA route to Bluetooth device
    m_audioHal->setRoute(AudioHAL::AudioRoute::Bluetooth);
    
    // Step 3: Reconfigure audio parameters if needed
    m_audioHal->setAudioConfig({
        sampleRate: 48000,  // Bluetooth supports 48kHz
        channels: 2,
        bitDepth: 16
    });
    
    // Step 4: Resume playback on new device
    if (wasPlaying) {
        m_audioHal->play();
    }
    
    // Step 5: Publish event for UI update
    QVariantMap payload;
    payload["route"] = "bluetooth";
    payload["device"] = bluetoothDeviceName;
    EventBus::instance().publish("audio/route_changed", payload);
}
```

---

## 11. Testing & Validation

### Unit Testing Documentation
Each module should include unit tests demonstrating:
1. Happy path (normal operation)
2. Error scenarios (invalid input, device unavailable)
3. Edge cases (boundary conditions, race conditions)

### Integration Testing
Services should be tested together:
1. AndroidAuto + MediaPipeline
2. WiFi + Bluetooth + Audio routing
3. Extension framework + EventBus

### Scenario Testing
Real-world scenarios documented and tested:
1. Cold start performance
2. Projection start/stop cycles
3. Device disconnection recovery
4. Multi-display coordination

---

## 12. Conclusion

This audit identifies comprehensive documentation for:
- ✅ **Core architecture**: EventBus, ServiceManager, WebSocketServer, ProfileManager
- ✅ **Main services**: AndroidAuto, Audio, Video, Transport
- ✅ **UI architecture**: QML bindings, theme system, responsive design
- ⚠️ **Extension framework**: Needs policy/guideline documentation
- ⚠️ **HAL specifics**: Transport, multimedia pipelines need more detail
- ⚠️ **Slim UI**: Headless mode needs platform-specific documentation

### Next Steps
1. Enhance extension framework documentation
2. Add HAL subsystem guides
3. Create component library API docs
4. Develop scenario testing guides
5. Add integration testing documentation

---

**End of Report**
