# Fix Summary: Qt6 Bluetooth & GUI linkage + AndroidAutoService TCP support

- Date: 2025-12-18
- Affected areas:
  - Core (crankshaft-core target) linkage to Qt6 Bluetooth
  - Test targets linkage to Qt6 GUI
  - AndroidAutoService TCP transport channel setup

## Root Causes

1. **ServiceManager.cpp includes BluetoothManager.h** which uses `QBluetoothAddress` (from Qt6 Connectivity). The core target did not link Qt6 Bluetooth, resulting in:
   ```
   fatal error: QBluetoothAddress: No such file or directory
   ```

2. **test_websocket target includes AndroidAutoService.cpp**, which includes `MockAndroidAutoService.h`. The mock header includes `<QImage>` (from Qt6 Gui), but tests did not link Qt6::Gui:
   ```
   fatal error: QImage: No such file or directory
   ```

3. **RealAndroidAutoService::setupTCPTransport()** called undefined method `setupChannelsWithTransport()`. The USB path used `setupChannels()` which creates transport internally; TCP needs a variant assuming transport already exists.

## Changes

### 1. core/CMakeLists.txt
- Added `Bluetooth` to `find_package(Qt6 REQUIRED COMPONENTS ... Bluetooth)`.
- Added `Qt6::Bluetooth` to `target_link_libraries(crankshaft-core PRIVATE ...)`.

### 2. Top-level CMakeLists.txt (root)
- Added `set(QT6_BT_PKG "libqt6bluetooth6")` for packaging.
- Included `${QT6_BT_PKG}` in `CPACK_DEBIAN_CORE_PACKAGE_DEPENDS` for runtime dependency.

### 3. tests/CMakeLists.txt
- Added `Qt6::Gui` to `target_link_libraries(test_websocket PRIVATE ...)` to resolve QImage.

### 4. core/services/android_auto/RealAndroidAutoService.h
- Declared `void setupChannelsWithTransport();` (was called but not declared).

### 5. core/services/android_auto/RealAndroidAutoService.cpp
- Implemented `setupChannelsWithTransport()` (~180 lines):
  - Creates SSL `Cryptor` and `Messenger` using existing `m_transport` and `m_ioService`.
  - Sets up all configured channels (video, audio, input, sensor, Bluetooth).
  - Initialises `GStreamerVideoDecoder` and `AudioMixer` with identical logic to `setupChannels()`.
  - Logs with TCP context to distinguish from USB path.

## Outcome

- Core target now compiles with Bluetooth header access.
- test_websocket target compiles with GUI header access.
- RealAndroidAutoService supports both USB (via `setupChannels`) and TCP (via `setupChannelsWithTransport`) transports.
- CI Docker packaging (with `-DBUILD_TESTS=OFF`) avoids pulling test dependencies into production builds.

## Follow-ups

- If CI still reports errors:
  - Check for any missing AASDK component includes in RealAndroidAutoService*.
  - Verify all MockAndroidAutoService includes (QImage, Qt containers) are properly covered by Qt6::Gui linkage.
  - Ensure AASDK is properly exported (libaasdk0 and libaasdk-dev packages) so crankshaft-core can link it.

## Files Modified

1. `core/CMakeLists.txt`
2. `CMakeLists.txt` (root)
3. `tests/CMakeLists.txt`
4. `core/services/android_auto/RealAndroidAutoService.h`
5. `core/services/android_auto/RealAndroidAutoService.cpp`

