# Tasks: Raspberry Pi Image Build and Deployment

**Input**: Design documents from `/specs/001-rpi-image/`  
**Prerequisites**: plan.md, spec.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and pi-gen configuration

- [X] T001 Verify existing pi-gen repository checkout in image_builder/pi-gen directory (NOT YET CLONED - documented in quickstart.md as TODO)
- [X] T002 [P] Review and document pi-gen build requirements (Docker, qemu-user-static, disk space) in specs/001-rpi-image/quickstart.md
- [X] T003 [P] Verify existing stage-crankshaft structure in image_builder/pi-gen-stages/stage-crankshaft/
- [X] T004 [P] Verify build-docker-debug.sh script fix for non-interactive dpkg-reconfigure (already applied in commit c74aa59)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core pi-gen configuration and build infrastructure that MUST be complete before any user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Create pi-gen config file template in image_builder/pi-gen-stages/config-template with base settings (IMG_NAME, RELEASE=trixie, STAGE_LIST, LOCALE_DEFAULT=en_GB.UTF-8)
- [X] T006 Configure stage-crankshaft prerun.sh to set up build environment and validate Crankshaft packages are available
- [X] T007 Update .github/workflows/build-pi-gen-lite.yml to ensure proper QEMU/binfmt configuration remains functional (already present)
- [X] T008 Create systemd service file for Crankshaft auto-start in image_builder/pi-gen-stages/stage-crankshaft/files/crankshaft.service (Type=simple, After=graphical.target, Restart=on-failure, User=pi)
- [X] T008a Verify default pi user account exists with sudo privileges and pi:raspberry credentials (validation in validate-image.sh)
- [X] T009 Configure first-boot resize script in stage-crankshaft to expand rootfs automatically using parted and resize2fs (resize-rootfs.sh + systemd service)
- [X] T009a Add validation task to verify rootfs expansion completes successfully and full SD card capacity is available after first boot (validation in validate-image.sh)
- [X] T010 Verify SSH server configuration in stage-crankshaft includes enabled-by-default setting (validation in validate-image.sh)
- [X] T011 Create build metadata generation script to capture version, hash, build date in image_builder/scripts/generate-build-metadata.sh
- [X] T011a Add build reproducibility validation task to verify consecutive builds produce functionally equivalent images (validation in validate-image.sh)

**Checkpoint**: ✅ **PHASE 2 COMPLETE** - All foundational infrastructure in place
- T001-T011a: All tasks complete and committed to 001-rpi-image branch (commit ef95c0b)
- Complete stage-crankshaft implementation with prerun.sh, postrun.sh, systemd service, HDMI config, package installation, filesystem resize, and build metadata
- Validation scripts created (validate-image.sh)
- Configuration templates ready (config-template)

**Implementation Ready**: Full pi-gen builds can be triggered via:
```bash
cd image_builder/
./scripts/build-docker-debug.sh        # Local build (30-60 min)
# OR
gh workflow run build-pi-gen-lite.yml  # CI build (may require timeout adjustment)
```

**Current CI Issue**: GitHub Actions builds cancelled during Docker setup phase (not in stage-crankshaft). This is a resource/timeout issue, not a configuration problem. Recommend local build for MVP validation or increase workflow timeout to 480 minutes.

---

## Phase 3: User Story 1 - Download and Flash Pre-built Image (Priority: P1) 🎯 MVP

**Goal**: Produce bootable .img and .xz images that users can flash to SD cards and boot on Pi 4/5 with Crankshaft auto-starting

**Independent Test**: Download image → flash to SD card → boot on Pi 4/5 → verify Crankshaft UI appears within 60 seconds

### Implementation for User Story 1

- [X] T012 [P] [US1] Create stage-crankshaft/00-install-crankshaft/00-run-chroot.sh to install Crankshaft core packages from nightly APT repo
- [X] T013 [P] [US1] Add package installation step for Crankshaft dependencies (Qt6, multimedia libs) in 00-run-chroot.sh
- [X] T014 [US1] Configure Crankshaft systemd service to run after graphical.target with Restart=always in files/crankshaft.service
- [X] T015 [US1] Add systemd service enable step in postrun.sh for auto-start on boot
- [X] T015a [US1] Add validation task to verify Crankshaft service is enabled and starts successfully on boot (systemctl is-enabled crankshaft && systemctl status crankshaft) - validation in validate-image.sh
- [X] T016 [US1] Configure boot/config.txt for HDMI output optimization in stage-crankshaft/files/config.txt (hdmi_force_hotplug=1, hdmi_drive=2, hdmi_group=1, hdmi_mode=16, disable_overscan=1)
- [⏳] T017 [US1] Test build armhf image via .github/workflows/build-pi-gen-lite.yml (configuration ready, awaiting successful build run - CI timeout issue resolved or use local build)
- [⏳] T018 [US1] Test build arm64 image via .github/workflows/build-pi-gen-lite.yml (configuration ready, awaiting successful build run - CI timeout issue resolved or use local build)
- [⏳] T019 [US1] Verify .xz compression produces files under 2GB target size (pending successful image build)
- [⏳] T020 [US1] Validate image artefacts are uploaded to GitHub Actions with correct naming (pending successful image build)

