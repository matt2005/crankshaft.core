# Extension Framework - Comprehensive Developer Guide

**Project**: Crankshaft Automotive Infotainment System  
**Last Updated**: 2025-01-15  
**Scope**: Plugin architecture, manifest system, security model, developer workflow

---

## 1. Extension Framework Overview

### 1.1 Purpose

The Extension Framework enables third-party developers to:
- Add new features without modifying core code
- Distribute extensions via Extension Store
- Integrate with core services via EventBus
- Contribute to Crankshaft ecosystem

### 1.2 Architecture

```
┌─────────────────────────────────────────┐
│ Extension Store (Web UI)                │
│ User discovers & installs extensions    │
└────────────────┬────────────────────────┘
                 │ Download .crank file
                 ↓
┌─────────────────────────────────────────┐
│ Extension Manager                       │
│ ├─ Manifest parsing                     │
│ ├─ Signature verification               │
│ ├─ Dependency resolution                │
│ └─ Lifecycle management                 │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Extension Instance (Sandbox)            │
│ ├─ QML UI components                    │
│ ├─ C++ backend (if compiled)            │
│ ├─ EventBus subscriptions               │
│ └─ Restricted file access               │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Core Services (EventBus)                │
│ ├─ Media, Audio, Bluetooth              │
│ ├─ Android Auto, WiFi                   │
│ └─ Extensions communicate via events    │
└─────────────────────────────────────────┘
```

---

## 2. Extension Manifest Format

### 2.1 manifest.json Structure

**File**: `manifest.json` (root of extension package)

```json
{
  "id": "com.example.spotify",
  "version": "1.2.3",
  "apiVersion": "1.0",
  
  "metadata": {
    "name": "Spotify Integration",
    "description": "Stream music from Spotify",
    "author": "Spotify Developer",
    "license": "MIT",
    "website": "https://www.spotify.com/",
    "supportUrl": "https://github.com/example/crankshaft-spotify/issues",
    "changelogUrl": "https://github.com/example/crankshaft-spotify/releases"
  },
  
  "ui": {
    "entryPoint": "qml/main.qml",
    "displayName": "Spotify",
    "icon": "assets/icon-128.png",
    "appIcon": "assets/app-icon.png",
    "backgroundColor": "#1DB954"
  },
  
  "features": {
    "playback": true,
    "nowPlaying": true,
    "playlist": true,
    "search": true
  },
  
  "requiredEventTopics": [
    "media/play_start",
    "media/pause",
    "media/next_track",
    "media/prev_track",
    "media/set_volume"
  ],
  
  "publishedEventTopics": [
    "spotify/authenticated",
    "spotify/playback_started",
    "spotify/playback_paused",
    "spotify/track_changed",
    "spotify/playlist_loaded",
    "spotify/error"
  ],
  
  "permissions": {
    "network": true,
    "filesystem": {
      "cache": true,
      "data": true,
      "allowedPaths": ["/opt/crankshaft/extensions/spotify/"]
    },
    "bluetooth": false,
    "gps": false,
    "camera": false,
    "microphone": false
  },
  
  "dependencies": {
    "crankshaft": ">=1.0.0",
    "qt": ">=6.0.0"
  },
  
  "settings": {
    "autoStart": true,
    "singleton": true,
    "priority": 50
  },
  
  "signing": {
    "publicKeyId": "spotify-key-2025",
    "signature": "base64-encoded-signature-here..."
  }
}
```

### 2.2 Manifest Field Descriptions

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `id` | Yes | String | Reverse domain notation (e.g., `com.company.extension`) |
| `version` | Yes | String | Semantic versioning (major.minor.patch) |
| `apiVersion` | Yes | String | Target Crankshaft API version |
| `name` | Yes | String | Display name in Store |
| `description` | Yes | String | Short description (1-2 sentences) |
| `author` | Yes | String | Developer name/organization |
| `entryPoint` | Yes | String | Path to main QML file |
| `icon` | Yes | String | 128×128px PNG icon |
| `permissions` | Yes | Object | Requested capabilities |
| `requiredEventTopics` | No | Array | EventBus topics this extension needs |
| `publishedEventTopics` | No | Array | EventBus topics this extension emits |
| `dependencies` | Yes | Object | Required versions (crankshaft, qt, etc.) |

