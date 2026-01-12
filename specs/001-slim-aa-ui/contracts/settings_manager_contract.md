# Contract: PreferencesFacade

**Service**: PreferencesFacade  
**Type**: C++ QObject exposed to QML (facade pattern)  
**File**: `PreferencesFacade.h` / `PreferencesFacade.cpp`

## Purpose

QML bridge to core's `PreferencesService`. Exposes slim UI settings to QML layer with typed properties. This is a thin facade - all persistence is delegated to the core `PreferencesService` (SQLite-backed).

**Architecture**: `QML ↔ PreferencesFacade ↔ core::PreferencesService`

**Key Prefix**: All slim UI settings use prefix `slim_ui.` to namespace them within the shared preferences database.

---

## Exposed Properties (Q_PROPERTY)

### `displayBrightness` : int
- **Range**: 0-100
- **Default**: 50
- **Description**: Current display brightness percentage
- **Writable**: Yes
- **Notify Signal**: `displayBrightnessChanged(int)`
- **Implementation**: 
  - Read: `m_corePrefs->get("slim_ui.display.brightness", 50).toInt()`
  - Write: `m_corePrefs->set("slim_ui.display.brightness", value)`

### `audioVolume` : int
- **Range**: 0-100
- **Default**: 50
- **Description**: Current audio volume percentage
- **Writable**: Yes
- **Notify Signal**: `audioVolumeChanged(int)`
- **Implementation**: 
  - Read: `m_corePrefs->get("slim_ui.audio.volume", 50).toInt()`
  - Write: `m_corePrefs->set("slim_ui.audio.volume", value)`

### `connectionPreference` : QString
- **Values**: "USB", "WIRELESS"
- **Default**: "USB"
- **Description**: Preferred connection type
- **Writable**: Yes
- **Notify Signal**: `connectionPreferenceChanged(QString)`
- **Implementation**: 
  - Read: `m_corePrefs->get("slim_ui.connection.preference", "USB").toString()`
  - Write: `m_corePrefs->set("slim_ui.connection.preference", value)`

### `themeMode` : QString
- **Values**: "LIGHT", "DARK"
- **Default**: "DARK"
- **Description**: Current theme mode
- **Writable**: Yes
- **Notify Signal**: `themeModeChanged(QString)`
- **Implementation**: 
  - Read: `m_corePrefs->get("slim_ui.theme.mode", "DARK").toString()`
  - Write: `m_corePrefs->set("slim_ui.theme.mode", value)`

### `lastConnectedDeviceId` : QString
- **Default**: ""
- **Description**: Device ID of last successfully connected device
- **Writable**: No (managed internally by facade when device connects)
- **Notify Signal**: `lastConnectedDeviceIdChanged(QString)`
- **Implementation**: 
  - Read: `m_corePrefs->get("slim_ui.device.lastConnected", "").toString()`
  - Write: Internal only, called when device successfully connects

---

## Exposed Methods (Q_INVOKABLE)

### `bool loadSettings()`
**Description**: Initialize preferences and load all settings (called on startup)  
**Returns**: `true` if loaded successfully, `false` if database error occurred  
**Side Effects**:
- Calls `m_corePrefs->initialize()` to ensure SQLite database ready
- Reads all slim UI settings from core preferences
- Emits all property changed signals with current values
- Core service handles corruption recovery automatically (returns defaults)

**Implementation**:
```cpp
bool PreferencesFacade::loadSettings() {
    if (!m_corePrefs->initialize()) return false;
    // Read all properties and emit signals
    emit displayBrightnessChanged(displayBrightness());
    emit audioVolumeChanged(audioVolume());
    // ... etc
    return true;
}
```

**Example QML Usage**:
```qml
Component.onCompleted: {
    preferencesFacade.loadSettings()
}
```

