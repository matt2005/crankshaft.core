# UI Architecture & Component Documentation

**Project**: Crankshaft Automotive Infotainment System  
**Last Updated**: 2025-01-15  
**Scope**: QML UI, WebSocket client, state management, responsive design

---

## 1. UI Architecture Overview

### 1.1 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **UI Framework** | Qt QML 6.x | Modern declarative UI |
| **Backend** | C++ Qt Core | Event loop, networking |
| **Styling** | Qt Style Sheets + Theme engine | Light/Dark mode |
| **i18n** | Qt Linguist | Multi-language support |
| **Networking** | Qt WebSocket + Custom JSON | Core communication |
| **Data Persistence** | SettingsRegistry (QSettings) | User preferences |

### 1.2 Architecture Stack

```
┌─────────────────────────────────────────────┐
│ QML Layer (Presentation)                    │
│ ├─ Pages/ (full-screen UI)                  │
│ ├─ Components/ (reusable widgets)           │
│ └─ Controls/ (gestures, input)              │
└────────────────────┬────────────────────────┘
                     │ Qt Binding
┌────────────────────▼────────────────────────┐
│ C++ Bridge Layer                            │
│ ├─ WebSocketClient (network I/O)            │
│ ├─ Theme (color/style management)          │
│ ├─ SettingsRegistry (preferences)          │
│ └─ Models (data adapters)                   │
└────────────────────┬────────────────────────┘
                     │ HTTP/WebSocket
┌────────────────────▼────────────────────────┐
│ Crankshaft Core (Remote)                    │
│ ├─ EventBus (local events)                  │
│ ├─ Services (AndroidAuto, Media, etc.)      │
│ └─ HAL (hardware drivers)                   │
└─────────────────────────────────────────────┘
```

### 1.3 Design Principles

1. **Responsive Design**: Adapts to multiple screen sizes (800×480 to 1920×1080)
2. **Touch-Optimised**: Minimum 48dp touch targets
3. **Accessibility**: High contrast, large text options
4. **Performance**: 60fps animations on low-power hardware
5. **Offline-Ready**: Core features work without core connection
6. **i18n-Ready**: All strings are translatable

---

## 2. QML Structure

### 2.1 File Organization

```
ui/
├── qml/
│   ├── Pages/
│   │   ├── HomePage.qml          # Home screen
│   │   ├── AndroidAutoPage.qml    # Android Auto UI
│   │   ├── MediaPage.qml          # Media player
│   │   ├── SettingsPage.qml       # Settings
│   │   └── ExtensionsPage.qml     # Plugin management
│   ├── Components/
│   │   ├── Button.qml             # Custom button
│   │   ├── Card.qml               # Content card
│   │   ├── Slider.qml             # Volume/seek slider
│   │   ├── Toast.qml              # Notification popup
│   │   └── Dialog.qml             # Modal dialog
│   ├── Layouts/
│   │   ├── GridLayout.qml         # Grid layout
│   │   ├── StackLayout.qml        # Stack layout
│   │   └── FlowLayout.qml         # Flow layout
│   ├── Controls/
│   │   ├── TouchGestureHandler.qml # Gesture recognition
│   │   ├── VolumeKnob.qml         # Rotating knob
│   │   └── HapticFeedback.qml     # Vibration effects
│   ├── themes/
│   │   ├── Light.qml              # Light color scheme
│   │   ├── Dark.qml               # Dark color scheme
│   │   └── Typography.qml         # Font definitions
│   ├── main.qml                   # Root component
│   ├── Constants.qml              # Global constants
│   └── i18n.qml                   # i18n wrapper
├── main.cpp                       # QML engine setup
├── WebSocketClient.h/cpp          # WebSocket client
├── Theme.h/cpp                    # Theme manager
└── SettingsRegistry.h/cpp         # Settings persistence
```

### 2.2 Main Window Structure