---

## 3. Extension Lifecycle

### 3.1 States & Transitions

```
DISCOVERY
    ↓ (user selects from store)
DOWNLOADING
    ↓ (download complete)
INSTALLING
    ├─ Verify signature
    ├─ Extract files
    ├─ Register manifest
    └─ Create extension instance
    ↓
INSTALLED (inactive)
    ↓ (user taps "Open" or autoStart=true)
LOADING
    ├─ Load QML components
    ├─ Initialize C++ backend (if any)
    └─ Set up EventBus connections
    ↓
ACTIVE (running)
    ├─ Process events
    ├─ Respond to user interactions
    └─ May sleep (low priority)
    ↓ (user stops, or timeout)
STOPPING
    ├─ Save state
    ├─ Cleanup resources
    └─ Unsubscribe from events
    ↓
STOPPED (inactive)
    ↓ (user uninstalls)
UNINSTALLING
    ├─ Terminate all processes
    ├─ Remove files
    └─ Clean registry
    ↓
REMOVED (deleted)
```

### 3.2 Lifecycle Callbacks

**QML Interface**:
```qml
// Every extension's main.qml should implement these functions
Item {
    // Called when extension is loaded
    function onExtensionInitialize() {
        console.log("Extension initializing");
        // Set up event subscriptions
        eventBus.subscribe("media/*");
        eventBus.subscribe("playback/*");
    }
    
    // Called when extension becomes active
    function onExtensionActivate() {
        console.log("Extension activated");
        // Start background tasks
        // Resume animation
    }
    
    // Called when extension goes to background/inactive
    function onExtensionDeactivate() {
        console.log("Extension deactivated");
        // Pause non-critical tasks
        // Save temporary state
    }
    
    // Called before extension unload (save state, cleanup)
    function onExtensionShutdown() {
        console.log("Extension shutting down");
        // Save preferences
        settingsRegistry.set("lastTrack", currentTrack);
        // Cleanup resources
        mediaPlayer.stop();
    }
}
```

**C++ Backend (Optional)**:
```cpp
class SpotifyExtension : public QObject {
    Q_OBJECT
public:
    Q_INVOKABLE void initialize() {
        qInfo() << "C++ extension initializing";
        // Setup
    }
    
    Q_INVOKABLE void activate() {
        qInfo() << "C++ extension activated";
    }
    
    Q_INVOKABLE void deactivate() {
        qInfo() << "C++ extension deactivated";
    }
    
    Q_INVOKABLE void shutdown() {
        qInfo() << "C++ extension shutting down";
        // Save state
    }
};
```

### 3.3 Scenario: Spotify Extension Startup

```
Time   Component              Action                          State
─────────────────────────────────────────────────────────────────
0ms    User                   Opens Crankshaft app            INSTALLED
10ms   ExtensionManager       Loads Spotify manifest          LOADING
50ms   ExtensionManager       Verifies signature              (verifying)
100ms  QML Engine             Loads main.qml                 LOADING
150ms  Spotify Extension      onExtensionInitialize() called
       - Subscribe to media/* events
       - Load saved user preferences
       - Initialize UI widgets
200ms  Extension              UI ready to display             LOADED
250ms  ExtensionManager       onExtensionActivate() called
       - Start Spotify session
       - Resume playback if was playing
300ms  Spotify               User sees Spotify UI             ACTIVE
       - Can interact with playlists
       - Receives media events

Shutdown scenario (user force-stops app):
──────────────────────────────────────────
0ms    User                   Closes Crankshaft
10ms   ExtensionManager       onExtensionDeactivate()
       - Pause playback
       - Save current playlist
20ms   ExtensionManager       onExtensionShutdown()
       - Save authentication token
       - Cleanup resources
30ms   QML Engine             Unload main.qml
40ms   Process                Exit
```

---

## 4. EventBus Integration

### 4.1 Pub/Sub Pattern

**Extensions communicate with core via EventBus**

