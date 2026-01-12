# Contract: AndroidAutoFacade

**Service**: AndroidAutoFacade  
**Type**: C++ QObject exposed to QML (facade pattern)  
**File**: `AndroidAutoFacade.h` / `AndroidAutoFacade.cpp`

## Purpose

QML bridge to core's `AndroidAutoService`. Exposes AndroidAuto connection state, device management, and control methods to QML layer. This is a thin facade - all business logic is delegated to the core `AndroidAutoService`.

**Architecture**: `QML ↔ AndroidAutoFacade ↔ core::AndroidAutoService`

---

## Exposed Properties (Q_PROPERTY)

### `connectionState` : QString
- **Values**: "DISCONNECTED", "SEARCHING", "CONNECTING", "AUTHENTICATING", "SECURING", "CONNECTED", "DISCONNECTING", "ERROR"
- **Default**: "DISCONNECTED"
- **Description**: Current connection state (mapped from core::AndroidAutoService::ConnectionState)
- **Writable**: No (managed by core service)
- **Notify Signal**: `connectionStateChanged(QString)`
- **Implementation**: Reads from `m_coreService->getConnectionState()`, converts enum to string

### `connectedDeviceName` : QString
- **Default**: ""
- **Description**: Human-readable name of currently connected device
- **Writable**: No
- **Notify Signal**: `connectedDeviceNameChanged(QString)`
- **Implementation**: Reads from `m_coreService->getConnectedDevice().name`

### `connectedDeviceId` : QString
- **Default**: ""
- **Description**: Unique identifier of currently connected device
- **Writable**: No
- **Notify Signal**: `connectedDeviceIdChanged(QString)`
- **Implementation**: Reads from `m_coreService->getConnectedDevice().id`

### `connectionType` : QString
- **Values**: "", "USB", "WIRELESS"
- **Default**: ""
- **Description**: Type of active connection (empty if not connected)
- **Writable**: No
- **Notify Signal**: `connectionTypeChanged(QString)`
- **Implementation**: Reads from `m_coreService->getConnectedDevice().connectionType`

### `lastError` : QString
- **Default**: ""
- **Description**: Last error message (empty if no error)
- **Writable**: No
- **Notify Signal**: `lastErrorChanged(QString)`
- **Implementation**: Subscribes to core::EventBus for "aa.error" events

### `isVideoActive` : bool
- **Default**: false
- **Description**: Whether video projection is actively streaming
- **Writable**: No
- **Notify Signal**: `isVideoActiveChanged(bool)`
- **Implementation**: Subscribes to core::EventBus for "aa.video.started" / "aa.video.stopped" events

### `isAudioActive` : bool
- **Default**: false
- **Description**: Whether audio is actively streaming
- **Writable**: No
- **Notify Signal**: `isAudioActiveChanged(bool)`
- **Implementation**: Subscribes to core::EventBus for "aa.audio.started" / "aa.audio.stopped" events

---

## Exposed Methods (Q_INVOKABLE)

### `void startDiscovery()`
**Description**: Begin searching for AndroidAuto-compatible devices  
**Returns**: void  
**Side Effects**:
- Delegates to `m_coreService->startDeviceDiscovery()`
- Sets `connectionState` to "SEARCHING"
- Emits `devicesDetected` signal when core service finds devices
- Automatically connects if single device found (after 3s delay)
- Shows device selection dialog if multiple devices found

**Implementation**: 
```cpp
m_coreService->startDeviceDiscovery();
```

**Example QML Usage**:
```qml
Component.onCompleted: {
    aaFacade.startDiscovery()
}
```

### `void connectToDevice(QString deviceId)`
**Description**: Initiate connection to specific device  
**Parameters**:
- `deviceId`: Unique device identifier
**Returns**: void  
**Side Effects**:
- Delegates to `m_coreService->connectToDevice(deviceId)`
- Sets `connectionState` to "CONNECTING"
- On success: transitions to "CONNECTED", emits `connectionEstablished`
- On failure: transitions to "ERROR", emits `connectionFailed`
- Core service logs connection attempt and result

