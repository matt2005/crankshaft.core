# Tasks: Comprehensive GitHub Actions CI/CD Pipeline

**Input**: Design documents from `/specs/003-github-actions-cicd/`  
**Prerequisites**: plan.md ✅, spec.md ✅

**Tests**: Tests are OPTIONAL and NOT included per spec (validation via workflow execution, not unit tests)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1-US6)
- Include exact file paths in descriptions

## Phase 1: Setup

**Purpose**: Project initialization and documentation structure

- [ ] T001 Create workflow directory structure: `.github/workflows/` (already exists), `.github/scripts/{quality,package,release}/`
- [ ] T002 Create documentation structure: `docs/ci-cd/` with placeholder files
- [ ] T003 [P] Create contracts directory: `specs/003-github-actions-cicd/contracts/` with template files
- [ ] T003a [P] Document dependency versioning strategy: Create `.github/DEPENDENCY_STRATEGY.md` specifying how AASDK/OpenAuto versions are selected (pinned tags, latest compatible, or main branch)
- [ ] T003b [P] Verify build.sh flag compatibility: Check existing `scripts/build.sh` for `--architecture` and `--skip-tests` flags; document if they need alignment with Phase 4 additions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core quality scanning infrastructure - MUST complete before any workflow enhancements

**⚠️ CRITICAL**: No user story work can begin until quality scanning foundation is ready

- [ ] T004 Create quality scan wrapper script: `.github/scripts/quality/check-format.sh` (clang-format in check mode)
- [ ] T005 [P] Create quality scan wrapper script: `.github/scripts/quality/check-tidy.sh` (clang-tidy with compilation database)
- [ ] T006 [P] Create quality scan wrapper script: `.github/scripts/quality/check-cppcheck.sh` (cppcheck with project config)
- [ ] T007 [P] Extend license check script: `scripts/check_license_headers.sh` to output GitHub Actions JSON format
- [ ] T008 Create reusable quality scan workflow: `.github/workflows/quality-scan.yml` with workflow_call interface
- [ ] T009 Define quality-scan.yml contract: `specs/003-github-actions-cicd/contracts/quality-scan.md` (inputs, outputs, behavior)

**Checkpoint**: Quality scanning infrastructure ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Developer Code Quality Feedback (Priority: P1) 🎯 MVP

**Goal**: Provide fast automated code quality feedback (< 2 min) on feature branch pushes

**Independent Test**: Push code with intentional style violations to feature branch, verify workflow runs and posts PR comment

### Implementation for User Story 1

- [ ] T010 [US1] Update ci.yml: Add quality-scan job before build job in `.github/workflows/ci.yml`
- [ ] T011 [US1] Configure quality-scan job: Call quality-scan.yml reusable workflow with fail-on-error=true
- [ ] T012 [US1] Implement PR comment posting: Use github-script action to post quality report as PR comment
- [ ] T013 [US1] Add skip check logic: Detect `[skip ci]` or `[ci skip]` in commit message and skip quality scan
- [ ] T014 [US1] Update quality-scan.yml: Implement parallel execution of all 4 checks (format, tidy, cppcheck, licenses)
- [ ] T015 [US1] Add quality report formatting: Generate markdown report with file paths, line numbers, suggested fixes
- [ ] T016 [US1] Add workflow timing: Measure and output execution time to verify < 2 min target
- [ ] T017 [US1] Create documentation: `docs/ci-cd/quality-checks.md` (what checks run, how to run locally, common fixes)

**Checkpoint**: User Story 1 complete - developers get fast quality feedback on PRs

---

## Phase 4: User Story 2 - Fast Iteration Feedback (Priority: P1) 🎯 MVP

**Goal**: Provide quick build feedback (< 5 min) via amd64-only builds for feature branches

**Independent Test**: Push code to feature branch, verify amd64-only build completes in < 5 min with artifacts

### Implementation for User Story 2

- [ ] T018 [US2] Update ci.yml: Add conditional architecture logic (amd64-only for feature branches, all for main/develop) in `.github/workflows/ci.yml`
- [ ] T019 [US2] Update build.yml: Add quality-scan-status input and pass to build workflow in `.github/workflows/build.yml`
- [ ] T020 [US2] Implement fastpath: Skip build entirely if quality fails and branch is not main/develop
- [ ] T021 [US2] Add build-run-id output: Export workflow run ID from ci.yml for downstream workflows
- [ ] T022 [P] [US2] Implement CMake build caching: Cache build artifacts by os-arch-compiler-hash in build.yml
- [ ] T023 [P] [US2] Implement QEMU setup caching: Cache QEMU for arm64/armhf builds in build.yml
- [ ] T024 [US2] Update build.yml artifact metadata: Include build timestamp, git SHA, quality scan results in artifact JSON
- [ ] T025 [US2] Update scripts/build.sh: Add `--architecture` and `--skip-tests` flags for explicit control
- [ ] T026 [US2] Improve build error messages: Add file/line context to build failures in scripts/build.sh