```qml
// ui/qml/main.qml
import QtQuick
import QtQuick.Layouts
import "Constants.js" as Constants

ApplicationWindow {
    id: mainWindow
    
    // Window properties
    width: 1024
    height: 600
    title: "Crankshaft Automotive Infotainment"
    color: theme.backgroundColor
    
    // Properties
    property var theme: null
    property var webSocketClient: null
    property var i18n: null
    
    // Status bar
    Rectangle {
        id: statusBar
        height: 40
        color: theme.accentColor
        anchors { top: parent.top; left: parent.left; right: parent.right }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            
            Text {
                text: "Crankshaft"
                font.bold: true
                color: theme.textColor
            }
            
            Item { Layout.fillWidth: true }  // Spacer
            
            // Status indicators
            StatusIndicator {
                id: coreStatus
                text: "Core"
                active: webSocketClient.isConnected
            }
            
            ThemeToggle {
                onToggled: theme.isDarkMode = !theme.isDarkMode
            }
        }
    }
    
    // Main content area (Stack layout for page switching)
    StackLayout {
        id: stackLayout
        anchors {
            top: statusBar.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        currentIndex: 0  // Home page by default
        
        HomePage { id: homePage }
        AndroidAutoPage { id: aaPage }
        MediaPage { id: mediaPage }
        SettingsPage { id: settingsPage }
    }
    
    // Navigation bar (app drawer)
    NavigationBar {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: 80
        
        onPageSelected: stackLayout.currentIndex = page
    }
    
    // Toast notifications
    ToastContainer {
        id: toastContainer
        anchors { bottom: navigationBar.top; horizontalCenter: parent.horizontalCenter }
    }
    
    // Component initialization
    Component.onCompleted: {
        // Initialize services
        webSocketClient.connectToCore();
        
        // Subscribe to events
        webSocketClient.onEventReceived.connect(handleCoreEvent);
        
        // Load user theme preference
        theme.isDarkMode = settingsRegistry.get("ui/darkMode", true);
    }
    
    // Event handlers
    function handleCoreEvent(topic, payload) {
        console.log("Event received:", topic);
        
        // Route events to appropriate pages
        if (topic.startsWith("android_auto/")) {
            aaPage.handleEvent(topic, payload);
        } else if (topic.startsWith("media/")) {
            mediaPage.handleEvent(topic, payload);
        }
    }
}
```

---

## 3. WebSocket Client Implementation

### 3.1 Connection Lifecycle

```cpp
// ui/WebSocketClient.h
class WebSocketClient : public QObject {
    Q_OBJECT
    
public:
    explicit WebSocketClient(QObject* parent = nullptr);
    
    // Connection management
    Q_INVOKABLE void connectToCore(const QString& host = "localhost",
                                   quint16 port = 8080);
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE bool isConnected() const;
    
    // Command sending
    Q_INVOKABLE void sendCommand(const QString& service,
                                  const QString& command,
                                  const QVariantMap& params = {});
    
    // Event subscription
    Q_INVOKABLE void subscribe(const QString& topic);
    Q_INVOKABLE void unsubscribe(const QString& topic);
    
signals:
    // Connection status
    void connected();
    void disconnected();
    void connectionError(const QString& error);
    
    // Events from core
    void eventReceived(const QString& topic, const QVariantMap& payload);
    
    // Command responses
    void commandResponse(const QString& command, const QVariantMap& response);
    void commandError(const QString& command, const QString& error);
    
private slots:
    void onConnected();
    void onDisconnected();
    void onTextReceived(const QString& message);
    void onError(QAbstractSocket::SocketError error);
    
private:
    QWebSocket m_webSocket;
    QString m_host;
    quint16 m_port;
    QMap<QString, int> m_pendingCommands;  // Command tracking
};
```

### 3.2 Connection Scenario

```
Time    Client                  Server                     UI
──────────────────────────────────────────────────────────────
0ms     connectToCore()         (listening on 8080)
10ms    TCP connect             onNewConnection()
20ms    WS handshake            (upgrade protocol)
30ms    (connection ready)      (client connected)
40ms    connected() signal      (in m_clients list)
50ms    subscribe(android_auto/*)
60ms                            handleSubscribe()
70ms    subscribe(media/*)      (subscriptions recorded)
80ms    (connected, subscribed) (ready for events)
        ├─ Send commands
        └─ Receive events

Error scenario (connection lost):
──────────────────────────────────
Timeout (no ping for 30s)        pingTimeout()
Server closes connection         onDisconnected()
disconnected() signal            (reconnect logic)
(Retry with exponential backoff)
```

### 3.3 QML Integration

```qml
// ui/qml/Components/AndroidAutoButton.qml
import QtQuick

Rectangle {
    id: aaButton
    width: 200
    height: 200
    color: theme.cardColor
    radius: 10
    
    property var webSocketClient: null
    
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Send command to core
            webSocketClient.sendCommand(
                "AndroidAuto",
                "start_projection",
                { displayId: 0 }
            );
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: "Start Android Auto"
        color: theme.textColor
    }
    
    // Respond to core events
    Connections {
        target: webSocketClient
        onEventReceived: function(topic, payload) {
            if (topic === "android_auto/projection_started") {
                console.log("Projection started");
                // Update UI state
                aaButton.enabled = false;
            }
        }
    }
}
```

---

## 4. State Management

### 4.1 Model Pattern