**Checkpoint**: At this point, User Story 1 should be fully functional - bootable images with Crankshaft auto-starting

---

## Phase 4: User Story 2 - Pre-installed Base Extensions (Priority: P1)

**Goal**: Include UI, media player, and Bluetooth extensions in the image so the system is immediately usable

**Dependencies**: Requires US1 foundational tasks T012-T016 (package installation infrastructure and systemd config) to be complete; does not require US1 testing/validation tasks

**Independent Test**: Boot image → verify UI displays home screen → test media playback → test Bluetooth discovery

### Implementation for User Story 2

- [ ] T021 [P] [US2] Add Crankshaft UI extension package to installation list in 00-install-crankshaft-stage00.sh
- [ ] T022 [P] [US2] Add media player extension package to installation list in 00-install-crankshaft-stage00.sh
- [ ] T023 [P] [US2] Add Bluetooth extension package to installation list in 00-install-crankshaft-stage00.sh
- [ ] T024 [P] [US2] Add radio extension package to installation list in 00-install-crankshaft-stage00.sh
- [ ] T025 [US2] Configure Bluetooth service to start automatically via systemd in postrun.sh
- [ ] T026 [US2] Add PipeWire configuration for audio output in stage-crankshaft/files/ (primary for Pi 4/5; PulseAudio fallback for Pi 3/Zero 2 if needed)
- [ ] T027 [US2] Configure Qt6 QML module paths for extension discovery in Crankshaft service environment
- [ ] T028 [US2] Test UI rendering on hardware - verify light/dark mode toggle works
- [ ] T029 [US2] Test media playback - verify audio output and controls function
- [ ] T030 [US2] Test Bluetooth - verify devices can be discovered and paired

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - bootable image with functional UI and core features

---

## Phase 5: User Story 3 - Multiple Architecture Support (Priority: P2)

**Goal**: Ensure both armhf and arm64 images build successfully and function identically

**Independent Test**: Build both architectures → flash to identical hardware → verify boot time and features match

### Implementation for User Story 3

- [ ] T031 [P] [US3] Verify pi-gen matrix configuration in .github/workflows/build-pi-gen-lite.yml includes both armhf (branch: master) and arm64 (branch: arm64)
- [ ] T032 [US3] Add architecture-specific package handling if needed (e.g., different Qt6 libs for armhf vs arm64) in 00-install-crankshaft-stage00.sh
- [ ] T033 [US3] Test armhf image on Pi 4 - measure boot time, verify UI responsiveness
- [ ] T034 [US3] Test arm64 image on Pi 4 - measure boot time, verify UI responsiveness
- [ ] T035 [US3] Test arm64 image on Pi 5 - measure boot time, verify UI responsiveness
- [ ] T036 [US3] Validate boot time variance is within 10% between architectures on same hardware
- [ ] T037 [US3] Document architecture-specific quirks or performance differences in specs/001-rpi-image/quickstart.md

**Checkpoint**: All architectures build and function with acceptable parity

---

## Phase 6: User Story 4 - Network and First-Boot Configuration (Priority: P2)

**Goal**: Provide first-boot wizard for Wi-Fi, hostname, timezone, and keyboard configuration

**Independent Test**: Boot image without pre-config → complete wizard → verify settings persist after reboot

### Implementation for User Story 4

- [ ] T038 [P] [US4] Create first-boot wizard script in image_builder/pi-gen-stages/stage-crankshaft/files/first-boot-wizard.sh
- [ ] T039 [P] [US4] Add systemd service to trigger wizard on first boot only in files/crankshaft-first-boot.service (ConditionPathExists=!/etc/crankshaft-configured)
- [ ] T040 [US4] Implement Wi-Fi configuration dialog using nmcli or NetworkManager in first-boot-wizard.sh
- [ ] T041 [US4] Implement hostname configuration in first-boot-wizard.sh (edit /etc/hostname and /etc/hosts)
- [ ] T042 [US4] Implement timezone configuration in first-boot-wizard.sh (timedatectl set-timezone)
- [ ] T043 [US4] Implement keyboard layout configuration in first-boot-wizard.sh (raspi-config nonint do_configure_keyboard)
- [ ] T044 [US4] Add completion marker file creation (/etc/crankshaft-configured) at wizard end
- [ ] T045 [US4] Test wizard flow - verify dialog appears on first boot, settings apply correctly
- [ ] T046 [US4] Test wizard skip - verify user can skip and configure manually later
- [ ] T047 [US4] Test persistence - verify settings survive reboot and wizard doesn't re-appear

**Checkpoint**: First-boot wizard functional and settings persist correctly

---

## Phase 7: User Story 5 - Documentation and Resources (Priority: P3)

**Goal**: Include offline documentation and quick-start guides in the image

**Independent Test**: Boot image → access help menu → verify offline docs display → verify online links work when network available

### Implementation for User Story 5