**Checkpoint**: User Story 2 complete - fast amd64-only builds for feature branches

---

## Phase 5: User Story 3 - Automated Package Publishing (Priority: P1) 🎯 MVP

**Goal**: Auto-publish DEB packages to APT repository (nightly channel) when code merges to main

**Independent Test**: Merge PR to main, verify all 3 architecture DEBs published to nightly APT within 30 min, installable via apt

### Implementation for User Story 3

- [ ] T027 [P] [US3] Create validation wrapper script: `.github/scripts/package/validate-deb.sh` (lintian checks)
- [ ] T028 [P] [US3] Create signing wrapper script: `.github/scripts/package/sign-packages.sh` (GPG signing with key validation)
- [ ] T029 [P] [US3] Create publish orchestration script: `.github/scripts/package/publish-apt.sh` (staging → production atomic swap)
- [ ] T030 [US3] Create reusable validation workflow: `.github/workflows/apt-validate.yml` with workflow_call interface
- [ ] T031 [US3] Define apt-validate.yml contract: `specs/003-github-actions-cicd/contracts/apt-validate.md`
- [ ] T032 [US3] Rename and update APT publish workflow: Rename `trigger-apt-publish.yml` to `apt-publish.yml` in `.github/workflows/`
- [ ] T033 [US3] Add workflow_call interface to apt-publish.yml: Enable auto-trigger from CI with inputs (build-run-id, channel, architectures)
- [ ] T034 [US3] Implement artifact download in apt-publish.yml: Download DEBs from build-run-id using GitHub Actions API
- [ ] T035 [US3] Implement package validation in apt-publish.yml: Call apt-validate.yml for each package before publishing
- [ ] T036 [US3] Implement staging upload: Upload packages to staging directory on APT server via SSH/SFTP
- [ ] T037 [US3] Implement metadata generation: Generate Packages.gz and Release files in staging
- [ ] T038 [US3] Implement GPG signing: Sign Release file with GPG key from GitHub Secrets (APT_SIGNING_KEY)
- [ ] T039 [US3] Implement atomic promotion: Atomically move staging → production (symlink swap or rsync --delete)
- [ ] T039a [US3] REFINEMENT: Document atomic promotion implementation: Use symlink swap for true atomicity - create staging as `/staging/apt.new`, then `ln -sfn` and `mv -T` for atomic cutover in apt-publish.sh
- [ ] T040 [US3] Add rollback capability: Keep last-good as backup in apt-publish.yml
- [ ] T041 [US3] Add concurrency control: Ensure only one APT publish at a time (queue others) in apt-publish.yml
- [ ] T041a [US3] REFINEMENT: Document concurrency mechanism: Use GitHub Actions native `concurrency` key in apt-publish.yml (not custom mutex) - simpler, no state management needed
- [ ] T042 [US3] Update ci.yml: Add apt-publish job that dispatches apt-publish.yml on successful main/develop builds
- [ ] T043 [US3] Create documentation: `docs/ci-cd/apt-publishing.md` (repository structure, package flow, GPG management, rollback)

**Checkpoint**: User Story 3 complete - automated APT publishing from main branch

---

## Phase 6: User Story 4 - Stable Release Creation (Priority: P2)

**Goal**: Auto-create GitHub release with comprehensive notes, DEBs, checksums, SBOM when version tag pushed

**Independent Test**: Push version tag (e.g., v1.2.0), verify release created within 10 min with all artifacts and formatted notes

### Implementation for User Story 4

