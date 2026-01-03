# Build.sh Flag Compatibility Verification

**Purpose**: Document existing build.sh flags and verify compatibility with Phase 4 enhancements.

**Date**: 2025-01-03  
**Feature**: 003-github-actions-cicd / Task T003b

---

## Existing build.sh Flags

### Current Flags (from scripts/build.sh)

Run the following to verify current implementation:

```bash
./scripts/build.sh --help
```

**Known Existing Flags**:
- `--build-type` or `-b`: Build type (Debug/Release)
- `--component`: Specific component to build (core/ui/all)
- `--clean`: Clean build artifacts before building
- `--package`: Create DEB packages after build

**Example Usage**:
```bash
./scripts/build.sh --build-type Debug
./scripts/build.sh --component core --build-type Release
./scripts/build.sh --build-type Release --package
```

---

## Proposed New Flags (Phase 4, Task T025)

**For Integration**:

### `--architecture` or `-a`

**Purpose**: Explicitly select target architecture(s)  
**Values**: `amd64` | `arm64` | `armhf` | `all`  
**Default**: `all` (build all three)  
**Compatibility**: Can coexist with existing flags

```bash
./scripts/build.sh --architecture amd64 --build-type Debug
./scripts/build.sh --architecture arm64 --build-type Release
./scripts/build.sh --architecture all --package  # Default behavior
```

**Implementation Note**: May require updating CMakeLists.txt to support conditional compilation/cross-compilation logic.

### `--skip-tests` 

**Purpose**: Skip running unit tests after build  
**Values**: `true` | `false`  
**Default**: `false` (run tests)  
**Compatibility**: Can coexist with existing flags

```bash
./scripts/build.sh --architecture amd64 --skip-tests
./scripts/build.sh --build-type Debug --skip-tests
```

**Implementation Note**: Tests are run via `ctest` after build. Flag should suppress this step.

---

## Flag Compatibility Matrix

| Flag | Current Status | Proposed | Conflict? | Notes |
|------|---|---|---|---|
| `--build-type` | ✅ Exists | Keep | No | Core flag, no change needed |
| `--component` | ✅ Exists | Keep | No | Orthogonal to new flags |
| `--clean` | ✅ Exists | Keep | No | Pre-build cleanup, independent |
| `--package` | ✅ Exists | Keep | No | Post-build packaging, independent |
| `--architecture` | ❌ Missing | Add | No | New feature, doesn't conflict |
| `--skip-tests` | ❌ Missing | Add | No | New feature, doesn't conflict |

**Conclusion**: ✅ **NO CONFLICTS** - Both new flags can be safely added without modifying existing flags.

---

## Implementation Checklist

- [ ] Read current `scripts/build.sh` to understand structure
- [ ] Add `--architecture` flag parsing
  - [ ] Accept `amd64`, `arm64`, `armhf`, `all`
  - [ ] Set `CMAKE_BUILD_ARCHITECTURE` or equivalent
  - [ ] Pass to CMake via `-DTARGET_ARCHITECTURE=...`
- [ ] Add `--skip-tests` flag parsing
  - [ ] Parse flag value (`true`/`false`)
  - [ ] Conditionally invoke `ctest` in post-build phase
- [ ] Test new flags:
  - [ ] `./scripts/build.sh --architecture amd64 --build-type Debug`
  - [ ] `./scripts/build.sh --skip-tests`
  - [ ] `./scripts/build.sh --architecture arm64 --build-type Release --skip-tests`
  - [ ] Verify old flags still work: `./scripts/build.sh --build-type Debug --package`
- [ ] Update `--help` output to document new flags
- [ ] Update build.sh header comments with new options

---

## Related Tasks

- **T025** (Phase 4): Update scripts/build.sh with new flags
- **T018** (Phase 4): Update ci.yml to use `--architecture` flag based on branch
- **T020** (Phase 4): Update ci.yml to use `--skip-tests` for fastpath builds

---

## Future Considerations

- Add `--cross-compile` flag to explicitly enable QEMU cross-compilation for arm* architectures
- Add `--jobs N` flag to control parallel build parallelism (currently uses system cores)
- Add `--cache-dir` flag to specify custom CMake cache directory for faster rebuilds
- Add `--enable-coverage` flag for code coverage reporting

---

**Verification Status**: 🔄 PENDING  
**Target Completion**: Phase 4, Task T025  
**Assigned To**: Implementation team