```qml
// Spotify extension subscribes to media events
Connections {
    target: eventBus
    
    onMessagePublished: function(topic, payload) {
        if (topic === "media/play_start") {
            handleMediaPlay(payload);
        } else if (topic === "media/pause") {
            handleMediaPause(payload);
        } else if (topic === "media/next_track") {
            spotifyPlayer.nextTrack();
        }
    }
}

// Spotify publishes its own events
function onTrackChanged(track) {
    eventBus.publish("spotify/track_changed", {
        trackId: track.id,
        trackName: track.name,
        artist: track.artist,
        duration: track.durationMs,
        thumbnail: track.thumbnailUrl,
        timestamp: Date.now()
    });
}
```

### 4.2 Topic Naming Convention

**Format**: `extension_id/event_name`

```
Spotify topics:
├─ spotify/authenticated
├─ spotify/playback_started
├─ spotify/playback_paused
├─ spotify/track_changed
├─ spotify/playlist_loaded
└─ spotify/error

YouTube topics:
├─ youtube/video_playing
├─ youtube/video_paused
├─ youtube/playlist_loaded
└─ youtube/search_results

Navigation topics:
├─ navigation/route_calculated
├─ navigation/arrival_warning
├─ navigation/maneuver
└─ navigation/traffic_update
```

### 4.3 Example: Playing Track from Extension

```qml
// Spotify extension UI
Button {
    text: "Play"
    onClicked: {
        // Command the core media service
        eventBus.publish("spotify/play_request", {
            trackId: spotifyModel.currentTrack.id,
            context: "album"
        });
        
        // Core's media service receives this event
        // May acknowledge with media/playback_started
    }
}

// Subscribe to core's playback events
Connections {
    target: eventBus
    
    onMessagePublished: function(topic, payload) {
        if (topic === "media/playback_started") {
            // Core confirmed playback started
            ui.updateUI("playing", payload.track);
        } else if (topic === "media/playback_stopped") {
            ui.updateUI("stopped");
        }
    }
}
```

---

## 5. Security Model

### 5.1 Sandboxing

**Extensions run in same process but have restricted access**

```
Capability Matrix:
╔──────────────────┬──────────┬─────────────┬──────────┐
║ Capability       │ Spotify  │ Navigation  │ Malware* │
╠──────────────────┼──────────┼─────────────┼──────────╣
║ Network          │ ✓ (Yes)  │ ✓ (Yes)     │ ✗ (No)   ║
║ Filesystem read  │ ✓ (Own)  │ ✓ (Own)     │ ✗ (No)   ║
║ Filesystem write │ ✓ (Own)  │ ✓ (Own)     │ ✗ (No)   ║
║ Bluetooth        │ ✗ (No)   │ ✗ (No)      │ ✗ (No)   ║
║ GPS              │ ✓ (Yes)  │ ✓ (Yes)     │ ✗ (No)   ║
║ Microphone       │ ✗ (No)   │ ✗ (No)      │ ✗ (No)   ║
║ Camera           │ ✗ (No)   │ ✗ (No)      │ ✗ (No)   ║
║ EventBus topics  │ Filtered │ Filtered    │ Filtered ║
╚──────────────────┴──────────┴─────────────┴──────────╝

* Malicious extension (rejected from store)
```

### 5.2 Signature Verification

**All extensions must be signed by publisher**

```cpp
class ExtensionSecurityManager {
    bool verifyExtensionSignature(const QString& extensionPath) {
        // 1. Read manifest.json
        QJsonDocument manifest = loadManifest(extensionPath);
        
        // 2. Extract public key ID
        QString keyId = manifest["signing"]["publicKeyId"].toString();
        
        // 3. Fetch public key from trusted keystore
        QByteArray publicKey = m_keystoreManager.getPublicKey(keyId);
        if (publicKey.isEmpty()) {
            Logger::instance().error("Unknown key ID: " + keyId);
            return false;
        }
        
        // 4. Verify signature
        QByteArray signature = QByteArray::fromBase64(
            manifest["signing"]["signature"].toString().toUtf8()
        );
        
        // 5. Validate with OpenSSL (RSA-2048)
        return verifyRSASignature(manifestPath, signature, publicKey);
    }
};
```

### 5.3 Permission System

**User must grant permissions to extension**