- [ ] T044 [P] [US4] Create changelog generation script: `.github/scripts/release/generate-notes.sh` (parse git log, categorize commits)
- [ ] T045 [P] [US4] Create SBOM generation script: `.github/scripts/release/generate-sbom.sh` (extract dependencies, format as SPDX/CycloneDX)
- [ ] T045a [P] [US4] REFINEMENT: Document SBOM format selection: Use SPDX format for release notes (more widely adopted than CycloneDX) - implement in generate-sbom.sh with standard SPDX output
- [ ] T046 [US4] Create reusable release notes workflow: `.github/workflows/release-notes.yml` with workflow_call interface
- [ ] T047 [US4] Define release-notes.yml contract: `specs/003-github-actions-cicd/contracts/release-notes.md`
- [ ] T048 [US4] Implement release-notes.yml: Generate markdown with version, commit SHA, build info, categorized changelog, install instructions, checksums
- [ ] T049 [US4] Update release.yml: Add auto-trigger on push of tag matching `v*.*.*` pattern in `.github/workflows/release.yml`
- [ ] T050 [US4] Add tag validation in release.yml: Validate semver format (regex: `^v[0-9]+\.[0-9]+\.[0-9]+$`), fail fast if invalid
- [ ] T051 [US4] Implement build trigger in release.yml: Dispatch ci.yml with all architectures via workflow_dispatch
- [ ] T052 [US4] Implement build wait logic in release.yml: Poll workflow run API until build completes or timeout
- [ ] T053 [US4] Implement artifact download in release.yml: Download all architecture DEBs from completed build
- [ ] T054 [US4] Call release-notes.yml in release.yml: Generate comprehensive release notes
- [ ] T055 [US4] Implement checksum generation in release.yml: Generate SHA256 for all artifacts
- [ ] T056 [US4] Implement GitHub release creation in release.yml: Create release with tag, name, body, assets (DEBs, checksums, SBOM)
- [ ] T057 [US4] Implement draft release support in release.yml: Support create_draft input for manual review before publishing
- [ ] T058 [US4] Add stable APT publish in release.yml: Dispatch apt-publish.yml with channel=stable after release creation
- [ ] T059 [US4] Add release validation in release.yml: Verify all expected artifacts attached and checksums valid
- [ ] T060 [US4] Create documentation: `docs/ci-cd/release-process.md` (auto vs manual, semver, failed release handling, hotfixes)

**Checkpoint**: User Story 4 complete - automated stable releases from version tags

---

## Phase 7: User Story 5 - Raspberry Pi Image Distribution (Priority: P2)

**Goal**: Build bootable Pi images (armhf/arm64) with Crankshaft pre-installed, attachable to releases

**Independent Test**: Trigger Pi-gen workflow, verify images created within 4 hours, boot on real Pi hardware with Crankshaft running

### Implementation for User Story 5

- [ ] T061 [US5] Update build-pi-gen-lite.yml: Add workflow_call interface in `.github/workflows/build-pi-gen-lite.yml`
- [ ] T061a [US5] REFINEMENT: Verify pi-gen branch compatibility: Document which pi-gen branches are used (master for armhf, arm64 for arm64) and confirm they're maintained/stable
- [ ] T062 [US5] Add release-tag input to build-pi-gen-lite.yml: Support version-specific image builds
- [ ] T063 [US5] Add attach-to-release input to build-pi-gen-lite.yml: Enable auto-attach to GitHub releases
- [ ] T064 [US5] Create Crankshaft pi-gen stage: `image_builder/pi-gen-stages/stage-crankshaft/` with stage scripts
- [ ] T065 [US5] Implement APT repository addition in stage-crankshaft: Add OpenCarDev APT repository to sources
- [ ] T066 [US5] Implement package installation in stage-crankshaft: Install Crankshaft packages (version-specific or latest nightly)
- [ ] T067 [US5] Implement service configuration in stage-crankshaft: Enable Crankshaft services, set up first-boot scripts
- [ ] T068 [US5] Implement parallel xz compression in build-pi-gen-lite.yml: Use `xz --threads=0` for faster compression
- [ ] T069 [US5] Implement SHA256 checksum generation in build-pi-gen-lite.yml: Generate checksums for all images
- [ ] T070 [US5] Create image metadata JSON in build-pi-gen-lite.yml: Include size, checksum, Debian release, packages
- [ ] T071 [US5] Implement auto-attach logic in build-pi-gen-lite.yml: If attach-to-release=true, attach images to GitHub release via API
- [ ] T072 [US5] Update release.yml: Trigger Pi-gen builds with attach-to-release=true during release creation
- [ ] T073 [US5] Create documentation: `docs/ci-cd/pi-gen-images.md` (manual triggers, customization, troubleshooting, flashing)

**Checkpoint**: User Story 5 complete - Pi-gen images with Crankshaft pre-installed

---

## Phase 8: User Story 6 - Manual Release Control (Priority: P3)

**Goal**: Support creating releases from existing builds without rebuilding (promote tested artifacts)

**Independent Test**: Trigger release workflow manually with specific build-run-id, verify release uses exact artifacts without rebuilding

### Implementation for User Story 6

