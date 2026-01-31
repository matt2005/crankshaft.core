# Protobuf v30.0 Packaging Strategy

## Overview

This document describes the shared protobuf packaging strategy for OpenCarDev projects. Google Protobuf v30.0 is built once by AASDK and published as DEB packages, which are then consumed by crankshaft.core and other projects.

## Architecture

### AASDK Repository (aasdk)

**Purpose**: Build and publish protobuf v30.0 as reusable DEB packages

**Components**:
- `aasdk/protobuf/CMakeLists.txt` - Builds protobuf v30.0 with Abseil from FetchContent
- `aasdk/.github/workflows/protobuf-build.yml` - CI/CD workflow that builds and publishes packages

**Process**:
1. CMake FetchContent downloads protobuf v30.0 and abseil-cpp
2. Protobuf is configured with C++20 support and shared libraries enabled
3. CPack generates two DEB packages:
   - `aap-protobuf` - Runtime libraries (libprotobuf.so, libabsl_*.so)
   - `aap-protobuf-dev` - Development files (headers, protoc compiler, CMake configs)
4. GitHub Actions uploads packages as workflow artifacts
5. Packages are eventually published to opencardev APT repository

**Key CMake Settings**:
```cmake
set(protobuf_BUILD_SHARED_LIBS ON)     # Build shared libraries
set(protobuf_INSTALL ON)                # Enable install rules
set(protobuf_ABSL_PROVIDER "package")   # Use fetched Abseil
```

**CPack Configuration**:
- Package Name: `aap-protobuf`
- Components: `runtime` and `development`
- Auto-computes dependencies via `CPACK_DEBIAN_PACKAGE_SHLIBDEPS`
- Generates separate packages for runtime and development

### Crankshaft.core Repository (opencardev/crankshaft.core)

**Purpose**: Consume pre-built protobuf packages for building crankshaft

**Dependency Model**:
- When `BUILD_AASDK=true`: Builds AASDK (including protobuf) from submodule
- When `BUILD_AASDK=false`: **Requires** `aap-protobuf` and `aap-protobuf-dev` from APT

**Error Handling**:
If `BUILD_AASDK=false` and packages are not available:
```
ERROR: aap-protobuf packages not found in APT repository
AASDK must build and publish protobuf packages before crankshaft.core can build
Either: 1) Set BUILD_AASDK=true to build from submodule
        2) Ensure aap-protobuf DEB packages are published to opencardev APT repo
```

## Build Flow

### Scenario 1: Full Build (BUILD_AASDK=true)
```
crankshaft.core build
  → Build AASDK from submodule
    → FetchContent downloads protobuf v30.0
    → Builds protobuf with AASDK code
    → Installs to /build/install
  → Build crankshaft with installed AASDK
```

### Scenario 2: Package Consumption (BUILD_AASDK=false)
```
crankshaft.core build
  → Check for aap-protobuf(-dev) in APT
    → If found: Install packages, use their libraries/headers
    → If NOT found: FAIL BUILD with clear error message
  → Build crankshaft with system packages
```

## Publishing Workflow

### Prerequisites
1. AASDK repository has protobuf/ folder with CMakeLists.txt + CPack config
2. GitHub Actions workflow (.github/workflows/protobuf-build.yml) is active
3. opencardev APT repository is configured to accept DEB uploads

### Steps
1. **Push trigger**: Changes to `aasdk/protobuf/` trigger protobuf-build workflow
2. **Build**: Workflow runs on ubuntu-latest, builds protobuf v30.0
3. **Package**: CPack generates `aap-protobuf_*.deb` and `aap-protobuf-dev_*.deb`
4. **Publish**: Upload to opencardev APT repository (manual step or automated via release workflow)
5. **Consume**: Crankshaft.core can now build with `BUILD_AASDK=false`

## Version Alignment

| Component | Version | Source |
|-----------|---------|--------|
| Google Protobuf | v30.0 | aasdk/protobuf via FetchContent |
| Abseil | 20240722.0 LTS | aasdk/protobuf via FetchContent |
| C++ Standard | C++20 | Both projects |
| CMake | 3.16+ | Requirement |

## Troubleshooting

### Issue: "aap-protobuf packages not found"
**Solution**: 
1. Ensure AASDK protobuf-build workflow has run and published packages
2. Verify packages are in the opencardev APT repository
3. Or set `BUILD_AASDK=true` to build from submodule

### Issue: Protobuf version mismatch
**Solution**: 
- Both projects must use the same version (v30.0)
- Check `aasdk/protobuf/CMakeLists.txt` for FetchContent version
- Check crankshaft.core imports for version requirements

### Issue: Build succeeds but missing protobuf symbols
**Solution**: 
- Ensure `aap-protobuf` runtime package is installed (not just -dev)
- Verify library paths: `LD_LIBRARY_PATH` should include `/usr/lib`
- Run `ldd` on binaries to check library dependencies

## Files Modified

### AASDK
- `protobuf/CMakeLists.txt` - Enable FetchContent build + install + CPack DEB generation
- `.github/workflows/protobuf-build.yml` - Build and publish workflow

### Crankshaft.core
- `docker/Dockerfile.build` - Require aap-protobuf packages when BUILD_AASDK=false

## Future Improvements

1. **Automated Publishing**: Extend protobuf-build.yml to automatically push to APT repo
2. **Version Matrix**: Build multiple protobuf versions for different compatibility needs
3. **Cross-compilation**: Add build targets for ARM64, armhf (Raspberry Pi)
4. **Security Scanning**: Add security checks to protobuf builds before publishing
5. **Performance Metrics**: Track build times and package sizes over releases