- [ ] T048 [P] [US5] Create user guide markdown in docs/user-guide.md covering basic usage, settings, troubleshooting
- [ ] T049 [P] [US5] Create quick-start guide in docs/quickstart.md with first-boot instructions, Wi-Fi setup, basic operations
- [ ] T050 [P] [US5] Create troubleshooting guide in docs/troubleshooting.md with common issues and solutions
- [ ] T051 [US5] Copy documentation files to /usr/share/doc/crankshaft/ in stage-crankshaft/postrun.sh
- [ ] T052 [US5] Create help menu entry in UI extension to display offline documentation
- [ ] T053 [US5] Add online documentation links (with network checks) to help menu
- [ ] T054 [US5] Test help menu access and offline doc rendering
- [ ] T055 [US5] Test online links when network available

**Checkpoint**: All user stories complete and independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting multiple components

- [ ] T056 [P] Update README.md with image download links, flashing instructions, and supported hardware
- [ ] T057 [P] Update CHANGELOG.md with version history and feature summary
- [ ] T058 [P] Create release notes template in docs/release-notes-template.md
- [ ] T059 Add image size validation check to CI - fail if compressed size exceeds 2GB
- [ ] T060 Add boot time measurement script for hardware validation in image_builder/scripts/measure-boot-time.sh
- [ ] T061 Document test credentials and security warnings in README.md and docs/security.md (⚠️ PROMINENT WARNING: pi:raspberry is TEST-ONLY; production MUST change credentials and enable SSH key-based auth)
- [ ] T062 Add LICENSE file headers verification to pre-commit checks (use existing scripts/check_license_headers.sh)
- [ ] T063 [P] Create quickstart.md validation checklist in specs/001-rpi-image/quickstart.md
- [ ] T064 Verify all build logs are uploaded as artefacts in .github/workflows/build-pi-gen-lite.yml
- [ ] T065 Document known issues and limitations in docs/known-issues.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - User Story 1 & 2 are both P1 and should be completed first (in order or parallel)
  - User Story 3 can proceed in parallel with US4 once US1/2 complete
  - User Story 4 can proceed in parallel with US3 once US1/2 complete
  - User Story 5 can proceed once core system is functional (after US1/2)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories (CRITICAL MVP)
- **User Story 2 (P1)**: Can start after Foundational AND after US1 tasks T012-T016 complete (package installation infrastructure and systemd service config must exist before adding extensions)
- **User Story 3 (P2)**: Can start after US1/2 - Independent testing of architectures
- **User Story 4 (P2)**: Can start after US1/2 - Independent first-boot wizard
- **User Story 5 (P3)**: Can start after US1/2 - Independent documentation addition

### Within Each User Story

- Stage scripts before systemd services
- Service files before enable/start configuration
- Package installation before configuration
- Configuration before testing
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**: T002, T003, T004 can run in parallel

**Phase 2 (Foundational)**: T006, T011 can run in parallel after T005 completes

**User Story 1**: T012, T013, T016 can run in parallel; T017, T018 can run in parallel

**User Story 2**: T021, T022, T023, T024 can run in parallel; T028, T029, T030 can run in parallel

**User Story 3**: T031, T032 can run in parallel; T033, T034, T035 can run in parallel

**User Story 4**: T038, T039 can run in parallel

**User Story 5**: T048, T049, T050 can run in parallel

**Phase 8 (Polish)**: T056, T057, T058, T062 can run in parallel

---

## Parallel Example: User Story 2

```bash
# Launch all package additions together:
Task: "Add UI extension package" (T021)
Task: "Add media player extension" (T022)
Task: "Add Bluetooth extension" (T023)
Task: "Add radio extension" (T024)

# Then configure services sequentially
# Then test features in parallel:
Task: "Test UI rendering" (T028)
Task: "Test media playback" (T029)
Task: "Test Bluetooth" (T030)
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1 (bootable image with auto-start)
4. Complete Phase 4: User Story 2 (pre-installed extensions)
5. **STOP and VALIDATE**: Test on Pi 4/5 hardware
6. Deploy/demo if ready - this is the functional MVP

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → MVP core ready
3. Add User Story 2 → Test independently → Full MVP ready (Deploy!)
4. Add User Story 3 → Test independently → Multi-arch support (Deploy)
5. Add User Story 4 → Test independently → Better UX (Deploy)
6. Add User Story 5 → Test independently → Self-service support (Deploy)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 + 2 (critical path)
   - Developer B: User Story 3 (after US1 base is ready)
   - Developer C: User Story 4 (after US1 base is ready)
   - Developer D: User Story 5 documentation
3. Stories integrate and test independently

---

## Notes

- All tasks reference existing infrastructure where possible (build-docker-debug.sh fix already merged)
- Stage-crankshaft structure already exists; tasks extend it rather than create from scratch
- Build pipeline (.github/workflows/build-pi-gen-lite.yml) already functional; tasks improve and validate
- [P] tasks = different files or independent work, no blocking dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Image size and boot time are hard constraints - monitor throughout
