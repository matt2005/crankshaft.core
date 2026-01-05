# Implementation Plan: Raspberry Pi Image Build and Deployment

**Branch**: `001-rpi-image` | **Date**: 2026-01-05 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/001-rpi-image/spec.md`

## Summary
- Build and publish pi-gen-based Raspberry Pi images (armhf + arm64) for Pi Zero 2, Pi 3, Pi 4, and Pi 5 with Crankshaft pre-installed (core + UI + base extensions). Primary targets: Pi 4/5; Pi Zero 2/Pi 3 supported as best-effort (may exceed boot time targets).
- Provide first-boot setup (Wi-Fi/hostname/timezone/keyboard), auto-resize rootfs, and auto-start Crankshaft on boot.
- Meet size and performance targets: compressed image ≤2GB; boot-to-UI ≤60s on Pi 4; first-boot wizard completes in <5 minutes; core features usable immediately.
- Keep VNC out of MVP (HDMI-only); keep default test credentials with documentation; plan security hardening later.

## Technical Context
**Language/Version**: C++17/Qt 6 (core + UI); shell for pi-gen customisation; Docker for CI builds  
**Primary Dependencies**: pi-gen (Raspberry Pi OS Trixie), Docker Buildx, Crankshaft core/UI artifacts, Bluetooth/media deps, first-boot wizard scripts  
**Storage**: Local filesystem image (FAT32 / boot, ext4 / root)  
**Testing**: ctest/CTests in CI for code; hardware smoke tests for image boot/UI/media/Bluetooth; image validation scripts in pipeline  
**Target Platform**: Raspberry Pi OS Trixie armhf + arm64; hardware Pi Zero 2, Pi 3, Pi 4, Pi 5  
**Project Type**: Embedded system image (automotive infotainment)  
**Performance Goals**: Boot-to-UI ≤90s (Pi 4), ≤120s Pi 3/Zero 2 (best-effort); first-boot wizard <5m user input time (excludes network connection time); auto-start Crankshaft within 60s of boot completion; steady-state core+UI memory within constitution budget (≤1.5GB)  
**Constraints**: Image ≤2GB compressed; build ≤60m clean in CI; no VNC in MVP; default test creds only; avoid blocking boot (systemd ordering)  
**Scale/Scope**: Multi-arch images (armhf, arm64) for four Pi models; publish nightly artifacts and logs

## Constitution Check
- **Code Quality**: Use existing lint/format in CI; stage scripts reviewed; avoid duplication; document stage changes.
- **Test-First**: Add/keep smoke tests for image boot + services; ensure ctest runs in CI; any new scripts get shellcheck where applicable.
- **UX Consistency**: UI/light-dark toggle and en-GB localisation preserved; first-boot wizard is minimal and driver-safe.
- **Performance**: Enforce boot-time targets; avoid extra services; measure boot on Pi 4/5; document Pi 3/Zero 2 expectations.
- **Observability**: Keep build logs, publish artifacts, ensure runtime logs (journal/Crankshaft) are accessible via SSH/serial.
- **Security**: Default pi:raspberry credentials documented as TEST-ONLY with prominent warnings in README.md, docs/security.md, and first-boot wizard. SSH enabled by default for MVP debugging. Phase 2 hardening MUST implement SSH key-based authentication or disable SSH by default; consider fail2ban, UFW firewall, and credential rotation mechanisms.

## Project Structure

```text
specs/001-rpi-image/
├── spec.md
├── plan.md               # this plan
├── checklists/
│   └── requirements.md
├── research.md           # (to be created if/when deeper research is needed)
├── data-model.md         # (Phase 1 output, if applicable)
├── quickstart.md         # (Phase 1 output)
└── contracts/            # (Phase 1 output)

image_builder/
├── pi-gen-stages/stage-crankshaft/    # custom stage for Crankshaft
├── stages/stage60/                    # legacy compatibility
└── scripts/build-docker-debug.sh      # pi-gen build entry

.github/workflows/
├── build-pi-gen-lite.yml              # image build workflow
├── ci.yml                             # triggers build + publish nightly
└── trigger-apt-publish.yml            # publishing hook

scripts/
└── build.sh                           # project build helper (core/UI)

docs/
└── (usage/release notes as needed)
```

**Structure Decision**: Single-project repo with image build assets under `image_builder/` and CI workflows under `.github/workflows/`; documentation and specs under `specs/001-rpi-image/`.

## Technical Specifications

### Systemd Service Configuration (FR-006)
- **Unit Type**: Type=simple
- **Dependencies**: After=graphical.target, Wants=network-online.target
- **Restart Policy**: Restart=on-failure, RestartSec=5s
- **User**: User=pi, Group=pi
- **Environment**: QT_QPA_PLATFORM=eglfs (or vnc for remote), QML2_IMPORT_PATH=/usr/lib/crankshaft/extensions

### Filesystem Auto-Resize (FR-010)
- **Mechanism**: Use raspi-config init_resize.sh script triggered on first boot
- **Implementation**: Add init=/usr/lib/raspi-config/init_resize.sh to /boot/cmdline.txt on image creation; script removes itself after execution
- **Validation**: Check available disk space equals SD card capacity after first boot

### Audio System (FR-004)
- **Primary**: PipeWire (recommended for Pi 4/5 - lower latency, modern)
- **Fallback**: PulseAudio (for Pi 3/Zero 2 compatibility if needed)
- **Configuration**: Default audio sink to HDMI, Bluetooth A2DP profile enabled

### HDMI Configuration (FR-008)
- **config.txt Parameters**:
  - hdmi_force_hotplug=1 (detect display even if unplugged at boot)
  - hdmi_drive=2 (enable HDMI audio)
  - hdmi_group=1, hdmi_mode=16 (1080p 60Hz default; auto-detect preferred)
  - disable_overscan=1 (use full screen)

## Complexity Tracking
| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| None | N/A | N/A |