```qml
// ui/qml/Models/AndroidAutoModel.qml
import QtQuick

QtObject {
    id: aaModel
    
    // Properties (bound to UI)
    property bool deviceConnected: false
    property string deviceName: ""
    property bool projectionActive: false
    property string projectionStatus: "idle"  // idle, starting, active
    property int videoFps: 0
    property int audioBitrate: 0
    
    // Commands
    function startProjection() {
        console.log("Requesting projection start");
        webSocketClient.sendCommand("AndroidAuto", "start_projection", {});
    }
    
    function stopProjection() {
        console.log("Requesting projection stop");
        webSocketClient.sendCommand("AndroidAuto", "stop_projection", {});
    }
    
    // Event handlers (from core)
    function onDeviceConnected(payload) {
        deviceConnected = true;
        deviceName = payload.deviceName || "Device";
    }
    
    function onProjectionStarted(payload) {
        projectionActive = true;
        projectionStatus = "active";
    }
    
    function onProjectionStopped(payload) {
        projectionActive = false;
        projectionStatus = "idle";
    }
}
```

### 4.2 Reactive Data Flow

```
Core Service (e.g., AndroidAutoService)
    ↓
publish("android_auto/device_connected", {...})
    ↓
EventBus::instance()
    ↓
WebSocketServer::broadcastEvent()
    ↓
Client receives WS message
    ↓
WebSocketClient::onTextReceived()
    ↓
emit eventReceived(topic, payload)
    ↓
QML Connections receives signal
    ↓
Model updates properties
    ↓
UI bindings update automatically
    ↓
User sees changes on display
```

---

## 5. Responsive Design & Layouts

### 5.1 Breakpoints

```qml
// ui/qml/Constants.js
const BREAKPOINT_PHONE = 480;      // <480px: phone mode
const BREAKPOINT_TABLET = 768;     // 480-768px: tablet mode
const BREAKPOINT_DESKTOP = 1024;   // >1024px: desktop mode

function getLayout(width) {
    if (width < BREAKPOINT_PHONE)
        return "phone";
    else if (width < BREAKPOINT_DESKTOP)
        return "tablet";
    else
        return "desktop";
}
```

### 5.2 Responsive Page Example

```qml
// ui/qml/Pages/MediaPage.qml
import QtQuick
import QtQuick.Layouts
import "Constants.js" as Constants
import "../Components"

Page {
    id: mediaPage
    
    onWidthChanged: updateLayout()
    
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Album art
        Rectangle {
            id: albumArt
            Layout.alignment: Qt.AlignHCenter
            
            // Responsive size
            property int size: Math.min(300, parent.width - 32)
            width: size
            height: size
            radius: 10
            color: theme.cardColor
            
            Image {
                anchors.fill: parent
                source: mediaModel.albumArtUrl
                fillMode: Image.PreserveAspectCrop
            }
        }
        
        // Now playing info
        ColumnLayout {
            id: infoLayout
            Layout.fillWidth: true
            spacing: 8
            
            Text {
                text: mediaModel.trackTitle
                font.pointSize: 18
                font.bold: true
                color: theme.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                text: mediaModel.artistName
                font.pointSize: 14
                color: theme.secondaryTextColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        
        // Playback controls
        PlaybackControls {
            id: controls
            Layout.fillWidth: true
            Layout.preferredHeight: 80
        }
        
        // Seek bar
        PlaybackSeeker {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
        }
        
        // Responsive grid layout
        GridLayout {
            id: buttonGrid
            Layout.fillWidth: true
            columns: {
                if (mediaPage.width < 500)
                    return 2;  // 2 columns on phone
                else
                    return 4;  // 4 columns on tablet/desktop
            }
            rowSpacing: 12
            columnSpacing: 12
            
            Button { text: "Queue" }
            Button { text: "Repeat" }
            Button { text: "Shuffle" }
            Button { text: "More" }
        }
        
        Item { Layout.fillHeight: true }  // Spacer
    }
    
    function updateLayout() {
        console.log("Layout updated for width:", width);
        // Re-render as needed
        mainLayout.implicitWidth = width;
    }
}
```

---

## 6. Gesture & Touch Handling

### 6.1 Gesture Recognition