```
On installation, user sees permission dialog:

┌───────────────────────────────────────┐
│ Install "Spotify"?                    │
├───────────────────────────────────────┤
│ This extension requests:              │
│ ☑ Network access (streams music)     │
│ ☑ File storage (cache)               │
│ ☐ GPS location (not used)            │
│ ☐ Camera (not used)                  │
├───────────────────────────────────────┤
│ [ Deny ]  [ Allow ]                   │
└───────────────────────────────────────┘

At runtime:
- Core enforces: extension can only access granted permissions
- Attempt to access denied permission → error → logged
- User can revoke permissions → extension stops
```

---

## 6. Development Workflow

### 6.1 Creating Your First Extension

**Step 1: Project Structure**
```
my-extension/
├── manifest.json          # Extension metadata
├── qml/
│   └── main.qml           # Main UI component
├── assets/
│   ├── icon-128.png       # Extension icon
│   └── app-icon.png       # App drawer icon
├── src/                   # Optional: C++ backend
│   ├── CMakeLists.txt
│   └── MyExtension.cpp
└── README.md              # Developer documentation
```

**Step 2: manifest.json**
```json
{
  "id": "com.mycompany.firstapp",
  "version": "1.0.0",
  "apiVersion": "1.0",
  "metadata": {
    "name": "My First App",
    "description": "A simple test extension",
    "author": "Developer Name",
    "license": "MIT"
  },
  "ui": {
    "entryPoint": "qml/main.qml",
    "displayName": "First App",
    "icon": "assets/icon-128.png"
  },
  "requiredEventTopics": ["media/playback_started"],
  "publishedEventTopics": ["myapp/ready"],
  "permissions": {
    "network": true,
    "filesystem": { "cache": true }
  },
  "dependencies": {
    "crankshaft": ">=1.0.0",
    "qt": ">=6.0.0"
  }
}
```

**Step 3: qml/main.qml**
```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    width: 1024
    height: 600
    
    property var eventBus: null
    property var settingsRegistry: null
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10
        
        Text {
            text: "My First Extension"
            font.pointSize: 24
            font.bold: true
        }
        
        Button {
            text: "Click Me"
            Layout.preferredHeight: 60
            onClicked: {
                // Publish event
                eventBus.publish("myapp/button_clicked", {
                    timestamp: Date.now()
                });
            }
        }
        
        Item { Layout.fillHeight: true }
    }
    
    // Lifecycle callbacks
    function onExtensionInitialize() {
        console.log("Extension initializing");
        // Subscribe to events
        eventBus.subscribe("media/playback_started");
    }
    
    function onExtensionActivate() {
        console.log("Extension activated");
    }
    
    function onExtensionShutdown() {
        console.log("Extension shutting down");
        // Save state
        settingsRegistry.set("lastState", "active");
    }
}
```

**Step 4: Package as .crank file**
```bash
# .crank is just a ZIP file with specific structure
zip -r my-extension.crank manifest.json qml/ assets/

# Sign the package (requires private key)
openssl dgst -sha256 -sign private_key.pem my-extension.crank \
    | openssl base64 > signature.txt

# Add signature to manifest and repackage
```

### 6.2 Testing Your Extension

**Local Testing (Development Mode)**:
```bash
# Copy extension to local extensions directory
cp my-extension.crank ~/.local/share/crankshaft/extensions/

# Launch Crankshaft in development mode
crankshaft --dev-mode

# Extension appears in "Installed" tab
# Can be tested without store approval
```

**Mock EventBus for Unit Tests**:
```qml
// tests/tst_MyExtension.qml
import QtTest
import QtQuick

TestCase {
    name: "MyExtensionTests"
    
    property var mockEventBus: QtObject {
        signal messagePublished(string topic, var payload)
        function publish(topic, payload) {
            messagePublished(topic, payload);
        }
        function subscribe(topic) { }
    }
    
    function test_buttonClick() {
        let clicked = false;
        mockEventBus.messagePublished.connect(function(topic, payload) {
            if (topic === "myapp/button_clicked")
                clicked = true;
        });
        
        myExtension.mockEventBus = mockEventBus;
        myExtension.clickButton();
        
        verify(clicked, "Button click published event");
    }
}
```

---

## 7. Common Extension Types

### 7.1 Music Streaming (Spotify, YouTube Music)

**Key Features**:
- Playback control (play, pause, next, previous)
- Queue management
- Artist/album browsing
- Search functionality