### `bool saveSettings()`
**Description**: (Optional) Force persistence of any pending writes  
**Returns**: `true` always (core service handles persistence automatically)  
**Side Effects**:
- No-op in current architecture (core's PreferencesService auto-saves on set)
- Provided for API compatibility, may call `m_corePrefs->sync()` if needed

**Note**: With core integration, explicit save is unnecessary - `set()` calls persist immediately. This method exists for QML compatibility.

**Example QML Usage**:
```qml
onAccepted: {
    if (!settingsManager.saveSettings()) {
        errorDialog.show("Failed to save settings")
    }
}
```

### `void resetToDefaults()`
**Description**: Reset all settings to factory defaults  
**Returns**: void  
**Side Effects**:
- Sets all properties to default values
- Emits all property changed signals
- Does NOT automatically save (caller must call `saveSettings()`)
- Logs reset event

**Example QML Usage**:
```qml
Button {
    text: "Reset to Defaults"
    onClicked: {
        settingsManager.resetToDefaults()
        settingsManager.saveSettings()
    }
}
```

### `void updateLastConnectedDevice(QString deviceId)`
**Description**: Update the last connected device identifier  
**Parameters**:
- `deviceId`: Device identifier string
**Returns**: void  
**Side Effects**:
- Updates `lastConnectedDeviceId` property
- Emits `lastConnectedDeviceIdChanged` signal
- Automatically saves settings

**Called By**: AAConnectionManager on successful connection

---

## Signals

### `displayBrightnessChanged(int brightness)`
**Emitted When**: Display brightness property changes  
**Parameters**: New brightness value (0-100)

### `audioVolumeChanged(int volume)`
**Emitted When**: Audio volume property changes  
**Parameters**: New volume value (0-100)

### `connectionPreferenceChanged(QString preference)`
**Emitted When**: Connection preference property changes  
**Parameters**: New preference ("USB" or "WIRELESS")

### `themeModeChanged(QString mode)`
**Emitted When**: Theme mode property changes  
**Parameters**: New mode ("LIGHT" or "DARK")

### `lastConnectedDeviceIdChanged(QString deviceId)`
**Emitted When**: Last connected device ID changes  
**Parameters**: New device ID string

### `settingsCorruptionDetected(QString reason)`
**Emitted When**: Settings file is corrupted on load  
**Parameters**: Reason string describing corruption  
**Use Case**: QML can display warning notification to user

---

## Data Types

### SettingsData (internal struct)
```cpp
struct SettingsData {
    int displayBrightness;
    int audioVolume;
    QString connectionPreference;
    QString themeMode;
    QString lastConnectedDeviceId;
    QString configVersion;
};
```

---

## Error Handling

### Load Failures
- **File Missing**: Create with factory defaults, return `false`, log INFO
- **File Corrupted**: Reset to factory defaults, overwrite file, emit `settingsCorruptionDetected`, log WARNING
- **JSON Parse Error**: Same as corrupted
- **Invalid Values**: Use factory default for invalid fields, log WARNING per field

### Save Failures
- **Directory Missing**: Create directory, retry save
- **No Write Permission**: Log ERROR, return `false`
- **Disk Full**: Log ERROR, return `false`

---

## Lifecycle

1. **Construction**: Initialize with factory defaults
2. **Application Startup**: QML calls `loadSettings()`
3. **Runtime**: Properties modified by QML or other services
4. **On Property Change**: Auto-save triggered (debounced 1 second)
5. **Application Shutdown**: Final `saveSettings()` called

---

## Threading

- **Main Thread Only**: All methods and property access must occur on main Qt thread
- **File I/O**: Performed synchronously (acceptable for small config file)

---

## Testing Requirements

### Unit Tests
- Load valid settings file
- Load missing settings file
- Load corrupted settings file
- Save settings successfully
- Save settings with I/O error (simulated)
- Reset to defaults
- Property validation (out of range values)
- Update last connected device

### Integration Tests
- Settings persist across application restart
- Settings corruption recovery flow
- Property change triggers auto-save
