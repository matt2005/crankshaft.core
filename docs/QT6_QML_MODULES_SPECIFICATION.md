# Qt6 QML Modules Specification

**Date**: January 8, 2026  
**Reference**: https://www.invisto.be/blog/introduction-to-qml-modules-in-qt6  
**Status**: Final

## Overview

This document captures critical knowledge about Qt6 QML module architecture as it applies to Crankshaft. This prevents repeated mistakes during development and clarifies the reasoning behind architectural decisions.

## Current Architecture: Single Consolidated Module

Crankshaft uses a **single `Crankshaft` QML module** containing:

### Module Contents

- **Screens** (5): Main, HomeScreen, SettingsScreen, AndroidAutoScreen, ToolsPage, ProfilesPage, WiFiSettingsPage, BluetoothSettingsPage
- **Components** (7): AppButton, Card, DrivingModeIndicator, Icon, LocaleSelector, SystemClock, Tile
- **Models** (3): SettingsModel (singleton), Strings (singleton), AndroidAutoStatus (singleton)
- **JavaScript** (1): MaterialDesignIcons.js
- **Resources**: Material Design Icons font, SVG assets, Material Design Icons.js utility

### Import Syntax

```qml
import Crankshaft 1.0

// Can use any type in the module
HomeScreen { }
AppButton { }
SettingsModel { }
```

## Why Not Split Modules?

Previous attempts to create separate `Crankshaft.Components` module failed due to CMake's strict metatype generation requirements:

### Technical Problem

Qt6's `qt_add_qml_module()` CMake function **always attempts metatype generation** for type registration. This process requires:
- Either `AUTOMOC ON` (which needs C++ files to process)
- Or a manual list of pre-generated `.json` metatype files

### Why QML-Only Modules Fail

Splitting components into a separate QML-only module creates a circular dependency:
- The component module has no C++ code (QML-only)
- CMake still tries to generate metatypes
- Without AUTOMOC or C++ files, metatype generation fails
- CMake error: "Metatype generation requires either the use of AUTOMOC or a manual list of generated json files"

### Solutions Attempted

1. **Separate modules with NO_GENERATE_QMLDIR**: Failed - CMake still expects metatypes
2. **Stub C++ file in components module**: Failed - AUTOMOC still requires actual C++ processing
3. **Manual metatype JSON files**: Not practical - requires maintaining separate .json files

### Why Single Module Works

- Main executable has C++ code (`main.cpp`, `WebSocketClient.cpp`, etc.)
- `qt_add_qml_module()` can use AUTOMOC from the main executable
- All QML files listed in single module = all types registered together
- No circular dependencies between modules
- Simpler build process, fewer CMake complications

## CMakeLists.txt Pattern

```cmake
qt_add_executable(crankshaft-ui
  main.cpp
  WebSocketClient.cpp
  SettingsRegistry.cpp
)

set_target_properties(crankshaft-ui PROPERTIES
  AUTOMOC ON
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/ui
)

qt_add_qml_module(crankshaft-ui
  URI Crankshaft
  VERSION 1.0
  NO_PLUGIN_OPTIONAL
  NO_GENERATE_QMLDIR
  QML_FILES
    qml/screens/Main.qml
    qml/screens/HomeScreen.qml
    qml/components/AppButton.qml
    qml/components/Card.qml
    qml/models/SettingsModel.qml
  RESOURCES
    assets/icons/mdi.svg
    qmldir
)

target_link_libraries(crankshaft-ui PRIVATE
  Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::WebSockets
)
```

## qmldir File Format

Located at `ui/qmldir`, declares all importable types:

