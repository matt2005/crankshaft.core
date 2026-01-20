# Coding and Documentation Guidelines

**Project:** Crankshaft  
**Version:** 1.0  
**Last Updated:** 2026-01-20  
**Language:** British English

## Table of Contents

1. [Overview](#overview)
2. [Documentation Standards](#documentation-standards)
3. [Code Structure Documentation](#code-structure-documentation)
4. [C++ Header Documentation](#c-header-documentation)
5. [Method Documentation Examples](#method-documentation-examples)
6. [Qt-Specific Documentation](#qt-specific-documentation)
7. [Architecture Documentation](#architecture-documentation)
8. [API Documentation](#api-documentation)
9. [Testing Documentation](#testing-documentation)
10. [Best Practices](#best-practices)

## Overview

Crankshaft uses a comprehensive documentation approach combining:
- **Inline Code Comments** - Explain implementation logic
- **Doxygen Comments** - Document API and interfaces
- **Architecture Diagrams** - Show component relationships
- **Usage Examples** - Demonstrate API usage patterns
- **Rationale Notes** - Explain design decisions and constraints

### Documentation Goals

1. Enable developers to understand code purpose without reading implementation
2. Provide IDE autocomplete and tooltip support (Doxygen + Qt tools)
3. Generate API documentation automatically
4. Maintain consistency across codebase
5. Explain constraints (e.g., Qt MOC limitations)
6. Link related concepts and files

## Documentation Standards

### File Headers

All source files must include GPL 3.0 header comment (see [project guidelines](../CODING_STANDARDS.md#file-headers)).

### Comment Style

```cpp
// Single-line comment for implementation details
// Use double-slash style consistently

/**
 * Multi-line documentation for public APIs
 * Uses Doxygen format for automatic doc generation
 */

/* Block comment for longer explanations in implementation */
```

### Doxygen Tags

Standard Doxygen tags used throughout codebase:

| Tag | Usage | Example |
|-----|-------|---------|
| `@brief` | One-line summary (required for public API) | `@brief Connect to Android Auto device` |
| `@param` | Document function parameter | `@param deviceId Unique device identifier` |
| `@return` | Document return value | `@return true if connection successful` |
| `@note` | Important implementation detail | `@note Thread-safe for Qt signals` |
| `@warning` | Critical caution | `@warning May block UI thread` |
| `@see` | Related documentation | `@see AndroidAutoFacade::connectToDevice()` |
| `@deprecated` | Mark as obsolete | `@deprecated Use newMethod() instead` |
| `@since` | Introduced in version | `@since 2026.01` |

## Code Structure Documentation

### Class Documentation

Every public class must include header documentation:

```cpp
/**
 * @brief Brief description of class purpose (one line)
 *
 * Longer description explaining:
 * - Main responsibility
 * - Key use cases
 * - Design pattern if applicable
 * - Important constraints or limitations
 *
 * @note Thread-safety characteristics
 * @see RelatedClass, AnotherRelated
 */
class MyClass : public QObject {
  Q_OBJECT
  // ...
};
```

### Enum Documentation

```cpp
/**
 * @brief Connection state enumeration
 *
 * Represents stages in the AndroidAuto connection lifecycle.
 * Values are used in both UI state display and internal routing.
 */
enum class ConnectionState {
  Disconnected = 0,  ///< Not connected; actively listening for devices
  Searching = 1,     ///< Scanning for compatible devices
  Connecting = 2,    ///< Connection in progress
  Connected = 3,     ///< Successfully connected to device
  Error = 4          ///< Error state; see lastError property
};
Q_ENUM(ConnectionState)
```

### Constant Documentation

```cpp
/// Maximum WebSocket message size in bytes
constexpr qint64 MAX_MESSAGE_SIZE = 1024 * 1024;

/// Default retry interval in milliseconds
constexpr int RETRY_INTERVAL_MS = 5000;
```

## C++ Header Documentation

### Public Methods

**Every public method must document:**

```cpp
/**
 * @brief What the method does (use imperative mood)
 *
 * Extended description explaining:
 * - Purpose and use case
 * - Side effects
 * - When to call this
 *
 * @param paramName Description of parameter
 *                  Can span multiple lines with proper indentation
 * @param another Another parameter
 *
 * @return Description of return value
 *         For void methods, omit @return
 *
 * @note Performance implications if any
 * @note Thread-safety if applicable
 * @warning Any preconditions or limitations
 *
 * @see RelatedMethod()
 * @see ../related/Header.h for context
 */
void methodName(const QString& paramName, int another);
```

### Private Methods

Document private methods with implementation detail comments:

```cpp
private:
  /// Extract device priority based on connection history and signal strength
  [[nodiscard]] auto calculateDevicePriority(const DetectedDevice& device) -> int;

  /// Validate incoming message structure against expected JSON schema
  [[nodiscard]] auto validateMessage(const QJsonObject& obj, QString& error) const -> bool;
```

### Signals and Slots

```cpp
signals:
  /**
   * @brief Emitted when connection state changes
   * @param state New connection state value
   * @see ConnectionState enum
   */
  void connectionStateChanged(int state);

private slots:
  /// Process incoming WebSocket message from client
  void onTextMessageReceived(const QString& message);
```

### Q_PROPERTY Documentation

```cpp
/**
 * @brief Current connection state
 *
 * Maps to core AndroidAutoService::ConnectionState values.
 * Possible values: Disconnected (0), Searching (1), Connecting (2),
 * Connected (3), Error (4).
 *
 * Read-only; changes emitted via connectionStateChanged signal.
 */
Q_PROPERTY(int connectionState READ connectionState NOTIFY connectionStateChanged)
```

## Method Documentation Examples

### Example 1: Simple Getter

```cpp
/**
 * @brief Get last reported error message
 * @return Error message text, empty string if no error
 */
[[nodiscard]] auto lastErrorMessage() const -> QString;
```

### Example 2: Service Command

```cpp
/**
 * @brief Report an error to UI layer
 *
 * Converts error code to user-friendly message and emits signal
 * for QML error dialog display.
 *
 * @param code Error code from ErrorCode enum
 * @param context Additional context (device name, service name, etc.)
 * @param severity Error severity level affecting UI presentation
 *
 * @note Asynchronous; does not block
 * @note Qt's MOC requires explicit return types for Q_INVOKABLE methods
 * @see ErrorCode enum for valid codes
 */
Q_INVOKABLE void reportError(ErrorCode code, const QString& context = QString(),
                             Severity severity = Severity::Error);
```

### Example 3: Complex Operation

```cpp
/**
 * @brief Load all stored preferences from persistent storage
 *
 * Attempts to load preferences from SQLite database at standard location.
 * If database is corrupted or missing, logs warning and returns empty map.
 *
 * @return QVariantMap containing all stored preferences
 *         Keys are preference names, values are QVariant (any type)
 *
 * @warning May block main thread; consider async version
 * @warning First call initialises database schema
 * @note Changes are not automatically persisted; call saveSettings()
 *
 * @see saveSettings()
 * @see PreferencesService::loadFromDatabase()
 */
[[nodiscard]] auto loadSettings() -> QVariantMap;
```

## Qt-Specific Documentation

### MOC Limitations

Always document Qt Meta-Object Compiler (MOC) constraints:

```cpp
/**
 * Q_INVOKABLE methods for QML interface
 * @note Qt's MOC (Meta-Object Compiler) cannot handle 'auto' keyword
 *       in method signatures. Explicit return types are required.
 *       See: https://doc.qt.io/qt-6/metaobjects.html
 *
 * Use targeted clang-tidy disables:
 *   // NOLINTBEGIN(modernize-use-trailing-return-type)
 *   Q_INVOKABLE void methodName();
 *   // NOLINTEND(modernize-use-trailing-return-type)
 */
```

### Signal/Slot Pattern

```cpp
signals:
  /**
   * @brief Emitted when device connection state changes
   *
   * @param state New ConnectionState value
   *
   * @note Connected to UI for real-time status updates
   * @note Emitted from event loop; safe to use from slots
   */
  void connectionStateChanged(int state);

private slots:
  /// Handle internal state machine transition; emits connectionStateChanged
  void onStateTransitionComplete();
```

## Architecture Documentation

### Service Architecture

Document the role of each service:

```cpp
/**
 * @brief Android Auto integration service
 *
 * Responsibilities:
 * - Device discovery (USB + Bluetooth)
 * - Connection lifecycle management
 * - Audio/video stream handling
 * - Error reporting and recovery
 *
 * Architecture:
 * - Wraps OpenAuto/AASDK library
 * - Emits Qt signals for state changes
 * - Runs in dedicated thread (not main UI thread)
 *
 * Integration Points:
 * - Signals: Used by WebSocketServer for client notification
 * - Slots: Called by UI for user-initiated actions
 * - EventBus: Publishes high-level events (connected, disconnected)
 *
 * Thread Safety:
 * - All methods thread-safe from any thread
 * - Signals/slots follow Qt thread-safe patterns
 *
 * Example Usage:
 *   auto* service = ServiceManager::instance()->getAndroidAutoService();
 *   connect(service, &AndroidAutoService::connectionStateChanged,
 *           this, &MyClass::onStateChanged);
 *   service->startDiscovery();
 */
```

### Module Interactions

```
┌─────────────────────────────────────────────────┐
│                    UI (QML)                      │
│          AndroidAutoFacade - DeviceManager      │
└────────────────┬────────────────────────────────┘
                 │ Signals/Slots, Q_INVOKABLE
┌────────────────┴────────────────────────────────┐
│              WebSocketServer                     │
│        (handles JSON message routing)            │
└────────────────┬────────────────────────────────┘
                 │ Qt Signals
┌────────────────┴────────────────────────────────┐
│            ServiceManager                        │
│         (lifecycle management)                   │
└────────────────┬────────────────────────────────┘
                 │ Manages services
    ┌────────────┼────────────┬──────────┐
    │            │            │          │
    ▼            ▼            ▼          ▼
 AndroidAuto  WiFi/BT   MediaPipeline Prefs
```

## API Documentation

### Complete Service Documentation Template

```cpp
/**
 * @file ServiceName.h
 * @brief Brief description of service
 *
 * Detailed description explaining:
 * - Purpose and responsibility
 * - Key features and capabilities
 * - Design patterns used
 * - Thread safety model
 * - Dependencies
 * - Usage example
 */

namespace Services {

/**
 * @class ServiceName
 * @brief One-line service description
 *
 * ### Purpose
 * What problem does this solve?
 * What is its primary responsibility?
 *
 * ### Features
 * - Feature 1 with brief description
 * - Feature 2
 * - Feature 3
 *
 * ### Usage Example
 * @code
 * auto* service = new ServiceName(config);
 * connect(service, &ServiceName::stateChanged,
 *         this, &MyClass::onStateChange);
 * service->initialize();
 * @endcode
 *
 * ### Thread Safety
 * All public methods are thread-safe.
 * Signals/slots follow Qt threading model.
 *
 * ### Dependencies
 * - Requires Qt 6.8+
 * - Uses AASDK library for AndroidAuto
 *
 * @see RelatedService
 * @see ../architecture/SERVICE_ARCHITECTURE.md
 */
class ServiceName : public QObject {
  // ...
};

}  // namespace Services
```

## Testing Documentation

### Test Class Documentation

```cpp
/**
 * @brief Test suite for AndroidAutoService
 *
 * Covers:
 * - Device discovery mechanism
 * - Connection state transitions
 * - Error handling and recovery
 * - Signal emission verification
 *
 * Test categories:
 * - Unit tests (isolated component testing)
 * - Integration tests (component interaction)
 * - End-to-end tests (full workflow)
 *
 * @note Requires AndroidAuto device or mock
 * @note Some tests may require special environment variables
 */
class TestAndroidAutoService : public QObject {
  Q_OBJECT
  // ...
};
```

### Test Method Documentation

```cpp
/// Test that device discovery initiates correctly
void testDiscoveryInitiation();

/// Test state transitions follow expected flow: Disconnected → Searching → Connecting
void testConnectionStateTransitions();

/// Test error recovery mechanism with exponential backoff
void testErrorRecoveryWithBackoff();
```

## Best Practices

### 1. Document the "Why", Not Just the "What"

**Bad:**
```cpp
/// Sets the volume
void setVolume(int volume);
```

**Good:**
```cpp
/**
 * @brief Set audio output volume
 *
 * Applies volume level to all active audio streams.
 * Called from UI volume slider or remote device control.
 * Clamped to 0-100 range; invalid values are rejected.
 *
 * @param volume Volume level (0-100)
 * @note Asynchronous; audio level changes smoothly over 200ms
 */
void setVolume(int volume);
```

### 2. Explain Constraints and Limitations

```cpp
/**
 * @note Qt's MOC cannot handle C++20 'auto' in Q_INVOKABLE signatures.
 *       Must use explicit return types. See commit 82d5ce1 for details.
 */

/**
 * @warning May block main UI thread. Consider running in background thread
 *          if processing large datasets (> 10,000 items).
 */
```

### 3. Cross-Reference Related Code

```cpp
/// See AndroidAutoService::startDiscovery() for discovery flow
/// See EventBus::publish() for event emission pattern
```

### 4. Document Enums Comprehensively

```cpp
enum class ErrorSeverity {
  Info,     ///< Informational, no action needed
  Warning,  ///< Warning, may affect functionality
  Error,    ///< Error, functionality impaired
  Critical  ///< Critical, application may not function
};
```

### 5. Include Usage Examples for Complex APIs

```cpp
/**
 * Example: Publish event to all subscribers
 * @code
 * eventBus.publish("android_auto/connected", {
 *   {"deviceId", "AA:BB:CC:DD:EE:FF"},
 *   {"deviceName", "Pixel 8"},
 *   {"connectionType", "USB"}
 * });
 * @endcode
 */
```

### 6. Keep Comments Updated with Code

When modifying code:
1. Update parameter documentation
2. Update return value documentation
3. Update notes about thread safety
4. Update examples if they're no longer accurate

### 7. Use Consistent Tense and Voice

- **Imperative mood for class/method descriptions:**
  - "Connect to device" ✓
  - "Is connecting to device" ✗

- **Passive voice for properties:**
  - "Audio stream status" ✓
  - "Is audio streaming" ✗ (too active)

### 8. Document Non-Obvious Design Decisions

```cpp
/**
 * @brief Convert trailing return type to traditional return syntax
 *
 * Design decision: Although modern C++20 prefers trailing return types
 * (auto methodName(...) -> ReturnType), Qt's MOC (Meta-Object Compiler)
 * cannot parse 'auto' keyword in Q_INVOKABLE method signatures.
 *
 * This is a hard constraint in Qt 6.x that cannot be worked around.
 * MOC processes header files before C++ compilation, so it cannot use
 * type deduction features.
 *
 * Solution: Use explicit return types for all Q_INVOKABLE methods.
 * Non-Q_INVOKABLE methods CAN use 'auto' for C++20 modernisation.
 *
 * References:
 * - https://doc.qt.io/qt-6/metaobjects.html
 * - Commit: 82d5ce1 (MOC constraint documentation)
 * - Issue: #27 (Fix: MOC compatibility and AA lifecycle test)
 */
```

## Documentation Checklist

Before submitting code for review:

- [ ] All public classes have `@brief` documentation
- [ ] All public methods have `@brief` + `@param` + `@return`
- [ ] All non-obvious implementation details have comments
- [ ] Thread-safety is documented (`@note` or in class docs)
- [ ] Constraints and limitations are documented (`@warning`, `@note`)
- [ ] Related code is cross-referenced (`@see`)
- [ ] Examples provided for complex APIs
- [ ] No outdated comments contradicting implementation
- [ ] Doxygen syntax is correct (tests with: `doxygen -d` in build)

## Tools and Generation

### Generate Doxygen Documentation

```bash
cd build
doxygen Doxyfile
# Output: build/doxygen/html/index.html
```

### IDE Integration

Most modern C++ IDEs support Doxygen comments:

- **VS Code + Clangd:**
  - Install "C/C++" extension by Microsoft
  - Hover over methods to see documentation

- **Qt Creator:**
  - Built-in support for Qt documentation
  - F1 on symbol shows documentation

- **CLion:**
  - Full Doxygen support
  - "Quick Documentation" with Ctrl+Q

---

**Document maintained by:** OpenCarDev Team  
**Last updated:** 2026-01-20  
**Language:** British English