```qml
// ui/qml/Controls/TouchGestureHandler.qml
import QtQuick

MouseArea {
    id: gestureArea
    
    // Properties
    property real minDragDistance: 10  // px
    property real swipeVelocity: 200   // px/ms
    
    // Signals
    signal tapped(point position)
    signal longPressed(point position)
    signal swiped(string direction)  // "left", "right", "up", "down"
    signal rotated(real angle)       // For rotary gestures
    
    // Variables
    property point pressPos: Qt.point(0, 0)
    property int pressTime: 0
    property bool isDragging: false
    
    // Long press timer
    Timer {
        id: longPressTimer
        interval: 500  // 500ms for long press
        onTriggered: gestureArea.longPressed(gestureArea.pressPos)
    }
    
    // Mouse area handlers
    onPressed: {
        pressPos = Qt.point(mouse.x, mouse.y);
        pressTime = Date.now();
        isDragging = false;
        longPressTimer.start();
    }
    
    onPositionChanged: {
        let dx = mouse.x - pressPos.x;
        let dy = mouse.y - pressPos.y;
        let distance = Math.sqrt(dx*dx + dy*dy);
        
        if (distance > minDragDistance) {
            longPressTimer.stop();
            isDragging = true;
            
            // Determine swipe direction
            if (Math.abs(dx) > Math.abs(dy)) {
                // Horizontal swipe
                if (dx > 0) swiped("right");
                else swiped("left");
            } else {
                // Vertical swipe
                if (dy > 0) swiped("down");
                else swiped("up");
            }
        }
    }
    
    onReleased: {
        longPressTimer.stop();
        
        if (!isDragging) {
            tapped(Qt.point(mouse.x, mouse.y));
        }
    }
}
```

### 6.2 Volume Knob Gesture Example

```qml
// ui/qml/Controls/VolumeKnob.qml
import QtQuick

Item {
    id: knob
    width: 100
    height: 100
    
    property int volume: 50  // 0-100
    property real rotation: 0
    
    signal volumeChanged(int newVolume)
    
    // Visual representation
    Canvas {
        id: canvas
        anchors.fill: parent
        
        onPaint: {
            let ctx = getContext("2d");
            let centerX = width / 2;
            let centerY = height / 2;
            let radius = Math.min(width, height) / 2 - 5;
            
            // Draw knob circle
            ctx.fillStyle = theme.accentColor;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
            ctx.fill();
            
            // Draw volume indicator (needle)
            let angle = (knob.volume / 100) * (280 * Math.PI / 180) - 140 * Math.PI / 180;
            let needleX = centerX + Math.cos(angle) * (radius - 10);
            let needleY = centerY + Math.sin(angle) * (radius - 10);
            
            ctx.strokeStyle = "white";
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(centerX, centerY);
            ctx.lineTo(needleX, needleY);
            ctx.stroke();
        }
    }
    
    // Touch gesture handler for rotation
    GestureArea {
        anchors.fill: parent
        
        onRotated: {
            // angle is in degrees, map to volume 0-100
            knob.volume = Math.max(0, Math.min(100, angle / 3.6));
            canvas.requestPaint();
            volumeChanged(knob.volume);
        }
    }
}
```

---

## 7. i18n & Localization

### 7.1 String Resources

```qml
// ui/qml/i18n.qml
pragma Singleton
import QtQuick

QtObject {
    id: i18n
    
    property string language: "en-GB"
    
    property QtObject strings: QtObject {
        // Common strings
        readonly property string appName: qsTr("Crankshaft", "Application name")
        readonly property string home: qsTr("Home")
        readonly property string back: qsTr("Back")
        readonly property string ok: qsTr("OK")
        readonly property string cancel: qsTr("Cancel")
        readonly property string error: qsTr("Error")
        readonly property string loading: qsTr("Loading...")
        
        // Android Auto page
        readonly property string androidAuto: qsTr("Android Auto")
        readonly property string startProjection: qsTr("Start Projection")
        readonly property string stopProjection: qsTr("Stop Projection")
        readonly property string deviceConnected: qsTr("Device Connected")
        readonly property string deviceDisconnected: qsTr("Device Disconnected")
        
        // Media page
        readonly property string media: qsTr("Media")
        readonly property string playing: qsTr("Playing")
        readonly property string paused: qsTr("Paused")
        readonly property string stopped: qsTr("Stopped")
    }
    
    // Format strings with parameters
    function formatString(format, ...args) {
        return format.replace(/%s/g, () => args[0]);
    }
}
```

### 7.2 Translation Workflow

```bash
# Extract strings to .ts file
lupdate ui/qml/ -ts ui/i18n/crankshaft_en_GB.ts

# Translate to other languages
# vi ui/i18n/crankshaft_de_DE.ts
# vi ui/i18n/crankshaft_fr_FR.ts

# Compile .ts to .qm (binary format)
lrelease ui/i18n/*.ts -qm ui/i18n/

# In application startup:
# QTranslator translator;
# translator.load("crankshaft_de_DE", ":/i18n");
# app.installTranslator(&translator);
```