- [ ] T074 [US6] Add manual release mode to release.yml: Support workflow_dispatch with build-run-id input in `.github/workflows/release.yml`
- [ ] T075 [US6] Implement artifact reuse logic in release.yml: If build-run-id provided, skip build trigger and use existing artifacts
- [ ] T076 [US6] Add artifact validation in release.yml: Verify artifacts from build-run-id exist before proceeding (fail fast if expired)
- [ ] T077 [US6] Implement draft review workflow in release.yml: If create_draft=true, create draft release for manual review
- [ ] T078 [US6] Update documentation in docs/ci-cd/release-process.md: Document manual release creation and draft promotion process

**Checkpoint**: User Story 6 complete - manual release control with artifact reuse

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and improvements across all user stories

- [ ] T079 [P] Create workflow guide: `docs/ci-cd/workflow-guide.md` (overview of all workflows, triggers, purposes)
- [ ] T080 [P] Create troubleshooting guide: `docs/ci-cd/troubleshooting.md` (top 10 common issues with solutions)
- [ ] T081 [P] Create developer handbook: `docs/ci-cd/developer-handbook.md` (how developers interact with CI)
- [ ] T082 [P] Create maintainer handbook: `docs/ci-cd/maintainer-handbook.md` (advanced workflows, debugging, rollbacks)
- [ ] T083 [P] Create architecture decisions doc: `docs/ci-cd/architecture-decisions.md` (why extend vs rewrite, tool choices)
- [ ] T083a [P] REFINEMENT: Create success criteria checklist template: `.github/templates/success-criteria-checklist.md` - reusable template for SC-001 through SC-019 validation with measurement columns
- [ ] T084 Test US1 end-to-end: Push code with violations, verify quality feedback in < 2 min
- [ ] T085 Test US2 end-to-end: Push to feature branch, verify amd64-only build in < 5 min
- [ ] T086 Test US3 end-to-end: Merge to main, verify APT publish completes, test apt install on Pi
- [ ] T087 Test US4 end-to-end: Push version tag, verify release created with all artifacts
- [ ] T088 Test US5 end-to-end: Trigger Pi-gen build, verify images boot on Raspberry Pi 4
- [ ] T089 Test US6 end-to-end: Create manual release from existing build-run-id
- [ ] T090 Validate success criteria: Create checklist for SC-001 through SC-019, measure actual vs targets
- [ ] T091 Performance validation: Measure quality scan time, build times, publish time, release time
- [ ] T092 Security validation: Verify GPG signing works, secrets masked in logs, access controls correct
- [ ] T093 Failure recovery testing: Test rollback procedures, retry logic, timeout handling
- [ ] T094 Code cleanup: Remove debug logging, optimize scripts, refactor duplicated code
- [ ] T095 Update main README: Add CI/CD status badges, link to docs/ci-cd/ documentation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational completion
  - US1 (P1): Quality feedback - no story dependencies
  - US2 (P1): Fast builds - depends on US1 (quality scan integrated)
  - US3 (P1): APT publish - depends on US2 (builds produce artifacts)
  - US4 (P2): Releases - depends on US2 (builds), US3 (APT publish for stable)
  - US5 (P2): Pi-gen images - depends on US3 (APT packages for image installation)
  - US6 (P3): Manual control - depends on US4 (extends release workflow)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

```
Foundational (Phase 2)
    │
    ├─> US1 (P1): Quality Feedback
    │       │
    │       v
    ├─> US2 (P1): Fast Builds [depends on US1]
    │       │
    │       v
    ├─> US3 (P1): APT Publish [depends on US2]
    │       │
    │       ├─> US4 (P2): Stable Releases [depends on US2, US3]
    │       │       │
    │       │       v
    │       │   US6 (P3): Manual Control [depends on US4]
    │       │
    │       └─> US5 (P2): Pi-gen Images [depends on US3]
```

### Critical Path

**Fastest route to MVP (all P1 stories)**:
Setup → Foundational → US1 → US2 → US3 = ~10-12 days

**Full feature delivery**:
Setup → Foundational → US1 → US2 → US3 → US4 → US5 → US6 → Polish = ~21 days

### Parallel Opportunities

**Phase 2 (Foundational)**: T005, T006, T007 can run parallel with T004

**Phase 3 (US1)**: No parallelization (sequential workflow updates)

**Phase 4 (US2)**: T022, T023 can run parallel with earlier tasks

**Phase 5 (US3)**: T027, T028, T029 can run parallel; documentation parallel with implementation

**Phase 6 (US4)**: T044, T045 can run parallel early in phase

