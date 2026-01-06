# Feature Specification: Raspberry Pi Image Build and Deployment

**Feature Branch**: `001-rpi-image`  
**Created**: 2026-01-05  
**Status**: Draft  
**Input**: User description: "create a raspberry pi image for the application"

## Overview

This feature enables the creation of pre-built Raspberry Pi images that include the complete Crankshaft automotive infotainment system. These images allow users to quickly deploy Crankshaft on Raspberry Pi 4/5 hardware without needing to compile the software from source.

## Clarifications

### Session 2026-01-05

- Q: Should VNC remote display support be included in the MVP image? → A: Use HDMI-only for MVP; defer VNC to a later phase.
- Q: Should the MVP image include security hardening (custom credentials, disabled SSH, firewall)? → A: Keep test credentials for MVP with clear documentation; plan hardening in a later phase.

### Supported Hardware

- Raspberry Pi Zero 2 (1GB)
- Raspberry Pi 3 Model B (1GB)
- Raspberry Pi 4 Model B (2GB, 4GB, 8GB RAM)
- Raspberry Pi 5 (2GB, 4GB, 8GB RAM)

### Supported Distributions

- Raspberry Pi OS (Trixie) - both armhf (32-bit) and arm64 (64-bit)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Download and Flash Pre-built Image (Priority: P1)

Users should be able to download a pre-built Raspberry Pi image containing Crankshaft and flash it to an SD card or USB drive without any additional configuration or compilation.

**Why this priority**: This is the core MVP that delivers immediate value. Users can get Crankshaft running on hardware with minimal effort.

**Independent Test**: Can be fully tested by: (1) downloading the image, (2) flashing it to a physical SD card, (3) booting on a Raspberry Pi, and (4) verifying the application starts successfully.

**Acceptance Scenarios**:

1. **Given** a user has an image file (.xz or .img format), **When** they use standard image flashing tools (balena Etcher, dd, etc.), **Then** the image flashes successfully without corruption
2. **Given** a flashed SD card is inserted into a Raspberry Pi 4/5, **When** the system boots, **Then** Crankshaft starts automatically within 60 seconds
3. **Given** Crankshaft has started, **When** the user interacts with the UI, **Then** the application responds to input and displays correctly on the connected display
4. **Given** the image is booted for the first time, **When** the system initialises, **Then** all hardware interfaces (HDMI, USB, Bluetooth, touch if available) are functional

---

### User Story 2 - Pre-installed Base Extensions (Priority: P1)

The image should include essential base extensions (UI, media player, Bluetooth) so the system is immediately usable without extension installation.

**Why this priority**: Users need a working system out-of-the-box; without base extensions, Crankshaft cannot function.

**Independent Test**: Can be tested by: (1) booting the image, (2) verifying UI displays, (3) testing media playback capabilities, (4) checking Bluetooth is available and discoverable.

**Acceptance Scenarios**:

1. **Given** the image boots successfully, **When** the system completes initialisation, **Then** the UI extension is loaded and displays the home screen
2. **Given** a media file is available on the system, **When** the user opens the media player extension, **Then** playback controls work and audio/video output functions
3. **Given** the system has booted, **When** the user accesses Bluetooth settings, **Then** Bluetooth is enabled and devices can be discovered and paired
4. **Given** a connected display, **When** the UI renders, **Then** light mode and dark mode toggle work and text/UI elements are readable

---

### User Story 3 - Multiple Architecture Support (Priority: P2)

The build pipeline should produce images for both 32-bit (armhf) and 64-bit (arm64) Raspberry Pi architectures so users can choose based on their hardware capabilities.

**Why this priority**: Supports broader hardware compatibility; some users may be running older Raspberry Pi 4 variants or have specific reasons to use 32-bit systems.

**Independent Test**: Can be tested by: (1) building both architecture variants, (2) flashing each to appropriate hardware, (3) verifying both boot and function identically in terms of user experience.