---

## 8. Theme System

### 8.1 Light/Dark Mode

```cpp
// ui/Theme.h
class Theme : public QObject {
    Q_OBJECT
    
    Q_PROPERTY(bool isDarkMode READ isDarkMode WRITE setIsDarkMode NOTIFY isDarkModeChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor NOTIFY isDarkModeChanged)
    Q_PROPERTY(QColor textColor READ textColor NOTIFY isDarkModeChanged)
    Q_PROPERTY(QColor accentColor READ accentColor NOTIFY isDarkModeChanged)
    
public:
    bool isDarkMode() const { return m_isDarkMode; }
    void setIsDarkMode(bool dark) {
        if (m_isDarkMode != dark) {
            m_isDarkMode = dark;
            emit isDarkModeChanged();
        }
    }
    
    QColor backgroundColor() const {
        return m_isDarkMode ? QColor("#121212") : QColor("#FFFFFF");
    }
    
    QColor textColor() const {
        return m_isDarkMode ? QColor("#FFFFFF") : QColor("#000000");
    }
    
    QColor accentColor() const {
        return QColor("#2196F3");  // Material Blue
    }
    
signals:
    void isDarkModeChanged();
    
private:
    bool m_isDarkMode = true;
};
```

### 8.2 QML Theme Usage

```qml
// ui/qml/Components/Card.qml
import QtQuick

Rectangle {
    id: card
    
    property var theme: null
    property alias title: titleText.text
    property alias content: contentText.text
    
    // Reactive color binding
    color: theme.isDarkMode ? "#1E1E1E" : "#FFFFFF"
    border.color: theme.isDarkMode ? "#333333" : "#EEEEEE"
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        
        Text {
            id: titleText
            font.bold: true
            color: theme.textColor  // Automatically updates
            font.pointSize: 14
        }
        
        Text {
            id: contentText
            color: theme.isDarkMode ? "#CCCCCC" : "#666666"
            font.pointSize: 12
            wrapMode: Text.Wrap
        }
    }
}
```

---

## 9. Performance Optimization

### 9.1 Rendering Optimization

```qml
// Avoid heavy re-renders
Item {
    id: optimizedItem
    
    // Use Loader for lazy loading
    Loader {
        sourceComponent: complexComponent
        asynchronous: true  // Load off-main-thread
    }
    
    // Use Canvas for drawing instead of many Rectangle items
    Canvas {
        id: graph
        // More efficient than 100 Rectangle items
    }
    
    // Cache images
    Image {
        cache: true  // Default true
        sourceSize: Qt.size(200, 200)  // Downscale on load
    }
}
```

### 9.2 Memory Management

```qml
// Use pooling for frequently created items
Component {
    id: buttonComponent
    Button { }
}

Repeater {
    model: listModel
    delegate: buttonComponent
    // Qt will reuse Button instances as list scrolls
}
```

---

## 10. Testing

### 10.1 QML Testing

```cpp
// tests/tst_UIComponents.cpp
#include <QtTest>
#include <QQmlEngine>

class UIComponentTest : public QObject {
    Q_OBJECT
    
private slots:
    void initTestCase() {
        engine = new QQmlEngine();
    }
    
    void testButtonClick() {
        QQmlComponent component(engine);
        component.setData("import QtQuick; Button { id: btn }", QUrl());
        
        Button* button = qobject_cast<Button*>(component.create());
        QVERIFY(button != nullptr);
        
        // Test click
        QSignalSpy clickSpy(button, SIGNAL(clicked()));
        button->click();
        QCOMPARE(clickSpy.count(), 1);
        
        delete button;
    }
    
private:
    QQmlEngine* engine;
};

#include "tst_UIComponents.moc"
```

---

## 11. Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Janky animations** | Stuttering, frame drops | Reduce delegates, use Canvas, profile with QML Profiler |
| **Memory leak** | Increasing memory over time | Check Connections cleanup, verify Loader unload |
| **Slow startup** | UI takes >2 seconds | Lazy load Pages, async image loading |
| **Gesture lag** | Delay in touch response | Reduce onPositionChanged work, use native gesture handler |
| **WebSocket timeout** | Lost core connection | Implement reconnect logic with backoff |

---

## 12. Documentation Checklist

- [x] QML structure and file organization
- [x] WebSocket client lifecycle
- [x] State management patterns
- [x] Responsive layout examples
- [x] Gesture handling implementation
- [x] i18n workflow
- [x] Theme system (light/dark)
- [x] Performance optimization techniques
- [ ] Component API reference
- [ ] UI testing guide

---

**End of UI Architecture Documentation**
