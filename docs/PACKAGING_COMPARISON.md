# Packaging Approaches Comparison

## Executive Summary

**Recommendation: Use CPack (Approach 1) exclusively**

The project currently uses two different packaging approaches:
1. **CPack** (CMake's built-in packager) - Used for core and ui
2. **Custom shell script** - Used for ui-slim via `build-deb-slim-ui.sh`

**CPack is superior for maintainability, consistency, and CI/CD integration.**

---

## Current State

### Approach 1: CPack (Core & UI)

**Location**: `CMakeLists.txt` (lines 179-282)

**How it works**:
```cmake
# Component-based packaging
set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_COMPONENTS_ALL runtime development core ui ui-slim)

# Per-component metadata
set(CPACK_DEBIAN_CORE_PACKAGE_NAME "crankshaft-core")
set(CPACK_DEBIAN_CORE_PACKAGE_DEPENDS "...")
set(CPACK_DEBIAN_CORE_FILE_NAME DEB-DEFAULT)

install(TARGETS crankshaft-core
  RUNTIME DESTINATION bin
  COMPONENT core
)
```

**Build command**:
```bash
cd build
cpack --config CPackConfig.cmake -G DEB -C Release -B /output
```

**Produces**:
- `crankshaft-core_<version>_<arch>.deb`
- `crankshaft-ui_<version>_<arch>.deb`
- `crankshaft-slim-ui_<version>_<arch>.deb` (once ui-slim is properly registered)

---

### Approach 2: Custom Shell Script (UI-Slim)

**Location**: `scripts/build-deb-slim-ui.sh` (244 lines)

**How it works**:
```bash
# Manual directory structure creation
mkdir -p "${PACKAGE_BUILD_DIR}/DEBIAN"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/bin"
mkdir -p "${PACKAGE_BUILD_DIR}/usr/lib/systemd/system"

# Manual file copying
cp "${BUILD_DIR}/ui-slim/crankshaft-slim-ui" "${PACKAGE_BUILD_DIR}/usr/bin/"

# Manual control file generation
cat > "${PACKAGE_BUILD_DIR}/DEBIAN/control" <<EOF
Package: crankshaft-slim-ui
Version: ${VERSION}
Architecture: ${DEB_ARCH}
...
EOF

# Manual dpkg-deb invocation
dpkg-deb --build --root-owner-group "${PACKAGE_BUILD_DIR}" "${PACKAGE_DIR}/${PACKAGE_NAME}.deb"
```

**Build command**:
```bash
./scripts/build-deb-slim-ui.sh
```

**Produces**:
- `crankshaft-slim-ui_<version>_<arch>.deb`

---

## Detailed Comparison

### 1. Maintainability

| Aspect | CPack | Custom Script |
|--------|-------|---------------|
| Lines of code | ~100 (declarative) | ~244 (imperative) |
| Duplication | None (shared settings) | Duplicates logic from CMake |
| Updates needed | Single location | Multiple locations (CMakeLists + script) |
| Error prone | Low (CMake validates) | High (manual file operations) |
| Version sync | Automatic | Manual (must match CMakeLists) |

**Winner: CPack** - Changes in one place, validated by CMake.

---

### 2. Consistency

| Aspect | CPack | Custom Script |
|--------|-------|---------------|
| Naming convention | DEB-DEFAULT (automatic) | Manual formatting |
| Dependency format | Consistent | Inconsistent (see below) |
| File permissions | CMake-managed | Manual chmod commands |
| Directory structure | Standardised | Custom per script |
| Control fields | Validated | Freeform text |

**Dependency Inconsistency Example**:

CPack (CMakeLists.txt):
```cmake
set(CPACK_DEBIAN_UI_PACKAGE_DEPENDS 
  "crankshaft-core (>= ${NUMERIC_VERSION}), ${QT6_CORE_PKG}, ...")
```

Custom script:
```bash
Depends: crankshaft-core (>= 0.1.0), qt6-base-dev (>= 6.2), ...
```

**Issues**:
- Script hardcodes `0.1.0` instead of using `${NUMERIC_VERSION}`
- Script lists `-dev` packages (build deps) in runtime deps
- Script includes packages already pulled by transitive deps

**Winner: CPack** - Automated consistency and validation.

---

### 3. CI/CD Integration

| Aspect | CPack | Custom Script |
|--------|-------|---------------|
| Docker integration | Direct (1 command) | Requires extra scripting |
| GitHub Actions | Native support | Custom steps needed |
| Multi-arch builds | Automatic | Manual adaptation |
| Parallel builds | CMake handles it | Sequential script |
| Error reporting | CMake diagnostics | Shell exit codes |

**Current Docker build** (`docker/Dockerfile.build`):
```dockerfile
# CPack approach - single command for all packages
RUN cd build && \
    cpack --config CPackConfig.cmake -G DEB -C Release \
        -B /output 2>&1 | tee /build/logs/cpack-deb.log
```

**With custom script** (would require):
```dockerfile
RUN ./scripts/build-deb-slim-ui.sh 2>&1 | tee /build/logs/slim-ui-deb.log
```

**Winner: CPack** - Single command, better logging, native CMake integration.

---

### 4. Feature Parity

| Feature | CPack | Custom Script |
|---------|-------|---------------|
| Systemd services | ✅ Via CONTROL_EXTRA | ✅ Manual copy |
| Pre/post install | ✅ Via CONTROL_EXTRA | ✅ Manual copy |
| Changelog generation | ✅ Automatic | ✅ Manual template |
| Dependency calculation | ✅ ${shlibs:Depends} | ❌ Manual list |
| Component dependencies | ✅ Built-in | ❌ Manual checking |
| Source packages | ✅ CPackSource | ❌ Not implemented |
| Debug packages | ✅ Separate component | ❌ Not implemented |
| lintian integration | ⚠️ Manual | ⚠️ Optional |

**Winner: CPack** - More features with less effort.

---

### 5. Dependency Management

**CPack Advantages**:
- Automatic shlibs dependency calculation (`${shlibs:Depends}`)
- Component-level dependencies (ui-slim depends on core)
- Version variable substitution (`${NUMERIC_VERSION}`)
- Suite-specific packages (t64 vs non-t64)

**Custom Script Issues**:
```bash
# From build-deb-slim-ui.sh control file
Depends: crankshaft-core (>= 0.1.0), qt6-base-dev (>= 6.2), 
         qt6-declarative-dev (>= 6.2), qt6-multimedia-dev (>= 6.2)
```

**Problems**:
1. **Wrong packages**: Lists `-dev` packages (headers) instead of runtime libraries
2. **Hardcoded version**: `0.1.0` should be `${VERSION}`
3. **Over-specified**: Qt6 base pulls many transitive deps automatically
4. **No shlibs**: Misses automatically detected library dependencies

**Correct dependencies** (from CMakeLists.txt):
```cmake
set(CPACK_DEBIAN_UI_PACKAGE_DEPENDS 
  "crankshaft-core (>= ${NUMERIC_VERSION}), 
   ${QT6_CORE_PKG}, ${QT6_GUI_PKG}, ${QT6_QML_PKG}, ${QT6_QUICK_PKG}, 
   ${QT6_WS_PKG}, ${QML_RUNTIME_PKGS}, qt6-qpa-plugins")
```

**Winner: CPack** - Runtime libs only, variable substitution, validated.

---

### 6. Real-World Issues

**Issue #1: Missing ui-slim package**
- **Root cause**: `ui-slim` not in `CPACK_COMPONENTS_ALL`
- **Fix**: One line in CMakeLists.txt
- **With script**: Would have worked but with wrong dependencies

**Issue #2: Debian suite transitions**
- **CMakeLists.txt handles**:
  ```cmake
  if(CPACK_DEBIAN_PACKAGE_RELEASE STREQUAL "deb13")
    set(QT6_CORE_PKG "libqt6core6t64")  # Time64 transition
  else()
    set(QT6_CORE_PKG "libqt6core6")
  endif()
  ```
- **Script approach**: Would need manual updates for each suite

**Issue #3: Architecture detection**
- **CPack**: Automatic via `CPACK_DEBIAN_PACKAGE_ARCHITECTURE`
- **Script**: Manual case statement, duplicates CMake logic

---

### 7. Testing & Quality

| Aspect | CPack | Custom Script |
|--------|-------|---------------|
| Syntax validation | CMake parses at configure | Runtime errors |
| Dependency validation | dpkg-shlibdeps | Manual list |
| Package validation | CPack built-in | Must add lintian |
| Test coverage | CMake test targets | Separate validation |
| Reproducible builds | Yes (CMake cache) | Depends on env |

---

## Migration Plan

### Step 1: Verify CPack Configuration (✅ Done)

Added `ui-slim` to `CPACK_COMPONENTS_ALL` in commit 70b4425.

### Step 2: Fix ui-slim Dependencies

**Current state in CMakeLists.txt**:
```cmake
set(CPACK_DEBIAN_UI-SLIM_PACKAGE_DEPENDS 
  "crankshaft-core (>= ${NUMERIC_VERSION}), 
   ${QT6_CORE_PKG}, ${QT6_GUI_PKG}, ${QT6_QML_PKG}, ${QT6_QUICK_PKG}, 
   ${QT6_WS_PKG}, ${QML_RUNTIME_PKGS}, qt6-qpa-plugins")
```

**Issue**: Missing multimedia and AASDK dependencies.

**Fix needed**:
```cmake
set(CPACK_DEBIAN_UI-SLIM_PACKAGE_DEPENDS 
  "libaasdk0 (>= ${NUMERIC_VERSION}), 
   crankshaft-core (>= ${NUMERIC_VERSION}), 
   ${QT6_CORE_PKG}, ${QT6_GUI_PKG}, ${QT6_QML_PKG}, ${QT6_QUICK_PKG}, 
   ${QT6_WS_PKG}, ${QT6_MULTIMEDIA_PKG}, 
   ${QML_RUNTIME_PKGS}, qt6-qpa-plugins, 
   gstreamer1.0-plugins-base, gstreamer1.0-plugins-good, 
   gstreamer1.0-plugins-bad, gstreamer1.0-libav")
```

### Step 3: Remove Obsolete Files

Once CPack packaging is verified:
```bash
git rm scripts/build-deb-slim-ui.sh
git rm packaging/ui-slim/control  # Redundant with CMakeLists.txt
```

Keep:
- `packaging/ui-slim/postinst` - Used by CPack
- `packaging/ui-slim/prerm` - Used by CPack
- `packaging/ui-slim/crankshaft-slim-ui.service` - Used by CPack

### Step 4: Update Documentation

Update any references to `build-deb-slim-ui.sh` in:
- README.md
- Build instructions
- CI/CD documentation

---

## Best Practices (Going Forward)

### 1. Always Use CPack for New Components

When adding new components:
```cmake
# 1. Add to components list
set(CPACK_COMPONENTS_ALL runtime development core ui ui-slim NEW_COMPONENT)

# 2. Define component metadata
set(CPACK_COMPONENT_NEW_COMPONENT_DISPLAY_NAME "Display Name")
set(CPACK_COMPONENT_NEW_COMPONENT_DESCRIPTION "Description")
set(CPACK_COMPONENT_NEW_COMPONENT_DEPENDS core)  # Dependencies

# 3. Define Debian package metadata
set(CPACK_DEBIAN_NEW_COMPONENT_PACKAGE_NAME "package-name")
set(CPACK_DEBIAN_NEW_COMPONENT_PACKAGE_DEPENDS "deps...")
set(CPACK_DEBIAN_NEW_COMPONENT_FILE_NAME DEB-DEFAULT)

# 4. Install targets with component
install(TARGETS my-target
  RUNTIME DESTINATION bin
  COMPONENT NEW_COMPONENT
)
```

### 2. Component Naming Convention

- CMake component: `new-component` (lowercase, hyphens)
- CPack variable: `NEW_COMPONENT` (uppercase, underscores)
- Package name: `crankshaft-new-component` (lowercase, hyphens)

### 3. Dependency Management

**Runtime deps only**:
```cmake
# ✅ Good
set(CPACK_DEBIAN_UI_PACKAGE_DEPENDS "${QT6_CORE_PKG}, ${QT6_GUI_PKG}")

# ❌ Bad - don't include -dev packages
set(CPACK_DEBIAN_UI_PACKAGE_DEPENDS "qt6-base-dev, qt6-declarative-dev")
```

**Use variables for version-dependent packages**:
```cmake
if(CPACK_DEBIAN_PACKAGE_RELEASE STREQUAL "deb13")
  set(QT6_CORE_PKG "libqt6core6t64")
else()
  set(QT6_CORE_PKG "libqt6core6")
endif()
```

### 4. Testing Packages Locally

```bash
# Build all packages
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_SLIM_UI=ON ..
make -j$(nproc)
cpack -G DEB -C Release

# Verify package
dpkg-deb --info crankshaft-slim-ui_*.deb
dpkg-deb --contents crankshaft-slim-ui_*.deb

# Test dependencies
dpkg-deb --field crankshaft-slim-ui_*.deb Depends

# Install locally
sudo apt install ./crankshaft-slim-ui_*.deb
```

---

## Conclusion

**CPack provides**:
- ✅ Single source of truth (CMakeLists.txt)
- ✅ Automatic dependency calculation
- ✅ Version variable substitution
- ✅ Suite-specific package handling
- ✅ Component-based builds
- ✅ Native CMake/Docker/CI integration
- ✅ Less code to maintain
- ✅ Better error detection
- ✅ Consistent naming and structure

**Custom scripts require**:
- ❌ Duplicate logic
- ❌ Manual dependency lists (often wrong)
- ❌ Manual version management
- ❌ Extra CI/CD steps
- ❌ More code to maintain
- ❌ More potential for errors

**Action Items**:
1. ✅ Add ui-slim to CPACK_COMPONENTS_ALL (Done: commit 70b4425)
2. ⬜ Fix ui-slim dependencies in CMakeLists.txt
3. ⬜ Verify CPack builds all packages correctly
4. ⬜ Remove `scripts/build-deb-slim-ui.sh`
5. ⬜ Remove `packaging/ui-slim/control`
6. ⬜ Update documentation

---

## References

- [CPack Documentation](https://cmake.org/cmake/help/latest/module/CPack.html)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- [Debian Package Dependencies](https://www.debian.org/doc/debian-policy/ch-relationships.html)
- [CMake Component Installation](https://cmake.org/cmake/help/latest/command/install.html)