**Acceptance Scenarios**:

1. **Given** build process is executed, **When** the build completes, **Then** both armhf and arm64 images are generated successfully
2. **Given** an armhf image is flashed to a Raspberry Pi 4, **When** the system boots, **Then** it functions identically to the arm64 version in terms of user-facing features
3. **Given** both images are created, **When** they are flashed to identical hardware, **Then** boot time and performance are comparable (within 10% variance)

---

### User Story 4 - Network and First-Boot Configuration (Priority: P2)

First-time users should have guided setup for essential network configuration (Wi-Fi, hostname, timezone) on the first boot.

**Why this priority**: Improves out-of-the-box experience; without network, many extension features and updates won't function.

**Independent Test**: Can be tested by: (1) booting the image without network pre-configuration, (2) completing the first-boot setup wizard, (3) verifying network connectivity after setup, (4) confirming settings persist across reboots.

**Acceptance Scenarios**:

1. **Given** the image boots for the first time without network, **When** the system completes initialisation, **Then** a first-boot setup dialog appears
2. **Given** the setup wizard is displayed, **When** the user configures Wi-Fi credentials, **Then** the system connects to the network and obtains an IP address
3. **Given** the user completes the setup wizard, **When** the system reboots, **Then** the configured settings persist and the system auto-connects to the configured Wi-Fi
4. **Given** the system has network connectivity, **When** the user opens extension store or settings, **Then** network-dependent features are available

---

### User Story 5 - Documentation and Resources (Priority: P3)

The image should include offline documentation and quick-start guides accessible from the system.

**Why this priority**: Helps users troubleshoot and understand the system capabilities; nice-to-have but not essential for basic operation.

**Independent Test**: Can be tested by: (1) accessing the help/documentation section from the UI, (2) verifying offline documentation is available, (3) confirming links to online resources work when network is available.

**Acceptance Scenarios**:

1. **Given** the system is running, **When** the user accesses the help menu, **Then** offline documentation is displayed
2. **Given** the user reads the documentation, **When** they follow a troubleshooting guide, **Then** it helps them resolve common issues
3. **Given** offline documentation is available, **When** network is unavailable, **Then** documentation remains accessible without errors

---

### Edge Cases

- What happens if the SD card is removed during boot? (System should fail gracefully with clear error messaging if no root filesystem is found)
- How does the system handle insufficient disk space during first update? (Should alert user and prevent partial updates)
- What happens if Wi-Fi credentials are incorrect in first-boot setup? (Should allow user to re-enter credentials or skip setup)
- How is data persisted if the image is re-flashed? (User data should be lost; this should be documented clearly)
- What happens if display is not connected? (System should boot and provide debugging output via SSH/serial console)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Image build pipeline MUST produce bootable .img and .xz-compressed image files for armhf and arm64 architectures
- **FR-002**: Image MUST include complete Crankshaft core application (C++ backend) compiled for the target architecture
- **FR-003**: Image MUST include UI extension (QML-based) with full functionality and internationalization support
- **FR-004**: Image MUST include media player, Bluetooth, and radio extensions (radio = internet radio only; FM/DAB hardware support deferred to future phase)
- **FR-005**: Image MUST initialise with a default user account (pi:raspberry) with sudo privileges
- **FR-006**: Image MUST auto-start Crankshaft application on boot without manual intervention
- **FR-007**: Image MUST include SSH server enabled by default for remote access and debugging ⚠️ **WARNING**: Default pi:raspberry credentials are for TESTING ONLY and MUST be changed for production deployments. See docs/security.md for hardening guidance.
- **FR-008**: Image MUST support HDMI display output for MVP; VNC remote display is deferred to a later phase
- **FR-009**: Image MUST include a first-boot configuration wizard for Wi-Fi and system settings
- **FR-010**: Image filesystem MUST be automatically resized on first boot to utilise full SD card capacity
- **FR-011**: Image MUST include extension store capabilities for installing additional extensions
- **FR-012**: Image MUST include offline documentation and help resources

