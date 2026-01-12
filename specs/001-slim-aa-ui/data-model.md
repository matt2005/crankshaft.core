# Data Model: Slim AndroidAuto UI

**Feature**: Slim AndroidAuto UI  
**Created**: 2026-01-10  
**Phase**: 1 - Design

## Overview

This document defines the data entities and their relationships for the Slim AndroidAuto UI application.

**IMPORTANT**: Most entities map directly to existing core service types. The slim UI facades expose these core types to QML rather than creating duplicate data structures.

---

## Entity 1: SettingsConfiguration

**Purpose**: User preferences for slim UI

**Core Mapping**: Maps to `PreferencesService` key-value entries with `slim_ui.` prefix

### Attributes (stored as PreferencesService keys)

| Attribute | Type | Range/Values | Default | PreferencesService Key |
|-----------|------|--------------|---------|------------------------|
| `display_brightness` | Integer | 0-100 | 50 | `slim_ui.display.brightness` |
| `audio_volume` | Integer | 0-100 | 50 | `slim_ui.audio.volume` |
| `connection_preference` | String | "USB", "WIRELESS" | "USB" | `slim_ui.connection.preference` |
| `theme_mode` | String | "LIGHT", "DARK" | "DARK" | `slim_ui.theme.mode` |
| `last_connected_device_id` | String | Any | "" | `slim_ui.device.lastConnected` |

### Validation Rules

- `display_brightness`: Must be 0-100 inclusive (validated by PreferencesFacade setter)
- `audio_volume`: Must be 0-100 inclusive (validated by PreferencesFacade setter)
- `connection_preference`: Must be "USB" or "WIRELESS"
- `theme_mode`: Must be "LIGHT" or "DARK"

### Storage Format

**Backend**: SQLite database managed by core's `PreferencesService`  
**Location**: Managed by core (typically `~/.local/share/crankshaft/preferences.db`)  
**Recovery**: Core service handles corruption automatically (returns defaults on error)

### State Transitions

- **On Load**: `PreferencesFacade::loadSettings()` reads all keys from core
  - Missing keys → Core returns provided defaults
  - Corrupted database → Core logs error, returns defaults
- **On Change**: `PreferencesFacade::set*()` calls `m_corePrefs->set(key, value)` - auto-persisted
- **On Application Exit**: Core service ensures all writes flushed

### Relationships

- **Exposed by**: `PreferencesFacade` C++ facade class
- **Backed by**: core's `PreferencesService` (SQLite)
- **Modified by**: `SettingsPanel` QML UI component
- **Referenced by**: `AndroidAutoFacade` (for connection preference), QML theme system

---

## Entity 2: AndroidAutoConnection

**Purpose**: Represents active or attempted connection to AndroidAuto device

**Core Mapping**: Maps to `AndroidAutoService::ConnectionState` enum and `AndroidDevice` struct

### Attributes (from core types)

| Attribute | Type | Values | Core Source |
|-----------|------|--------|-------------|
| `device_id` | String | MAC address format | `AndroidDevice::id` |
| `device_name` | String | Any | `AndroidDevice::name` |
| `connection_type` | String | "USB", "WIRELESS" | `AndroidDevice::connectionType` |
| `connection_state` | String | DISCONNECTED, SEARCHING, CONNECTING, AUTHENTICATING, SECURING, CONNECTED, DISCONNECTING, ERROR | `AndroidAutoService::ConnectionState` (enum) |
| `connected_timestamp` | DateTime | ISO 8601 | Tracked by facade from EventBus |
| `last_error` | String | Any | From EventBus "aa.error" events |
| `video_stream_active` | Boolean | true/false | From EventBus "aa.video.started/stopped" |
| `audio_stream_active` | Boolean | true/false | From EventBus "aa.audio.started/stopped" |

### Validation Rules

- All validation performed by core's `AndroidAutoService`
- Facade only translates types (enum→string) for QML

### State Machine

**Core Service States** (from `AndroidAutoService::ConnectionState`):

```
[SEARCHING] ─(device detected)─> [CONNECTING]
[CONNECTING] ─(handshake complete)─> [CONNECTED]
[CONNECTING] ─(handshake failed)─> [ERROR]
[CONNECTED] ─(device disconnected)─> [DISCONNECTED]
[CONNECTED] ─(connection lost)─> [ERROR]
[DISCONNECTED] ─(reconnect attempt)─> [CONNECTING]
[ERROR] ─(retry)─> [CONNECTING]
[ERROR] ─(timeout)─> [DISCONNECTED]
```

