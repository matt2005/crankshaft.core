# Feature Specification: Buildroot Image Build for Crankshaft

**Feature Branch**: `004-buildroot-image`  
**Created**: 2026-01-05  
**Status**: Draft  
**Input**: User description: "continue with pi-gen but create a new spec for a buildroot build"

## Overview

Introduce a Buildroot-based image build path for Crankshaft as an alternative to pi-gen. The goal is to produce a minimal, fast-booting image for Raspberry Pi 4/5 that packages Crankshaft core, UI, and base extensions, while keeping pi-gen builds in place for compatibility. The Buildroot path should be reproducible, automated in CI, and deliver a pared-back root filesystem with only required components.

### Supported Hardware

- Raspberry Pi 4 Model B (2GB, 4GB, 8GB)
- Raspberry Pi 5 (2GB, 4GB, 8GB)

### Supported Outputs

- Buildroot-generated SD card image (.img) for arm64 (primary) and armhf (secondary, if feasible)
- Compressed artefacts (.xz) for distribution

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Minimal Fast-Boot Image (Priority: P1)
Users can obtain a Buildroot image that boots Crankshaft to UI in under the defined target time, with only required services enabled.

**Why this priority**: Delivers the core value of Buildroot—speed and minimal footprint.

**Independent Test**: Flash image, boot on Pi 4/5, measure boot-to-UI time and verify only required services run.

**Acceptance Scenarios**:
1. **Given** the Buildroot image is flashed, **When** the Pi powers on, **Then** the UI appears within the target boot time.
2. **Given** the system is running, **When** services are listed, **Then** only Crankshaft-critical services are active.

---

### User Story 2 - Core Feature Parity (Priority: P1)
Users should have the same core Crankshaft functionality (UI, media, Bluetooth) on Buildroot as on pi-gen images.

**Why this priority**: Ensures Buildroot is a viable alternative, not a reduced demo.

**Independent Test**: Run sanity tests for UI render, media playback, and Bluetooth discovery on Buildroot image.

**Acceptance Scenarios**:
1. **Given** the UI loads, **When** navigation across screens occurs, **Then** rendering and input are responsive.
2. **Given** a media file is available, **When** playback starts, **Then** audio output is produced without glitches.
3. **Given** Bluetooth is enabled, **When** scanning for devices, **Then** nearby devices are discoverable.

---

### User Story 3 - CI Reproducible Build (Priority: P2)
The Buildroot image can be produced in CI with pinned configs and artefacts published alongside pi-gen outputs.

**Why this priority**: Ensures maintainability and distribution at scale.

**Independent Test**: Run CI job from clean workspace; verify artefact hashes remain stable for the same inputs.

**Acceptance Scenarios**:
1. **Given** CI runs the Buildroot pipeline, **When** build completes, **Then** an .img and .xz artefact are published.
2. **Given** two builds use the same Buildroot defconfig and source pins, **When** outputs are hashed, **Then** hashes match (allowing timestamp normalisation if required).

---

### User Story 4 - Configuration Extensibility (Priority: P3)
Developers can enable/disable optional packages (e.g., VNC, extra codecs) via Buildroot configs without invasive changes.

**Why this priority**: Keeps Buildroot path adaptable while remaining minimal by default.

**Independent Test**: Toggle a feature flag in defconfig, rebuild, and verify the resulting image includes/excludes the package.

**Acceptance Scenarios**:
1. **Given** a defconfig toggle is set for an optional feature, **When** the build runs, **Then** the feature is present in the image.
2. **Given** the toggle is unset, **When** the build runs, **Then** the feature is absent and image size reflects the reduction.

### Edge Cases