```
module Crankshaft
typeinfo crankshaft-ui.qmltypes
prefer :/qt/qml/Crankshaft/

# Screens
Main 1.0 qml/screens/Main.qml
HomeScreen 1.0 qml/screens/HomeScreen.qml
SettingsScreen 1.0 qml/screens/SettingsScreen.qml

# Components
AppButton 1.0 qml/components/AppButton.qml
Card 1.0 qml/components/Card.qml
DrivingModeIndicator 1.0 qml/components/DrivingModeIndicator.qml

# Singletons
singleton SettingsModel 1.0 qml/models/SettingsModel.qml
singleton Strings 1.0 qml/models/Strings.qml
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `module Crankshaft` | Defines module URI for imports |
| `typeinfo crankshaft-ui.qmltypes` | Points to auto-generated type info file |
| `prefer :/qt/qml/Crankshaft/` | Namespace path in resource filesystem |
| `TypeName 1.0 path/to/file.qml` | Type declaration with version and file location |
| `singleton TypeName 1.0 path/to/file.qml` | Singleton instance (only one instantiated globally) |

## CMake Qt_add_qml_module() Options

| Option | Purpose |
|--------|---------|
| `URI` | Import namespace (e.g., `Crankshaft`) |
| `VERSION` | Module version (e.g., `1.0`) |
| `QML_FILES` | List all .qml and .js files to include in module |
| `RESOURCES` | Non-QML files (qmldir, fonts, SVG assets) |
| `NO_PLUGIN_OPTIONAL` | Always load module; don't make it optional |
| `NO_GENERATE_QMLDIR` | Use manual qmldir instead of auto-generated |
| `DEPENDS` | Other modules this module depends on (rarely used) |

## Automatic Build Steps

When `qt_add_qml_module()` is invoked, CMake automatically:

1. **Collects QML files**: Processes all files in `QML_FILES` list
2. **Generates metatypes**: Creates `crankshaft-ui.qmltypes` file with type information
3. **Creates QML cache**: Generates `.cpp` files in `.rcc/qmlcache/` for each QML file
4. **Registers types**: Uses qmldir to make types discoverable by QML engine
5. **Validates syntax**: Runs qmllint on all QML files (enforces code style)
6. **Embeds in binary**: All QML files, cache, and resources compiled into executable

## Runtime Type Resolution

When QML engine encounters an import:

```qml
import Crankshaft 1.0
```

It searches for `crankshaft-ui.qmltypes` and `qmldir` in:
1. Built-in resource paths (`:/qt/qml/`)
2. Qt installation QML directories
3. Environment variable `QML_IMPORT_PATH`
4. Application-specific paths

Once found, qmldir declares available types for that URI.

## Troubleshooting Guide

### Build-Time Errors

**"Metatype generation requires AUTOMOC or manual list of json files"**
- **Cause**: QML module defined without C++ backing and AUTOMOC not enabled
- **Solution**: Ensure main executable has AUTOMOC ON before qt_add_qml_module() call
- **Prevention**: Always define qt_add_qml_module() after the executable, not before

**"Cannot find file: qmldir" or "file not found in resources"**
- **Cause**: qmldir file missing or not listed in RESOURCES
- **Solution**: 
  1. Verify qmldir exists at `ui/qmldir`
  2. Add `qmldir` to `RESOURCES` section in CMakeLists
  3. Rebuild from clean (rm -rf build)

### Runtime Errors on Device

**"module Crankshaft is not installed"**
- **Cause**: QML engine cannot find Crankshaft module in runtime
- **Solution**:
  1. Verify binary was deployed (not old binary)
  2. Check binary contains qml cache files: `strings build/ui/crankshaft-ui | grep -i qml`
  3. Verify qmldir is in RESOURCES section of CMakeLists

**"SystemClock is not a type"**
- **Cause**: Component type declared in code but not in qmldir
- **Solution**:
  1. Add type to qmldir: `SystemClock 1.0 qml/components/SystemClock.qml`
  2. Verify file is in QML_FILES list in CMakeLists
  3. Rebuild and redeploy binary

## Design Decisions Rationale

### Decision: Single Module vs. Split Modules

**Rationale**:
- Qt6 CMake system designed primarily for C++/QML hybrid modules
- QML-only modules work better when consolidated
- Simplifies build process and reduces CMake complexity
- Avoids circular dependency issues with module linking
- Easier to maintain - one qmldir file, one metatype file

**Trade-offs**:
- Less granular organization (all types in one namespace)
- Harder to organize components as components become numerous
- Future refactoring needed if module grows significantly (>50 types)

**Future Direction**:
If the module grows beyond 50+ types, consider introducing:
- `Crankshaft.Screens` namespace for screens only
- `Crankshaft.Models` namespace for singletons
- Each with proper C++ backing (stub classes with QML_ELEMENT)

## Qt6 QML Module Documentation

Key Qt6 references:
- Qt6 CMake API: https://doc.qt.io/qt-6/qt-add-qml-module.html
- Writing QML Modules: https://doc.qt.io/qt-6/qtqml-writing-a-module.html
- QML Type System: https://doc.qt.io/qt-6/qtqml-typesystem-basics.html

## Summary

✅ **Current Approach Works**: Single consolidated Crankshaft module with all types
✅ **Automatic CMake Handling**: qt_add_qml_module() handles most complexity
✅ **No Manual Files**: qmldir and qmltypes auto-generated (with NO_GENERATE_QMLDIR override)
✅ **Type Registration**: All types properly registered and discoverable
✅ **Device Deployment**: Binary contains all needed QML infrastructure

⚠️ **Avoid**: Attempting to create separate QML-only modules without C++ backing
⚠️ **Remember**: Keep qmldir in RESOURCES, keep AUTOMOC enabled on executable
⚠️ **Future**: Plan for module split if types exceed ~50-60 items

---

## 7. Implementation Status - COMPLETE ✅

**Status: VERIFIED & TESTED**

Successfully implemented split QML modules using the Qt-recommended STATIC library pattern:

### Final Architecture

1. **Crankshaft.Components (Static Library)**
   - C++ backing: `ui/qml/components/CrankshaftComponents.h` (stub header with AUTOMOC)
   - Contains 7 reusable components: AppButton, Card, DrivingModeIndicator, Icon, LocaleSelector, SystemClock, Tile
   - JavaScript helper (MaterialDesignIcons.js) declared with QT_QML_SKIP_QMLDIR_ENTRY
   - Built as static library (not shared object)
   - Plugin automatically created: `crankshaft-ui-componentsplugin`

2. **Crankshaft (Main Module)**
   - Contains all screens, models, and app-level components
   - Depends on Crankshaft.Components module
   - Links crankshaft-ui-componentsplugin into final executable
   - Declares Q_IMPORT_QML_PLUGIN(Crankshaft_ComponentsPlugin) in main.cpp

3. **Single Binary Architecture**
   - Both QML modules compile into single `crankshaft-ui` executable
   - No runtime module loading needed
   - Module resolution happens at link time via plugin registration
   - Resource embedding via Qt RCC system (qml cache files)

### Verification Results

```
Build:            ✅ cmake configure + cmake --build completed successfully
Configuration:    ✅ No "Metatype generation requires AUTOMOC" errors
QML Module Load:  ✅ "[STARTUP] 948 ms elapsed: QML module loaded" confirmed
Runtime:          ✅ Application starts, all modules resolve correctly
Imports:          ✅ HomeScreen and other screens import Crankshaft.Components 1.0
```

### Key Technical Solutions

| Problem | Solution | Implementation |
|---------|----------|-----------------|
| Metatype generation errors | AUTOMOC on STATIC library | `set_target_properties(crankshaft-ui-components PROPERTIES AUTOMOC ON)` |
| Module resolution | Q_IMPORT_QML_PLUGIN macro | Added to main.cpp before main() |
| JS helper warning | QT_QML_SKIP_QMLDIR_ENTRY | Separated MaterialDesignIcons.js as resource |
| Plugin linking | Static library dependency | Link `crankshaft-ui-componentsplugin` into main executable |
| Multiple modules in binary | qt_add_library(STATIC) + qt_add_qml_module | Qt6-recommended pattern from official docs |

### Reference Documentation

- **Qt Official Pattern**: https://doc.qt.io/qt-6/qtqml-writing-a-module.html#multiple-qml-modules-in-one-binary
- **Implementation Commits**:
  - a858e3: Split QML modules with STATIC library pattern (FINAL)
  - c7bbcdc: Qt-recommended pattern with Q_IMPORT_QML_PLUGIN
  - bb97481: Specification document

### Design Rationale

This implementation follows Qt6's official recommendation for "Multiple QML Modules in One Binary" because:
1. Single executable deployment (no separate .so files)
2. Proper module namespacing (Crankshaft vs. Crankshaft.Components)
3. Clean separation of concerns (components library separate from main app)
4. Future-proof for adding more modules (AndroidAuto, MediaPlayer, etc.)
5. Proper type registration via automatic qmltypes generation