**Phase 7 (US5)**: Most tasks sequential (workflow updates)

**Phase 8 (US6)**: Quick phase, minimal parallelization

**Phase 9 (Polish)**: T079-T083 (all documentation) can run in parallel; T084-T089 (all tests) can run in parallel

---

## Parallel Example: User Story 3 (APT Publishing)

```bash
# Start these in parallel:
T027: Create validate-deb.sh
T028: Create sign-packages.sh  
T029: Create publish-apt.sh

# Then sequential:
T030: Create apt-validate.yml (needs T027)
T031: Document apt-validate contract
T032: Rename workflow file
T033: Add workflow_call interface
...continue sequentially...

# Documentation can run parallel with late implementation:
T043: Write apt-publishing.md (parallel with T040-T042)
```

---

## Implementation Strategy

**MVP First (P1 stories only)**:
1. Complete Setup + Foundational (~3 days)
2. Complete US1: Quality feedback (~2 days)
3. Complete US2: Fast builds (~3 days)
4. Complete US3: APT publish (~4 days)
5. **Total MVP**: ~12 days
6. **Value**: Developers have fast feedback, automated builds, automated publishing to nightly

**Incremental Delivery**:
- MVP delivers P1: Core developer productivity and automation
- Add US4 (P2): Automated stable releases (~4 days) - high value, infrequent use
- Add US5 (P2): Pi-gen images (~3 days) - simplifies user onboarding
- Add US6 (P3): Manual control (~1 day) - advanced use case, low friction to add
- Polish (~3 days): Documentation, testing, validation

**Success Metrics Validation** (Phase 9):
- SC-001: Quality feedback < 2 min (measure via T084)
- SC-004: amd64 builds < 5 min (measure via T085)
- SC-005: Multi-arch builds < 20 min (measure via T086)
- SC-009: 100% GPG signing (validate via T092)
- SC-011: Release creation < 30 min (measure via T087)
- SC-006: Pi-gen < 4 hours (measure via T088)
- All 19 criteria validated in T090

---

## Risk Mitigation Tasks

- **T039 (atomic promotion)**: Mitigates APT corruption risk
- **T040 (rollback capability)**: Mitigates failed publish risk  
- **T041 (concurrency control)**: Mitigates concurrent publish conflicts
- **T050 (tag validation)**: Mitigates invalid release tag risk
- **T052 (build wait with timeout)**: Mitigates hung build risk
- **T059 (release validation)**: Mitigates incomplete release risk
- **T076 (artifact validation)**: Mitigates artifact expiration risk
- **T093 (failure recovery testing)**: Validates all mitigation strategies work

---

## Next Steps

1. **Review task breakdown** with team for estimation refinement
2. **Begin Phase 1 (Setup)**: Create directory structure (T001-T003) - ~1 day
3. **Proceed to Phase 2 (Foundational)**: Build quality scanning infrastructure (T004-T009) - ~2 days
4. **Start US1 (Quality Feedback)**: First MVP increment (T010-T017) - ~2 days
5. **Continue sequentially through P1 stories** to reach MVP milestone
6. **Add P2/P3 stories incrementally** based on priority and capacity
7. **Validate success criteria** in Phase 9 before marking feature complete

**Estimated Total Effort**: 21 days (sequential) or 18 days (with parallelization in foundational + polish phases)

---

## Refinement Tasks Summary

This task list includes **6 REFINEMENT tasks** (T003a, T003b, T039a, T041a, T045a, T061a, T083a) that address clarifications identified in the ANALYSIS_REPORT.md:

| Refinement Task | Purpose | Phase | Effort | Critical Path Impact |
|-----------------|---------|-------|--------|----------------------|
| **T003a** | Document dependency versioning (AASDK/OpenAuto) | 1 | 1-2 hrs | None (parallel) |
| **T003b** | Verify build.sh flag compatibility | 1 | 15 min | None (parallel) |
| **T039a** | Document symlink swap implementation for atomic promotion | 5 | 30 min | None (parallel) |
| **T041a** | Document GitHub concurrency key for queue logic | 5 | 5 min | None (parallel) |
| **T045a** | Specify SPDX format for SBOM generation | 6 | 15 min | None (parallel) |
| **T061a** | Verify pi-gen branch stability | 7 | 30 min | None (parallel) |
| **T083a** | Create success criteria validation checklist template | 9 | 30 min | None (parallel) |

**Total refinement effort**: ~3.5 hours  
**Total task count**: 102 tasks (95 original + 7 refinement)  
**Impact on critical path**: ZERO - all refinements marked [P] or run parallel to phase work
