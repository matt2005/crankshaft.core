# Dependency Version Management Strategy

**Purpose**: Define how build-time dependencies (AASDK, OpenAuto) and runtime packages are versioned and selected during CI/CD workflows.

**Date**: 2025-01-03  
**Feature**: 003-github-actions-cicd / Task T003a

---

## Overview

The Crankshaft CI/CD pipeline has multiple dependency sources:
1. **Build-time dependencies**: AASDK, OpenAuto (compile-time only)
2. **Runtime dependencies**: Qt6, system libraries (delivered in DEBs)
3. **Development dependencies**: CMake, compiler toolchain, linters

This document specifies how versions are selected for each category.

---

## Build-Time Dependencies (AASDK, OpenAuto)

### Strategy: Latest Compatible via Git Tags

**Default Behavior**:
- AASDK: Use latest stable release tag (`v*.*.*` matching semver)
- OpenAuto: Use latest stable release tag (`v*.*.*` matching semver)

**Implementation**:
```bash
# In scripts/build.sh or cmake configuration:
# - Clone AASDK from github.com/opencardev/aasdk
# - Checkout latest tag matching ^v[0-9]+\.[0-9]+\.[0-9]+$
# - Clone OpenAuto from github.com/opencardev/openauto
# - Checkout latest tag matching ^v[0-9]+\.[0-9]+\.[0-9]+$
```

### Pinning to Specific Versions

**Use Case**: Building release with known-good dependency versions

**Method**:
- Add `AASDK_VERSION` and `OPENAUTO_VERSION` environment variables to workflow
- If set, use exact version (e.g., `AASDK_VERSION=v1.2.3`)
- If unset, default to latest stable tag

**Workflow Example**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      AASDK_VERSION: ${{ github.event.inputs.aasdk_version || 'latest' }}
      OPENAUTO_VERSION: ${{ github.event.inputs.openauto_version || 'latest' }}
    steps:
      - run: ./scripts/build.sh --aasdk-version="$AASDK_VERSION" --openauto-version="$OPENAUTO_VERSION"
```

### Breaking Change Handling

**Policy**:
- If AASDK or OpenAuto releases breaking changes, they MUST increment MAJOR version
- Crankshaft CI/CD will detect incompatible versions and fail with clear error message
- Maintainer manually updates to compatible version and creates hotfix release

**Documentation**:
- Release notes MUST mention any AASDK/OpenAuto version upgrades
- Migration notes provided if breaking changes detected

---

## Runtime Dependencies (Qt6, System Libraries)

### Strategy: Debian Repository Pinning

**Default Behavior**:
- Build targets: Debian Trixie (testing) for current development
- Version selection: Latest available in repository at build time
- Debian packages use semantic versioning for main packages

**Implementation**:
```bash
# In CMakeLists.txt or package control files:
# Declare minimum versions (soft constraint)
# Qt6: >= 6.5.0
# SystemLibs: as available in Trixie repository
```

### Future: Version Pinning

**Not Yet Implemented** - Marked for future enhancement:
- Exact version pinning via Debian packages manifest
- Created during release process for reproducible builds
- Stored as `packages/DEBIAN_VERSIONS.txt`

---

## Development Dependencies (CMake, Toolchain)

### Strategy: Tool Version Pinning in Workflow

**Specification**:
- CMake >= 3.25 (enforced in workflow)
- clang/gcc: GCC 12+ or Clang 14+ (enforced in workflow runner selection)
- clang-format, clang-tidy, cppcheck: Latest available in Ubuntu runners

**Implementation**:
```yaml
# In ci.yml, build.yml:
- uses: actions/setup-cmake@v3
  with:
    cmake-version: 3.25.0  # Minimum version constraint
```

---

## Version Constraint Summary Table

| Dependency | Type | Selection | Pinning | Validation |
|-----------|------|-----------|---------|-----------|
| **AASDK** | Build-time | Latest tag | `AASDK_VERSION` env var | Tag format: `^v[0-9]+\.[0-9]+\.[0-9]+$` |
| **OpenAuto** | Build-time | Latest tag | `OPENAUTO_VERSION` env var | Tag format: `^v[0-9]+\.[0-9]+\.[0-9]+$` |
| **Qt6** | Runtime | Latest in Trixie | Future feature | Tested via DEB package install |
| **CMake** | Dev-time | >= 3.25 | Workflow constraint | Version check in workflow |
| **Toolchain** | Dev-time | Ubuntu runner default | Not pinned | GCC 12+ or Clang 14+ verified |

---

## Error Handling

### Incompatible Versions Detected

**Workflow Action**:
```bash
# During build, if dependency check fails:
if ! check_dependency_compatibility "$AASDK_VERSION" "$OPENAUTO_VERSION"; then
  echo "ERROR: Incompatible dependency versions"
  echo "AASDK: $AASDK_VERSION"
  echo "OpenAuto: $OPENAUTO_VERSION"
  echo "See .github/DEPENDENCY_COMPATIBILITY.md for matrix"
  exit 1
fi
```

**Resolution**:
1. Maintainer checks `.github/DEPENDENCY_COMPATIBILITY.md` for known-good combinations
2. Manually update versions in release workflow
3. Test locally before committing

### Repository Unavailable

**Fallback Strategy**:
- Retry with exponential backoff (3 attempts, 1s/2s/4s delays)
- If all retries fail, workflow fails with clear error message
- Include fallback mirror URLs in future (not yet implemented)

---

## Future Enhancements

- [ ] Create `.github/DEPENDENCY_COMPATIBILITY.md` matrix for known-good version combinations
- [ ] Implement `scripts/check-dependency-versions.sh` for early validation
- [ ] Add `DEBIAN_VERSIONS.txt` manifest for reproducible Trixie builds
- [ ] Support mirror fallbacks for repository unavailability
- [ ] Add vulnerability scanning for dependency versions (Dependabot integration)

---

## Questions & Decisions

**Q**: Should we pin Debian packages to exact versions for reproducibility?  
**A**: Not yet - Trixie is rolling release (testing). Pin versions for stable releases in future enhancement.

**Q**: How often should we update to latest AASDK/OpenAuto?  
**A**: On release (maintainer discretion) or when critical fixes are needed. Monthly update checks recommended.

**Q**: What if a dependency releases a critical security fix?  
**A**: Create emergency release with patched dependency version. Document in security advisory.

---

**Next Steps**:
1. Implement `scripts/build.sh --aasdk-version` and `--openauto-version` flags (Phase 4, Task T025)
2. Add version validation to quality-scan.yml (Phase 2, Task T008)
3. Document in ci.yml and release.yml workflow comments
4. Create DEPENDENCY_COMPATIBILITY.md in future enhancement phase