```
DISCONNECTED ←→ SEARCHING → CONNECTING → AUTHENTICATING → SECURING → CONNECTED
                    ↓            ↓             ↓             ↓            ↓
                  ERROR ←────────┴─────────────┴─────────────┴────────────┘
                    ↓
              DISCONNECTING → DISCONNECTED
```

**Managed by**: Core's `AndroidAutoService` - facade only observes state changes via EventBus

### Relationships

- **Exposed by**: `AndroidAutoFacade` C++ facade class
- **Managed by**: core's `AndroidAutoService`
- **Observed by**: `ConnectionStatusView` QML component
- **Event Source**: core's EventBus topics: `aa.connection.stateChanged`, `aa.error`, `aa.video.*`, `aa.audio.*`

---

## Entity 3: DetectedDevice

**Purpose**: Represents AndroidAuto-compatible device discovered but not yet connected

**Core Mapping**: Corresponds to `AndroidDevice` struct from core's `AndroidAutoService`

### Attributes (from core types)

| Attribute | Type | Core Source | Description |
|-----------|------|-------------|-------------|
| `device_id` | String | `AndroidDevice::id` | Unique device identifier |
| `device_name` | String | `AndroidDevice::name` | Human-readable name from device |
| `connection_type` | String | `AndroidDevice::connectionType` | "USB" or "WIRELESS" |
| `signal_strength` | Integer | `AndroidDevice::signalStrength` | 0-100 (for wireless), -1 for USB |
| `is_last_connected` | Boolean | Facade comparison with `slim_ui.device.lastConnected` | Whether this was the last successfully connected device |
| `detected_timestamp` | DateTime | Tracked by facade | When device was first detected in current session |

### Validation Rules

- All validation performed by core's `AndroidAutoService`
- Facade adds `is_last_connected` by comparing with PreferencesService

### Relationships

- **Source**: core's `AndroidAutoService::getDetectedDevices()`
- **Exposed by**: `AndroidAutoFacade::getDetectedDevices()` Q_INVOKABLE method
- **Displayed in**: `DeviceSelectionDialog` QML component
- **Prioritized by**: `is_last_connected` flag from preferences

---

## Entity 4: VideoFrame

**Purpose**: Single frame of AndroidAuto video projection

**Core Mapping**: Handled entirely by core's `MediaPipeline` - slim UI only displays via Qt VideoOutput

### Attributes (not directly exposed to slim UI)

| Attribute | Type | Description |
|-----------|------|-------------|
| `frame_data` | ByteArray | H.264 encoded frame data (handled by core) |
| `width` | Integer | Frame width in pixels (handled by core) |
| `height` | Integer | Frame height in pixels (handled by core) |
| `timestamp` | Integer | Presentation timestamp (handled by core) |
| `format` | Enum | H264, RGB, YUV (varies by decode stage) |

### Validation Rules

- `width`, `height`: Must be positive integers
- `timestamp`: Must be monotonically increasing
- `frame_data`: Must not be null

### Relationships

- Produced by: AASDK library
- Consumed by: `AAVideoFrameProvider` → Qt VideoSink
- Rendered in: `AAProjectionView` QML component

### Processing Pipeline

1. AASDK produces H.264 frame
2. Decoder converts to RGB/YUV
3. Qt VideoSink renders to QML surface
4. User sees projection

---

## Entity 5: AudioBuffer

**Purpose**: PCM audio data for playback or recording

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `pcm_data` | ByteArray | Raw PCM audio samples |
| `sample_rate` | Integer | Samples per second (typically 48000) |
| `channels` | Integer | Number of audio channels (1=mono, 2=stereo) |
| `bit_depth` | Integer | Bits per sample (typically 16) |
| `direction` | Enum | PLAYBACK, RECORDING | Data flow direction |

### Validation Rules

- `pcm_data`: Must not be null, must be multiple of (channels * bit_depth / 8)
- `sample_rate`: Typically 48000, must match system capability
- `channels`: 1 or 2
- `bit_depth`: 16 or 24

### Relationships

- Produced by: AASDK (playback), system microphone (recording)
- Consumed by: Qt Audio Sink (playback), AASDK (recording)
- Managed by: `AudioHandler` C++ class

### Processing Flow

**Playback**: AASDK → AudioBuffer → Qt Audio Sink → System Audio Device  
**Recording**: System Microphone → Qt Audio Source → AudioBuffer → AASDK

---

