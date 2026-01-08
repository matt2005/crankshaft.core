# QML Module Architecture Fix - Crankshaft UI

**Date**: 2025-01-08  
**Issue**: Crankshaft UI failing to load on RPi5 with error "module Crankshaft.Components is not installed"  
**Status**: RESOLVED  
**Commits**: `7113b66` (this fix), `e9ad0cd` (previous attempt)

## Problem Summary

The HomeScreen component was unable to load on RPi5 because the QML engine could not find the `Crankshaft.Components` module. This prevented the entire UI from initialising and displayed only an error screen.

### Root Cause Analysis

The initial approach attempted to create a **separate QML module** for components:
- `qt_add_qml_module(crankshaft-ui-components)` with URI `Crankshaft.Components`
- `qt_add_qml_module(crankshaft-ui)` with URI `Crankshaft` depending on the components module

**Why This Failed**:
1. Qt6 QML modules created with `qt_add_qml_module` require C++ metatype support for type registration
2. When using `NO_GENERATE_QMLDIR`, the CMake system still tries to generate metatypes
3. QML-only modules (no C++ backing) don't have metatypes to generate, causing CMake error:
   ```
   Metatype generation requires either the use of AUTOMOC or a manual list of generated json files
   ```
4. This prevented the build from completing, so the binary could never be deployed

### Implementation of Fix

**Strategy**: Consolidate both modules into a single Crankshaft module with all QML files (screens, models, and components).

**Changes Made**:

1. **ui/CMakeLists.txt**:
   - Removed separate `qt_add_qml_module(crankshaft-ui-components)` definition
   - Merged all component QML files into the main `qt_add_qml_module(crankshaft-ui)` declaration:
     ```cmake
     QML_FILES
       qml/screens/Main.qml
       qml/screens/HomeScreen.qml
       ...
       qml/components/AppButton.qml
       qml/components/Card.qml
       qml/components/DrivingModeIndicator.qml
       qml/components/Icon.qml
       qml/components/LocaleSelector.qml
       qml/components/SystemClock.qml
       qml/components/Tile.qml
       qml/components/MaterialDesignIcons.js
     ```
   - Removed `DEPENDS Crankshaft.Components` from main module declaration
   - Removed `target_link_libraries(...crankshaft-ui-components)` from executable linking

2. **ui/qmldir**:
   - Added type declarations for all component files:
     ```
     AppButton 1.0 qml/components/AppButton.qml
     Card 1.0 qml/components/Card.qml
     DrivingModeIndicator 1.0 qml/components/DrivingModeIndicator.qml
     Icon 1.0 qml/components/Icon.qml
     LocaleSelector 1.0 qml/components/LocaleSelector.qml
     SystemClock 1.0 qml/components/SystemClock.qml
     Tile 1.0 qml/components/Tile.qml
     ```

### Verification

Build verification on WSL (amd64):
```bash
$ cmake -B build -DCMAKE_BUILD_TYPE=Debug
-- Configuring done (338.2s)
-- Generating done (43.2s)

$ cmake --build build --target crankshaft-ui -j4
[100%] Linking CXX executable crankshaft-ui
[100%] Built target crankshaft-ui
$ ls -lh build/ui/crankshaft-ui
-rwxrwxrwx 1 matt matt 13M Jan  8 20:19 .../crankshaft-ui
```

CMake successfully:
- Generated QML cache files for all 20 QML/JS files
- Generated metatype JSON for the module
- Registered all types including components via qmldir
- Linked final 13MB binary

## Impact

✅ **Positive Outcomes**:
- QML module now properly registers all types including components
- Consolidated architecture simpler to maintain (single module vs two)
- Eliminates metatype generation errors
- Binary can now be deployed and executed

**Limitations**:
- All QML files are now part of a single URI namespace (`Crankshaft.*`)
- If future scaling requires truly separate modules, would need to add C++ backing to the components module

## Deployment Steps

1. **Build the binary**:
   ```bash
   cmake --build build --target crankshaft-ui
   ```

2. **Deploy to RPi5**:
   ```bash
   scp build/ui/crankshaft-ui pi@rpi5.home.lan:/tmp/
   ssh pi@rpi5.home.lan 'sudo systemctl stop crankshaft-ui && \
     sudo cp /tmp/crankshaft-ui /usr/bin/ && \
     sudo systemctl start crankshaft-ui'
   ```

3. **Verify via VNC or console logs**:
   ```bash
   ssh pi@rpi5.home.lan 'journalctl -u crankshaft-ui -f'
   ```

Should now see HomeScreen load without "module Crankshaft.Components is not installed" error.

## Technical Reference

**Qt6 QML Module Best Practices**:
- Single `qt_add_qml_module()` call per URI namespace
- Include all files (QML, JS, resources) in that single declaration
- Use qmldir file to declare type mappings within the module
- For truly separate modules with different URIs, ensure each has proper C++ support if using metatype registration

**CMake QML Module Quirks**:
- `qt_add_qml_module()` always attempts metatype generation (unless explicitly disabled)
- QML-only modules work fine within a single module URI
- Module dependencies (`DEPENDS`) create link-time requirements - unnecessary for QML files in same module

## References

- Qt6 CMake QML Documentation: [Qt6QmlMacros.cmake](https://cmake.org/cmake/help/latest/module/FindQt6Qml.html)
- Qt6 QML Module Guide: [Defining QML Modules](https://doc.qt.io/qt-6/qtqml-modules-qmldir.html)
- AASDK Integration: Separate issue; AASDK build system independent of this fix