**Implementation**:
```cpp
m_coreService->connectToDevice(deviceId.toStdString());
```

**Example QML Usage**:
```qml
DeviceSelectionDialog {
    onDeviceSelected: {
        connectionManager.connectToDevice(deviceId)
    }
}
```

### `void disconnect()`
**Description**: Disconnect from currently connected device  
**Returns**: void  
**Side Effects**:
- Gracefully shuts down AASDK connection
- Stops video and audio streams
- Sets `connectionState` to "DISCONNECTED"
- Clears `connectedDeviceName`, `connectedDeviceId`, `connectionType`
- Logs disconnection event

**Example QML Usage**:
```qml
Button {
    text: "Disconnect"
    onClicked: connectionManager.disconnect()
}
```

### `void sendTouchEvent(QString eventType, int x, int y, real pressure)`
**Description**: Forward touch input to connected AndroidAuto device  
**Parameters**:
- `eventType`: "PRESS", "MOVE", or "RELEASE"
- `x`: X coordinate in pixels
- `y`: Y coordinate in pixels
- `pressure`: Touch pressure 0.0-1.0 (optional, default 1.0)
**Returns**: void  
**Precondition**: Must be in "CONNECTED" state  
**Side Effects**:
- Converts to AASDK touch event format
- Transmits to connected device
- No-op if not connected

**Example QML Usage**:
```qml
MouseArea {
    anchors.fill: parent
    onPressed: connectionManager.sendTouchEvent("PRESS", mouse.x, mouse.y, 1.0)
    onPositionChanged: connectionManager.sendTouchEvent("MOVE", mouse.x, mouse.y, 1.0)
    onReleased: connectionManager.sendTouchEvent("RELEASE", mouse.x, mouse.y, 1.0)
}
```

### `void retryConnection()`
**Description**: Retry connection after ERROR state  
**Returns**: void  
**Side Effects**:
- Resets error state
- Attempts reconnection to last attempted device
- Sets `connectionState` to "CONNECTING"

**Example QML Usage**:
```qml
Button {
    text: "Retry"
    visible: connectionManager.connectionState === "ERROR"
    onClicked: connectionManager.retryConnection()
}
```

---

## Signals

### `connectionStateChanged(QString state)`
**Emitted When**: Connection state changes  
**Parameters**: New state ("SEARCHING", "CONNECTING", "CONNECTED", "DISCONNECTED", "ERROR")

### `connectedDeviceNameChanged(QString name)`
**Emitted When**: Connected device name changes  
**Parameters**: Device name or empty string

### `connectedDeviceIdChanged(QString id)`
**Emitted When**: Connected device ID changes  
**Parameters**: Device ID or empty string

### `connectionTypeChanged(QString type)`
**Emitted When**: Connection type changes  
**Parameters**: "USB", "WIRELESS", or empty string

### `lastErrorChanged(QString error)`
**Emitted When**: Error occurs  
**Parameters**: Error message string

### `isVideoActiveChanged(bool active)`
**Emitted When**: Video streaming state changes  
**Parameters**: true if video active, false otherwise

### `isAudioActiveChanged(bool active)`
**Emitted When**: Audio streaming state changes  
**Parameters**: true if audio active, false otherwise

### `devicesDetected(QVariantList devices)`
**Emitted When**: Devices discovered during SEARCHING state  
**Parameters**: List of device objects (see DeviceInfo structure below)  
**Use Case**: Trigger device selection dialog if multiple devices

**Example QML Usage**:
```qml
Connections {
    target: connectionManager
    function onDevicesDetected(devices) {
        if (devices.length > 1) {
            deviceSelectionDialog.devices = devices
            deviceSelectionDialog.open()
        }
    }
}
```

### `connectionEstablished()`
**Emitted When**: Connection successfully established  
**Use Case**: Show success notification, hide connection prompts