## Entity 6: TouchEvent

**Purpose**: Touch input event from user interaction

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `x` | Integer | X coordinate in pixels |
| `y` | Integer | Y coordinate in pixels |
| `event_type` | Enum | PRESS, MOVE, RELEASE | Type of touch action |
| `timestamp` | Integer | Event timestamp (milliseconds) |
| `pressure` | Float | Touch pressure 0.0-1.0 (if supported) |

### Validation Rules

- `x`, `y`: Must be within display bounds
- `event_type`: Must be valid enum
- `pressure`: 0.0-1.0 if present, null if not supported

### Relationships

- Captured by: QML MouseArea in `AAProjectionView`
- Converted by: `AAConnectionManager`
- Sent to: AASDK → connected phone

### Processing Pipeline

1. User touches `AAProjectionView` QML surface
2. QML MouseArea captures event
3. `AAConnectionManager` converts to AASDK format
4. Transmitted to connected Android device
5. AndroidAuto app on phone processes touch

---

## Entity 7: LogEntry

**Purpose**: Structured log event for observability

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `timestamp` | DateTime | ISO 8601 timestamp |
| `level` | Enum | DEBUG, INFO, WARNING, ERROR | Log severity |
| `category` | String | Component identifier (e.g., "aa_connection", "settings") |
| `message` | String | Human-readable message |
| `context` | JSON Object | Structured context data |

### Validation Rules

- `timestamp`: Must be valid ISO 8601
- `level`: Must be valid enum
- `category`: Should follow namespace pattern
- `message`: Must not be empty

### Key Categories

- `aa_connection`: Connection state changes, device detection
- `settings`: Configuration changes, corruption recovery
- `audio`: Audio routing, backend detection
- `video`: Frame processing, rendering issues
- `system`: Application lifecycle, platform events

### Example Log Entries

```json
{
  "timestamp": "2026-01-10T14:32:11.234Z",
  "level": "INFO",
  "category": "aa_connection",
  "message": "AndroidAuto device connected",
  "context": {
    "device_id": "device:12:34:56:78:90:ab",
    "device_name": "John's Pixel",
    "connection_type": "USB"
  }
}
```

```json
{
  "timestamp": "2026-01-10T14:35:22.456Z",
  "level": "WARNING",
  "category": "settings",
  "message": "Settings file corrupted, resetting to factory defaults",
  "context": {
    "file_path": "/home/pi/.config/crankshaft/slim-ui-settings.json",
    "error": "JSON parse error at line 5"
  }
}
```

### Relationships

- Generated by: All components
- Written to: stdout (JSON format)
- Consumed by: System logging (journald, syslog) or external log aggregation

---

## Data Flow Diagrams

### Application Startup Flow

```
[Load Settings] → [Read Config File]
    ├─ Success → [Apply Settings] → [Start AA Discovery]
    └─ Failure → [Log Error] → [Reset to Defaults] → [Start AA Discovery]

[Start AA Discovery] → [Enumerate Devices]
    ├─ No devices → [Show "Connect Device" Prompt]
    ├─ One device → [Auto-connect] → [CONNECTING State]
    └─ Multiple devices → [Show Device Selection Dialog]

[Device Selected] → [Initiate Connection] → [CONNECTING State]
    ├─ Success → [CONNECTED State] → [Start Video/Audio Streams]
    └─ Failure → [ERROR State] → [Show Error Message]
```

### Settings Change Flow

```
[User Adjusts Setting] → [SettingsPanel QML]
    → [Update SettingsManager]
    → [Validate Value]
    → [Apply Immediately]
    → [Write to Config File]
    → [Log Change]
```

### Device Disconnection Flow

```
[Device Disconnect Event] → [AAConnectionManager]
    → [DISCONNECTED State]
    → [Stop Video/Audio Streams]
    → [Log Disconnection]
    → [Show "Device Disconnected" Prompt]
    → [Auto-reconnect if device still present]
```

---

## Summary

This data model defines 7 core entities:
1. **SettingsConfiguration** - User preferences (persistent)
2. **AndroidAutoConnection** - Active connection state (runtime)
3. **DetectedDevice** - Discovered devices (runtime)
4. **VideoFrame** - Projection video data (streaming)
5. **AudioBuffer** - Audio data (streaming)
6. **TouchEvent** - User input (events)
7. **LogEntry** - Observability data (logging)

All entities have clear validation rules, state transitions where applicable, and defined relationships. The data flow diagrams show how entities interact during key operations.