**Events**:
```
Published: spotify/track_changed, spotify/playback_started
Subscribed: media/play_start, media/pause, media/next_track
```

### 7.2 Navigation (Google Maps, HERE Maps)

**Key Features**:
- Route calculation
- Turn-by-turn guidance
- Traffic information
- POI (Points of Interest) search

**Events**:
```
Published: navigation/maneuver, navigation/arrival
Subscribed: gps/location_updated, vehicle/speed_changed
```

### 7.3 Messaging (WhatsApp, Telegram)

**Key Features**:
- Display notifications
- Read messages
- Send quick replies
- Contact list

**Events**:
```
Published: messaging/new_message, messaging/call_incoming
Subscribed: messaging/reply_sent
```

---

## 8. Best Practices

### 8.1 Performance

- **Lazy load** UI components not immediately visible
- **Debounce** event handlers (don't process every event)
- **Cache** network requests (avoid redundant API calls)
- **Profile** with Qt QML Profiler

**Example: Debounced search**
```qml
Timer {
    id: searchDebounce
    interval: 500  // 500ms delay
    onTriggered: performSearch(searchField.text)
}

TextField {
    onTextChanged: searchDebounce.restart()
}
```

### 8.2 Error Handling

```qml
// Always handle errors gracefully
function loadTrack(trackId) {
    try {
        spotify.loadTrack(trackId);
    } catch (error) {
        console.error("Failed to load track:", error);
        // Publish error event for UI notification
        eventBus.publish("myapp/error", {
            message: "Could not load track",
            severity: "warning"
        });
        // Show fallback UI
        showErrorMessage("Track not available");
    }
}
```

### 8.3 Memory Management

```qml
// Clean up when deactivating
function onExtensionDeactivate() {
    // Stop timers
    updateTimer.stop();
    
    // Disconnect signals
    mediaPlayer.stopped.disconnect();
    
    // Release large objects
    if (coverArtCache) {
        coverArtCache.clear();
        coverArtCache = null;
    }
}
```

---

## 9. Distribution & Publishing

### 9.1 Publishing to Extension Store

1. **Create account** on Crankshaft Extension Store
2. **Package extension** as .crank file
3. **Write description** and screenshots
4. **Submit for review** (automated checks + human review)
5. **Approval** (if passes security & quality checks)
6. **Users discover** via store search

### 9.2 Version Management

```json
{
  "version": "1.2.3",
  "changelog": "Fixed playback sync issue, improved UI responsiveness"
}
```

Semantic versioning: `MAJOR.MINOR.PATCH`
- **MAJOR**: Incompatible API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes

---

## 10. Troubleshooting

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Extension won't load** | "Failed to initialize" | Check manifest.json syntax, verify QML files exist |
| **Events not received** | No event handling works | Verify topic names, check EventBus subscription |
| **Memory leak** | Growing RAM over time | Check Connections cleanup, verify property bindings |
| **Signature invalid** | "Signature verification failed" | Regenerate signature, ensure correct key used |
| **Permission denied** | "Access denied: network" | Add permission in manifest.json, user must re-install |

---

## 11. API Reference

### Extension Lifecycle Functions

```qml
// Called on extension load
function onExtensionInitialize()

// Called on extension activation
function onExtensionActivate()

// Called on extension deactivation (background)
function onExtensionDeactivate()

// Called before extension unload
function onExtensionShutdown()
```

### Available Globals

```qml
// EventBus for Pub/Sub
eventBus.subscribe(topic: String)
eventBus.publish(topic: String, payload: Object)

// Settings persistence
settingsRegistry.set(key: String, value: Variant)
settingsRegistry.get(key: String, defaultValue: Variant): Variant

// Logging
console.log(message: String)
console.warn(message: String)
console.error(message: String)
```

---

## 12. Documentation Checklist

- [x] Manifest format and validation
- [x] Extension lifecycle and callbacks
- [x] EventBus integration examples
- [x] Security model and signing
- [x] Development workflow (create, test, publish)
- [x] Common extension types
- [x] Best practices (performance, error handling, memory)
- [x] Distribution and versioning
- [ ] C++ backend guide (for complex extensions)
- [ ] UI component library reference

---

**End of Extension Framework Documentation**