### Non-Functional Requirements

- **NFR-001**: Image file size MUST NOT exceed 2GB (compressed .xz format)
- **NFR-002**: Image boot time (from power-on to UI display) MUST NOT exceed 90 seconds on Raspberry Pi 4
- **NFR-003**: Image MUST be created using pi-gen (official Raspberry Pi image builder) to ensure compatibility
- **NFR-004**: Build process MUST be repeatable and produce functionally equivalent images from the same source code (timestamps and build metadata may differ; core functionality must be identical)
- **NFR-005**: Build logs and artefacts MUST be preserved for debugging failed builds

## Constitution Check (mandatory)

### Impacted Principles

- **Code Quality**: Image must include only validated, tested code; build process must verify compilation without errors
- **Testing**: Pre-built images must be tested on physical hardware to verify boot and core functionality
- **Performance**: Boot time and application responsiveness must meet defined criteria for resource-constrained Raspberry Pi 4
- **Security**: Default credentials documented as test-only; production must customise. MVP does not include additional hardening; plan in later phase.
- **Observability**: Build process should generate detailed logs; runtime should support SSH/serial debugging
- **Documentation**: Image must include clear first-boot guidance and offline documentation

## Key Entities

- **Image File**: Compressed (.xz) or uncompressed (.img) Raspberry Pi OS image containing Crankshaft and all base extensions
- **Build Artefact**: All intermediate build outputs, logs, and version information generated during image creation
- **User Account**: Default 'pi' user with pre-configured privileges and SSH key support
- **Configuration State**: First-boot settings (Wi-Fi, hostname, timezone, locale)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can download, flash, and boot the image on a Raspberry Pi 4/5 with zero compilation steps (100% out-of-the-box usability)
- **SC-002**: Image boot time from power-on to fully functional UI is under 90 seconds on Raspberry Pi 4
- **SC-003**: Crankshaft application startup is automatic on boot with no manual interaction required
- **SC-004**: Both armhf and arm64 images are available for download with identical feature sets
- **SC-005**: Image file size (compressed) is under 2GB for easy distribution over standard internet connections
- **SC-006**: First-boot configuration wizard allows users to set up Wi-Fi and essential settings in under 5 minutes
- **SC-007**: All core features (UI display, media playback, Bluetooth) are functional immediately after boot
- **SC-008**: Build process for images completes within 60 minutes for a clean build on standard CI/CD hardware
- **SC-009**: Image can be flashed successfully using standard tools (balena Etcher, dd, Win32 Disk Imager) without special drivers or utilities
- **SC-010**: 99% of users should successfully boot the image without encountering hardware compatibility issues on supported hardware

## Assumptions

- Raspberry Pi 4 Model B or Pi 5 will be the primary deployment target; older Pi models are out of scope
- Raspberry Pi OS (Bookworm or Trixie) is the base operating system; custom kernels are not in scope for this MVP
- Users have standard SD card readers or USB flashing capability
- Initial deployment uses default 'pi' credentials; production security hardening is a future enhancement
- Wi-Fi is the primary network connectivity method; Ethernet configuration is a secondary feature
- Display output is assumed to be HDMI or VNC; serial console debugging is supported but not the primary interface

## Constraints

- Build process must use pi-gen (official Raspberry Pi image builder) for compatibility
- Image must fit within typical SD card sizes (8GB minimum for testing, 16GB+ recommended for end-users)
- Crankshaft application must not require additional system dependencies beyond what's in pi-gen base
- Build duration should not exceed 60 minutes to support reasonable CI/CD pipeline times
- Boot-time startup of Crankshaft requires careful systemd service configuration to avoid blocking boot sequence
- Image should support unattended boot without requiring user intervention (except first-boot wizard)