- Buildroot package failures (e.g., missing Qt6 dependency) should fail the build with clear logs.
- Kernel/firmware mismatch for Pi 5 vs Pi 4 should be detectable and surfaced in CI.
- Insufficient SD card space should be detected before flashing (image size check).
- Absent GPU acceleration libraries should trigger a clear warning and skip build.
- Network-less boot should still reach UI; if networking is required for a feature, it should degrade gracefully.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Provide a Buildroot defconfig for Raspberry Pi 4/5 with Crankshaft core, UI, media, and Bluetooth enabled.
- **FR-002**: Buildroot pipeline MUST produce bootable .img and .xz artefacts.
- **FR-003**: Crankshaft MUST auto-start on boot via Buildroot init/systemd-equivalent service.
- **FR-004**: Include audio, Bluetooth, and video pipeline dependencies required by Crankshaft in Buildroot packages.
- **FR-005**: Include a minimal first-boot configuration step for locale/timezone/keyboard; Wi-Fi may be CLI or simple dialog.
- **FR-006**: Generate artefact metadata (build hash, build date, defconfig revision) alongside outputs.
- **FR-007**: Preserve existing pi-gen pipeline; Buildroot is additive and selectable in CI matrix.
- **FR-008**: Provide toggles in defconfig for optional features (e.g., VNC, extra codecs) defaulting to off.
- **FR-009**: Publish build logs for troubleshooting failures.

### Non-Functional Requirements

- **NFR-001**: Target compressed image size ≤ 1.5GB for Buildroot output.
- **NFR-002**: Boot-to-UI time target: ≤ 70s on Pi 4, ≤ 50s on Pi 5 (cold boot).
- **NFR-003**: Build time target: ≤ 60 minutes in CI for a clean build with caching disabled; ≤ 30 minutes with caching.
- **NFR-004**: Reproducibility: identical inputs (defconfig, sources, hashes) produce identical artefacts (allowing timestamp normalisation).
- **NFR-005**: Security: ship with documented test credentials; allow easy override of default user/password at build time.

## Constitution Check (mandatory)

- **Code Quality**: Buildroot configs, package selections, and service definitions must be reviewed and linted where possible.
- **Testing**: Hardware smoke tests on Pi 4 and Pi 5 to validate boot, UI, media, Bluetooth.
- **Performance**: Must meet boot-time targets and remain responsive on constrained hardware.
- **Security**: Default creds documented as test-only; make credential override straightforward; no unnecessary network services enabled by default.
- **Observability**: Build logs published; runtime should expose serial/SSH for debugging.
- **Documentation**: Provide setup/usage notes and defconfig toggles documentation.

## Key Entities

- **Buildroot Defconfig**: Configuration file defining packages, kernel options, and Crankshaft integration.
- **Build Artefacts**: .img and .xz outputs plus metadata (hashes, build date, defconfig revision).
- **Runtime Services**: Crankshaft startup service and minimal supporting services (Bluetooth, audio, display).
- **Optional Feature Flags**: Defconfig toggles controlling optional packages/features.

## Success Criteria *(mandatory)*

- **SC-001**: Buildroot pipeline produces bootable .img and .xz artefacts for Pi 4/5.
- **SC-002**: Boot-to-UI within targets (≤70s Pi 4, ≤50s Pi 5).
- **SC-003**: Core features (UI, media, Bluetooth) validated on hardware with parity to pi-gen images.
- **SC-004**: Compressed image size ≤ 1.5GB.
- **SC-005**: CI build completes within 60 minutes clean; 30 minutes with cache.
- **SC-006**: Optional feature toggles verified to add/remove components without breaking core build.
- **SC-007**: Artefact metadata (hash, defconfig revision) published with downloads.
- **SC-008**: Reproducible builds yield identical hashes for identical inputs (with timestamp normalisation).

## Assumptions

- Buildroot supports necessary Raspberry Pi firmware, GPU, and drivers for Pi 4/5.
- Qt6 and multimedia stacks can be built in Buildroot without custom patches beyond upstream recipes.
- CI runners have enough resources (≥4 vCPU, ≥16GB RAM, ample disk) for Buildroot builds.
- Users flashing the image are comfortable with standard flashing tools; first-boot Wi-Fi may be basic (CLI/dialog).

## Constraints

- Buildroot path must not break or delay existing pi-gen pipeline; both may run in CI matrix.
- Keep default services minimal (no extra daemons) to preserve boot time targets.
- Avoid non-free components unless already used in pi-gen build; document any additions.
- Maintain British English documentation and i18n readiness in UI components.
