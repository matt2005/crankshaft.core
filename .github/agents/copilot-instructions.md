# crankshaft-mvp Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-31

## Active Technologies
- C++17 with Qt 6 (QML/Qt Quick Controls 6); QML for UI composition. + Qt Quick Controls 6, Qt Graphical Effects (if available), Qt Linguist for i18n, existing AndroidAuto integration via openauto/aasdk hooks (status + launch), existing settings/config modules. (005-modern-responsive-ui)
- Local config files (existing settings persistence; no new DB). (005-modern-responsive-ui)
- C++17 with Qt 6 (QML/Qt Quick Controls 6) + Qt Quick Controls 6, Qt Linguist (qsTr + .ts), CMake/Ninja toolchain (005-modern-responsive-ui)
- Existing settings/config service (QSettings-backed) with JSON export for tests; no new databases (005-modern-responsive-ui)

- (002-infotainment-androidauto)

## Project Structure

```text
backend/
frontend/
tests/
```

## Commands

# Add commands for 

## Code Style

: Follow standard conventions

## Recent Changes
- 005-modern-responsive-ui: Added C++17 with Qt 6 (QML/Qt Quick Controls 6) + Qt Quick Controls 6, Qt Linguist (qsTr + .ts), CMake/Ninja toolchain
- 005-modern-responsive-ui: Added C++17 with Qt 6 (QML/Qt Quick Controls 6); QML for UI composition. + Qt Quick Controls 6, Qt Graphical Effects (if available), Qt Linguist for i18n, existing AndroidAuto integration via openauto/aasdk hooks (status + launch), existing settings/config modules.
- 005-modern-responsive-ui: Added [if applicable, e.g., PostgreSQL, CoreData, files or N/A]


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