### `connectionFailed(QString reason)`
**Emitted When**: Connection attempt fails  
**Parameters**: Failure reason string  
**Use Case**: Display error message to user

### `deviceDisconnected(QString reason)`
**Emitted When**: Connected device unexpectedly disconnects  
**Parameters**: Disconnection reason ("USER_INITIATED", "CONNECTION_LOST", "DEVICE_ERROR")  
**Use Case**: Show reconnection prompt

---

## Data Types

### DeviceInfo (QVariantMap in QML)
```cpp
struct DeviceInfo {
    QString deviceId;           // Unique identifier
    QString deviceName;         // Human-readable name
    QString connectionType;     // "USB" or "WIRELESS"
    int signalStrength;        // 0-100 for wireless, -1 for USB
    bool isLastConnected;      // true if this was last connected device
};
```

**Example QML Access**:
```qml
ListView {
    model: devices
    delegate: ItemDelegate {
        text: modelData.deviceName + " (" + modelData.connectionType + ")"
        highlighted: modelData.isLastConnected
        onClicked: connectionManager.connectToDevice(modelData.deviceId)
    }
}
```

---

## State Machine

```
SEARCHING
  ├─ No devices found → Stay in SEARCHING
  ├─ One device found → Auto-connect after 3s → CONNECTING
  └─ Multiple devices found → Emit devicesDetected → Stay in SEARCHING (waiting for user selection)

CONNECTING
  ├─ Handshake successful → CONNECTED
  └─ Handshake failed → ERROR

CONNECTED
  ├─ User disconnect() → DISCONNECTED
  ├─ Device disconnected → DISCONNECTED + emit deviceDisconnected
  └─ Connection error → ERROR + emit deviceDisconnected

DISCONNECTED
  ├─ retryConnection() → CONNECTING
  └─ startDiscovery() → SEARCHING

ERROR
  ├─ retryConnection() → CONNECTING
  └─ startDiscovery() → SEARCHING
```

---

## Error Handling

### Device Not Found
- Stay in SEARCHING state
- Log INFO level
- Display "Waiting for device" prompt in UI

### Connection Timeout
- Transition to ERROR state
- Set `lastError` to "Connection timed out"
- Emit `connectionFailed`
- Log WARNING level

### AASDK Library Error
- Transition to ERROR state
- Set `lastError` to AASDK error message
- Emit `connectionFailed` or `deviceDisconnected`
- Log ERROR level

### USB Permission Denied (Linux)
- Transition to ERROR state
- Set `lastError` to "USB permission denied. Add udev rules."
- Emit `connectionFailed`
- Log ERROR level with remediation steps

---

## Threading

- **Main Thread**: All QML-facing methods and properties
- **Worker Thread**: AASDK operations (device discovery, connection, data transfer)
- **Synchronization**: All signals emitted via `QMetaObject::invokeMethod` with `Qt::QueuedConnection`

---

## Lifecycle

1. **Construction**: Initialize AASDK library
2. **Application Startup**: Call `startDiscovery()`
3. **Runtime**: Manage connection lifecycle
4. **Application Shutdown**: Call `disconnect()`, cleanup AASDK

---

## Dependencies

- **AASDK Library**: AndroidAuto protocol implementation
- **SettingsManager**: Read connection preference, write last connected device
- **AudioHandler**: Notify when audio stream starts/stops
- **VideoFrameProvider**: Notify when video stream starts/stops

---

## Testing Requirements

### Unit Tests
- Device discovery (0, 1, multiple devices)
- Connection success flow
- Connection failure flow
- Disconnection handling (user-initiated, unexpected)
- Touch event forwarding
- State machine transitions
- Error recovery

### Integration Tests
- USB device connection end-to-end
- Wireless device connection end-to-end (requires network setup)
- Multi-device selection flow
- Connection persistence (last connected device priority)
- Video and audio stream activation
