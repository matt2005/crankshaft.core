# Implementation Plan: Comprehensive GitHub Actions CI/CD Pipeline

**Branch**: `003-github-actions-cicd` | **Date**: 2025-01-28 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/003-github-actions-cicd/spec.md`

## Summary

Implement a comprehensive CI/CD pipeline using GitHub Actions that provides automated code quality scanning, multi-architecture builds (Debian Trixie: amd64/arm64/armhf), APT package publishing, Pi-gen image creation, and automated release management. The system leverages existing proven workflows (build.yml, ci.yml, release.yml) and extends them with enhanced capabilities while maintaining fast developer feedback loops (< 5 min for feature branches).

**Primary Goals**:
1. Enable fast developer feedback with quality scanning (< 2 min) and amd64-only builds (< 5 min) for feature branches
2. Automate full multi-architecture package publishing to APT repository (nightly/stable channels)
3. Automate release creation with comprehensive notes, checksums, and SBOM
4. Provide Pi-gen image builds integrated with release workflow

## Technical Context

**Language/Version**: GitHub Actions YAML (workflow DSL), Bash scripting 5.x  
**Primary Dependencies**: 
- GitHub Actions platform (workflow runners, artifact storage, API)
- Build tools: CMake 3.25+, clang-format 14+, clang-tidy 14+, cppcheck 2.x
- Cross-compilation: QEMU user-static, cross-compiler toolchains (arm64, armhf)
- Package tools: dpkg, lintian, GPG (gnupg2), aptly or custom APT repository tools
- Pi-gen: Raspberry Pi Foundation's official image builder
- Version control: Git with semver tagging convention

**Storage**: 
- GitHub Artifacts (90-day retention, 10GB per workflow run limit)
- External APT repository server (SSH/SFTP access, 50GB minimum)
- GitHub Releases (2GB per file, 10GB per release)

**Testing**: 
- Workflow validation: act (local GitHub Actions runner) or workflow_dispatch testing
- Package validation: lintian checks, dependency resolution tests
- Integration testing: Real hardware validation (Raspberry Pi 4) for Pi-gen images
- Contract testing: Verify workflow inputs/outputs match expectations

**Target Platform**: 
- CI/CD: GitHub Actions hosted runners (ubuntu-latest, 2-core/7GB RAM standard)
- Build targets: Debian Trixie (amd64 native, arm64/armhf cross-compiled via QEMU)
- Deployment: APT repository (Debian-based systems), GitHub Releases

**Project Type**: DevOps/CI/CD infrastructure (workflow orchestration)

**Performance Goals**:
- Code quality feedback: < 2 minutes from push to PR comment
- amd64-only build (feature branches): < 5 minutes to artifacts
- Full multi-arch build (main/develop): < 20 minutes to artifacts
- APT publish: < 5 minutes from artifacts to published packages
- Release creation: < 30 minutes from tag push to published release
- Pi-gen image build: < 4 hours (240 minute timeout)

**Constraints**:
- GitHub Actions free tier: 2000 minutes/month for public repos, 20 concurrent jobs
- Artifact size: 10GB per workflow run (Pi-gen images ~3GB compressed acceptable)
- QEMU emulation: 3-5x slower than native builds (acceptable for CI)
- APT publish atomicity: Must avoid partial repository states visible to users
- Build reproducibility: Cannot guarantee byte-identical builds (timestamps in DEBs acceptable)
- Network: Must handle transient failures with retry logic (3 attempts, exponential backoff)

**Scale/Scope**:
- Workflows: 8 total (5 existing to extend + 3 new to create)
- User stories: 6 prioritized (P1: 3, P2: 2, P3: 1)
- Functional requirements: 45 across 6 categories
- Success criteria: 19 measurable outcomes
- Target architectures: 3 (amd64, arm64, armhf)
- APT channels: 2 (nightly from main, stable from version tags)

## Constitution Check

**Status**: ✅ PASSED - No violations or deviations

### Impacted Principles & Compliance

**Code Quality**:
- ✅ Compliant: FR-001 to FR-006 implement automated quality scanning (clang-format, clang-tidy, cppcheck, license headers)
- ✅ Measurable: SC-001 (< 2 min feedback), SC-002 (zero false positives), SC-003 (90% violation detection)
- Implementation: Phase 1 adds quality-scan.yml reusable workflow called before builds

**Testing**:
- ✅ Compliant: Static analysis catches bugs before runtime; lintian validates packages before publish
- ✅ Measurable: SC-019 (100% package validation), SC-007 (95% build success rate)
- Implementation: Phase 3 adds apt-validate.yml for package integrity checks

**Performance**:
- ✅ Compliant: Fast feedback loops for developers (amd64-only builds for feature branches)
- ✅ Measurable: SC-004 (< 5 min amd64), SC-005 (< 20 min multi-arch)
- Implementation: Phase 2 implements conditional architecture selection in ci.yml

**Observability**:
- ✅ Compliant: Real-time workflow status, comprehensive release notes with traceability
- ✅ Measurable: SC-008 (real-time status), SC-015 (root cause in first 50 log lines)
- Implementation: Phase 5 adds release-notes.yml for structured changelog generation

**Security**:
- ✅ Compliant: 100% GPG signing, secure key storage, package validation, SBOM inclusion
- ✅ Measurable: SC-009 (100% signed), SC-017 (SBOM included), SC-019 (100% validation)
- Implementation: Phase 3 implements GPG signing in APT publish workflow

**Maintainability**:
- ✅ Compliant: Reusable workflow patterns, clear separation of concerns, modular design
- ✅ Measurable: SC-016 (< 10 lines to adopt in other projects)
- Implementation: All phases use workflow_call pattern for reusability

**No Deviations**: This plan does not propose any deviations from constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/003-github-actions-cicd/
├── spec.md              # Feature specification (COMPLETE)
├── plan.md              # This file - implementation plan (CURRENT)
├── checklists/
│   └── requirements.md  # Specification validation (COMPLETE)
├── research.md          # Phase 0 - workflow analysis (embedded below)
├── contracts/           # Phase 1 - workflow input/output contracts
│   ├── quality-scan.md  # quality-scan.yml contract
│   ├── apt-validate.md  # apt-validate.yml contract
│   └── release-notes.md # release-notes.yml contract
└── tasks.md             # Phase breakdown with acceptance criteria (NEXT)
```

### Source Code (repository root)

```text
.github/
├── workflows/
│   ├── build.yml                  # [EXTEND] Reusable multi-arch build
│   ├── ci.yml                     # [EXTEND] Main CI workflow entry point
│   ├── release.yml                # [EXTEND] Release creation
│   ├── trigger-apt-publish.yml    # [EXTEND] APT package publishing
│   ├── build-pi-gen-lite.yml      # [EXTEND] Pi-gen image builds
│   ├── quality-scan.yml           # [NEW] Code quality checks (reusable)
│   ├── apt-validate.yml           # [NEW] Package validation (reusable)
│   └── release-notes.yml          # [NEW] Release note generation (reusable)
└── scripts/
    ├── quality/
    │   ├── check-format.sh        # [NEW] clang-format wrapper
    │   ├── check-tidy.sh          # [NEW] clang-tidy wrapper
    │   ├── check-cppcheck.sh      # [NEW] cppcheck wrapper
    │   └── check-licenses.sh      # [EXTEND] Existing license check
    ├── build/
    │   └── version-gen.sh         # [EXISTS] Version string generator
    ├── package/
    │   ├── validate-deb.sh        # [NEW] Package integrity validation
    │   └── sign-packages.sh       # [NEW] GPG signing wrapper
    └── release/
        ├── generate-notes.sh      # [NEW] Changelog generation
        └── generate-sbom.sh       # [NEW] SBOM creation

scripts/
├── build.sh                       # [EXISTS] Build orchestration
└── format_cpp.sh                  # [EXISTS] Code formatting

docs/
└── ci-cd/
    ├── workflow-guide.md          # [NEW] Workflow usage documentation
    ├── troubleshooting.md         # [NEW] Common CI issues & solutions
    └── release-process.md         # [NEW] Release creation guide
```

**Structure Decision**: 
- Workflows in `.github/workflows/` follow GitHub Actions convention
- Support scripts in `.github/scripts/` for workflow-specific logic (quality, validation, release)
- General build scripts remain in `scripts/` for local/CI use
- Documentation in `docs/ci-cd/` for developer reference
- Leverage existing workflows via extension (not replacement) to maintain proven patterns

## Complexity Tracking

**No Violations** - This plan adheres to all constitution principles without requiring justifications.

## Phase Breakdown

### Phase 0: Research & Discovery ✅ COMPLETE

**Status**: Research completed during specification phase.

**Key Findings**:

1. **Existing Workflow Patterns** (Analyzed):
   - `build.yml`: Reusable workflow with `workflow_call`, multi-arch matrix (amd64/arm64/armhf), version auto-generation (YYYY.MM.DD+git.SHA), conditional amd64-only mode
   - `ci.yml`: Triggers on push/PR, skip check ([skip ci]), lint job, calls build.yml, dispatches cd.yml, conditional architecture selection
   - `release.yml`: Manual workflow_dispatch, downloads artifacts from build run ID, generates release notes (version, commit, install instructions, SBOM ref), creates GitHub release
   - `build-pi-gen-lite.yml`: Matrix strategy (armhf master, arm64 branch), 240-minute timeout, workflow_call and workflow_dispatch, auto-release option
   - `trigger-apt-publish.yml`: Manual trigger for APT publishing (needs automation)

2. **Extension Strategy**:
   - Quality scanning: Add as pre-build step in ci.yml via new quality-scan.yml reusable workflow
   - Build workflow: Already optimal, add quality-scan call before build invocation
   - APT publish: Auto-trigger from ci.yml on successful main/develop builds via workflow_dispatch
   - Release: Auto-trigger on version tag push, enhance notes generation, integrate Pi-gen images
   - Pi-gen: Maintain existing pattern, add auto-attach to releases

3. **Tool Selection**:
   - Code quality: clang-format (style), clang-tidy (static analysis), cppcheck (additional checks), existing license script
   - Package validation: lintian (Debian package checks), dpkg-deb (metadata extraction)
   - GPG signing: gnupg2 with key from GitHub Secrets
   - Release notes: git log with conventional commit parsing, markdown formatting
   - SBOM: syft or custom dependency extraction (specify in Phase 1)

4. **Risk Assessment**:
   - **High**: APT publish atomicity - mitigation: staging → production promotion pattern
   - **Medium**: Pi-gen build timeout (4 hours) - mitigation: maintain existing timeout, document expected duration
   - **Medium**: QEMU performance (3-5x slower) - mitigation: acceptable for CI, prioritize amd64 for fast feedback
   - **Low**: Artifact expiration (90 days) - mitigation: document in release workflow, fail fast with clear error
   - **Low**: Network failures - mitigation: retry logic with exponential backoff (3 attempts)

### Phase 1: Enhanced Code Quality Scanning

**Goal**: Add comprehensive code quality checks that run before builds, providing fast feedback to developers.

**Deliverables**:
1. New reusable workflow: `.github/workflows/quality-scan.yml`
   - Inputs: repository path, fail-on-error flag, report format (text/json)
   - Runs: clang-format check, clang-tidy analysis, cppcheck scan, license header check
   - Outputs: Combined quality report (job summary + artifact), exit code (0 = pass)
   - Performance: Target < 2 minutes execution time

2. Support scripts in `.github/scripts/quality/`:
   - `check-format.sh`: Runs clang-format in check mode, outputs diff if failures
   - `check-tidy.sh`: Runs clang-tidy with compilation database, filters relevant warnings
   - `check-cppcheck.sh`: Runs cppcheck on src directories, configures check categories
   - Extend `scripts/check_license_headers.sh` for GitHub Actions JSON output format

3. Update `ci.yml`:
   - Add quality-scan job before build job (depends_on: [])
   - Call quality-scan.yml reusable workflow with fail-on-error: true
   - Post results as PR comment (using github-script action)
   - Build job runs only if quality-scan succeeds

4. Documentation: `docs/ci-cd/quality-checks.md`
   - List of checks performed
   - How to run locally
   - Common issues and fixes
   - How to skip checks ([skip ci])

**Acceptance Criteria**:
- [ ] quality-scan.yml workflow completes in < 2 minutes for typical PR
- [ ] All four checks (format, tidy, cppcheck, licenses) run in parallel where possible
- [ ] PR comment includes file paths, line numbers, and suggested fixes
- [ ] Workflow fails on quality issues but provides actionable feedback
- [ ] Documentation allows developers to reproduce checks locally

**Dependencies**: None (foundational phase)

**Estimated Effort**: 2-3 days

---

### Phase 2: Multi-Architecture Build Improvements

**Goal**: Optimize build workflow for fast developer feedback while maintaining multi-arch capability.

**Deliverables**:
1. Update `build.yml`:
   - Add quality scan as optional pre-step (input: run_quality_scan, default: false)
   - Improve artifact metadata (include build timestamp, git SHA, quality scan results)
   - Add output: build-info JSON with version, architectures, artifact IDs

2. Update `ci.yml`:
   - Implement conditional architecture logic: amd64-only for feature branches, all architectures for main/develop
   - Pass quality scan status to build.yml
   - Add fastpath: if quality fails and branch is not main/develop, skip build entirely
   - Add workflow output: build-run-id for downstream workflows (cd.yml, apt-publish)

3. Add build caching (GitHub Actions cache):
   - Cache CMake build artifacts by architecture (key: os-arch-compiler-hash(CMakeLists.txt))
   - Cache QEMU setup for arm64/armhf builds
   - Target: 20% build time reduction on cache hit

4. Update `scripts/build.sh`:
   - Add `--architecture` flag for explicit arch selection
   - Add `--skip-tests` flag for faster CI builds (tests run separately)
   - Improve error messages with file/line context

**Acceptance Criteria**:
- [ ] Feature branch builds complete in < 5 minutes (amd64-only)
- [ ] Main branch builds complete in < 20 minutes (all architectures)
- [ ] Build artifacts include comprehensive metadata (version, SHA, timestamp, architectures)
- [ ] Cache hit reduces build time by at least 15%
- [ ] Build failures include clear error context (file, line, architecture)

**Dependencies**: Phase 1 (quality scanning integrated)

**Estimated Effort**: 3-4 days

---

### Phase 3: APT Package Publishing Automation

**Goal**: Automate APT package publishing with GPG signing, validation, and atomic repository updates.

**Deliverables**:
1. New reusable workflow: `.github/workflows/apt-validate.yml`
   - Inputs: artifact path, architecture, Debian release
   - Runs: lintian checks, dependency resolution validation, metadata extraction
   - Outputs: validation report (pass/fail + details), package info JSON

2. Update `trigger-apt-publish.yml`:
   - Rename to `apt-publish.yml` (remove "trigger" prefix for clarity)
   - Add workflow_call interface (enable auto-trigger from CI)
   - Inputs: build-run-id, channel (nightly/stable), architectures (comma-separated)
   - Download artifacts from build-run-id
   - Call apt-validate.yml for each package before publishing
   - Implement staging → production promotion:
     1. Upload packages to staging directory
     2. Generate Packages.gz and Release files
     3. Sign with GPG (key from secrets.APT_SIGNING_KEY)
     4. Atomically move staging → production (symlink swap or rsync --delete)
   - Add rollback capability: keep last-good as backup

3. Support scripts in `.github/scripts/package/`:
   - `validate-deb.sh`: Wrapper for lintian with project-specific rules
   - `sign-packages.sh`: GPG signing with key validation and error handling
   - `publish-apt.sh`: Atomic publish orchestration (staging → production)

4. Update `ci.yml`:
   - Add apt-publish job (runs only on main/develop after successful build)
   - Dispatch apt-publish.yml with build-run-id and channel (nightly)
   - Add concurrency control: only one APT publish at a time (queue others)

5. Documentation: `docs/ci-cd/apt-publishing.md`
   - APT repository structure
   - How packages flow from build → validation → publish
   - GPG key management (rotation procedure)
   - Rollback procedure for failed publishes

**Acceptance Criteria**:
- [ ] Packages validated with lintian before publishing (100% coverage)
- [ ] All packages GPG-signed (100% compliance)
- [ ] APT repository updates are atomic (no partial states visible to users)
- [ ] Publishing completes in < 5 minutes from build completion
- [ ] Rollback procedure documented and tested
- [ ] CI auto-triggers APT publish on successful main/develop builds

**Dependencies**: Phase 2 (build workflow outputs build-run-id)

**Estimated Effort**: 4-5 days

---

### Phase 4: Pi-gen Image Integration

**Goal**: Integrate Pi-gen image builds with release workflow, enabling automated image distribution.

**Deliverables**:
1. Update `build-pi-gen-lite.yml`:
   - Add workflow_call interface (enable triggering from release.yml)
   - Add input: release-tag (optional, for version-specific image builds)
   - Add input: attach-to-release (boolean, default false)
   - Implement auto-attach logic:
     1. If attach-to-release=true and release-tag provided
     2. Build images (armhf + arm64)
     3. Upload as workflow artifacts
     4. Attach to GitHub release via API (gh release upload)
   - Add output: image-artifact-ids for manual download

2. Create `image_builder/pi-gen-stages/stage-crankshaft/`:
   - Custom pi-gen stage that installs Crankshaft packages
   - Stage script: apt-add-repository (OpenCarDev APT), apt-install crankshaft-*
   - Configuration: enable services, set up first-boot scripts
   - Package source selection: version-specific (from release-tag) or latest nightly

3. Update image compression:
   - Add `xz --threads=0` for parallel compression (reduce time by 30%)
   - Generate SHA256 checksums for all images
   - Create image metadata JSON: size, checksum, Debian release, included packages

4. Documentation: `docs/ci-cd/pi-gen-images.md`
   - How to trigger manual Pi-gen builds
   - Image customization guide (adding stages)
   - Troubleshooting long build times
   - How to flash and verify images

**Acceptance Criteria**:
- [ ] Pi-gen builds complete within 4-hour timeout 95% of the time
- [ ] Images compressed to < 800MB (lite image target)
- [ ] SHA256 checksums generated for all images
- [ ] Images can be auto-attached to releases when triggered from release.yml
- [ ] Crankshaft packages correctly installed and functional on first boot
- [ ] Both armhf and arm64 images build successfully in parallel

**Dependencies**: Phase 3 (APT publishing provides packages for image installation)

**Estimated Effort**: 3-4 days

---

### Phase 5: Release Automation Orchestration

**Goal**: Automate release creation with comprehensive notes, checksums, SBOM, and integrated Pi-gen images.

**Deliverables**:
1. New reusable workflow: `.github/workflows/release-notes.yml`
   - Inputs: from-tag (previous release), to-tag (current release), repository
   - Generates: Markdown release notes with:
     - Version header and commit SHA
     - Build information (date, workflow run ID)
     - Changelog: categorized commits (feat/fix/docs/chore/BREAKING)
     - Installation instructions per architecture (apt-get, direct download)
     - SBOM reference (link to artifact)
     - SHA256 checksums for all packages
   - Outputs: release-notes.md (artifact)

2. Support scripts in `.github/scripts/release/`:
   - `generate-notes.sh`: Parse git log, categorize commits, format Markdown
   - `generate-sbom.sh`: Extract dependencies from built packages, format as SBOM (SPDX or CycloneDX)

3. Update `release.yml`:
   - Add auto-trigger: on push of tag matching `v*.*.*` (in addition to manual workflow_dispatch)
   - Validate tag format (regex: `^v[0-9]+\.[0-9]+\.[0-9]+$`) and fail fast if invalid
   - Workflow steps:
     1. Validate tag format
     2. Trigger full multi-arch build (workflow_dispatch to ci.yml with all architectures)
     3. Wait for build completion (use workflow run API polling)
     4. Trigger Pi-gen builds (workflow_dispatch to build-pi-gen-lite.yml with attach-to-release=true)
     5. Generate release notes (call release-notes.yml)
     6. Download all artifacts (DEB packages from build, images from Pi-gen)
     7. Generate checksums (SHA256 for all artifacts)
     8. Create GitHub release:
        - Tag: version tag
        - Name: "Crankshaft v{version}"
        - Body: generated release notes
        - Assets: all DEBs, Pi-gen images, checksums.txt, SBOM
        - Draft: configurable via input (default: false for auto-trigger, true for manual)
   - Add APT publish step: dispatch apt-publish.yml with channel=stable

4. Add release validation:
   - After release creation, verify all expected artifacts are attached
   - Verify checksums match built artifacts
   - Verify SBOM is valid and complete

5. Documentation: `docs/ci-cd/release-process.md`
   - How to create releases (auto via tag or manual)
   - Release naming conventions (semver)
   - How to handle failed releases (rollback, delete tag)
   - How to create hotfix releases
   - How to promote draft releases to published

**Acceptance Criteria**:
- [ ] Pushing version tag auto-triggers release workflow
- [ ] Release completes in < 30 minutes from tag push
- [ ] Release notes include all required sections (changelog, install instructions, checksums, SBOM)
- [ ] All architecture DEBs attached to release (amd64, arm64, armhf)
- [ ] Pi-gen images auto-attached if builds complete in time
- [ ] Packages published to stable APT channel
- [ ] Release validation confirms all artifacts present and checksums valid
- [ ] Manual release creation (workflow_dispatch) supports creating drafts for review

**Dependencies**: Phase 2 (builds), Phase 3 (APT publish), Phase 4 (Pi-gen images)

**Estimated Effort**: 4-5 days

---

### Phase 6: Documentation & Testing

**Goal**: Comprehensive documentation, workflow testing, and validation against success criteria.

**Deliverables**:
1. Complete documentation in `docs/ci-cd/`:
   - `workflow-guide.md`: Overview of all workflows, when they run, what they do
   - `troubleshooting.md`: Common issues (build failures, timeout, artifact expiration) with solutions
   - `developer-handbook.md`: How developers interact with CI (pushing code, creating releases)
   - `maintainer-handbook.md`: Advanced workflows (manual triggers, debugging, rollbacks)
   - `architecture-decisions.md`: Why existing workflows extended vs rewritten, tool choices, patterns

2. Workflow testing:
   - Test all user scenarios from spec with real workflows
   - Create test branches/tags to verify conditional logic
   - Validate error handling (network failures, build failures, timeout)
   - Performance validation: measure actual times vs targets (SC-001 to SC-006)
   - Security validation: verify GPG signing, secret handling, access controls

3. Success criteria validation:
   - Create validation checklist matching spec.md success criteria (SC-001 to SC-019)
   - Measure and document actual performance: quality feedback time, build times, publish times
   - Validate developer experience: manual dispatch, log clarity, workflow reusability
   - Document any gaps or trade-offs vs original goals

4. Integration testing:
   - End-to-end test: push code → quality scan → build → APT publish → verify installable
   - Release test: push tag → automated release → verify all artifacts → install and run on Pi
   - Failure recovery: test rollback procedures, retry logic, error notifications

5. Migration guide (if applicable):
   - Steps to migrate from current manual processes to automated workflows
   - Checklist for maintainers before first production release
   - Known issues and workarounds

**Acceptance Criteria**:
- [ ] All workflows documented with usage examples
- [ ] Troubleshooting guide covers top 10 common issues
- [ ] All 6 user scenarios from spec tested and pass
- [ ] All 19 success criteria validated (pass or documented gap)
- [ ] End-to-end integration test completes successfully
- [ ] Release process tested on real hardware (Raspberry Pi 4)
- [ ] Performance measurements documented (compare to targets)
- [ ] Migration guide available for maintainers

**Dependencies**: All previous phases (1-5)

**Estimated Effort**: 3-4 days

---

## Implementation Order & Dependencies

```
Phase 0: Research ✅ COMPLETE
    │
    v
Phase 1: Code Quality Scanning (2-3 days)
    │
    v
Phase 2: Multi-Arch Build Improvements (3-4 days)
    │
    v
Phase 3: APT Publishing Automation (4-5 days)
    │
    ├─> Phase 4: Pi-gen Integration (3-4 days) [can run parallel with Phase 5]
    │
    └─> Phase 5: Release Automation (4-5 days)
            │
            v
        Phase 6: Documentation & Testing (3-4 days)

Total Sequential: ~24 days
Total with Parallelization (Phase 4 || Phase 5): ~21 days
```

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Pi-gen builds timeout (> 4 hours) | Medium | Low (5%) | Document expected duration, provide manual retry, optimize stages |
| APT repository corruption during publish | High | Low (5%) | Staging → production pattern, rollback capability, backup last-good |
| GitHub Actions quota exhaustion | Medium | Low (10%) | Monitor usage, optimize caching, prioritize amd64 for branches |
| QEMU performance degrades CI times | Low | Medium (20%) | Acceptable per spec (3-5x slower), cache more aggressively |
| Network failures break artifact downloads | Medium | Low (10%) | Retry logic with exponential backoff (implemented) |
| GPG key expiration breaks signing | High | Low (5%) | Key validity checks before publish, 2-year minimum validity, rotation docs |
| Breaking changes in existing workflows | High | Very Low (2%) | Extension strategy (not replacement), backward compatibility |

## Success Metrics (From Spec)

**Phase 1 Target Metrics**:
- SC-001: Quality feedback < 2 minutes ✓
- SC-002: Zero false positives ✓
- SC-003: 90% violation detection ✓

**Phase 2 Target Metrics**:
- SC-004: amd64 builds < 5 minutes ✓
- SC-005: Multi-arch builds < 20 minutes ✓
- SC-007: 95% build success rate ✓

**Phase 3 Target Metrics**:
- SC-009: 100% GPG signing ✓
- SC-010: Atomic APT updates ✓
- SC-019: 100% package validation ✓

**Phase 4 Target Metrics**:
- SC-006: Pi-gen < 4 hours, 95% success ✓

**Phase 5 Target Metrics**:
- SC-011: Release creation < 30 minutes ✓
- SC-012: 90% self-explanatory notes ✓
- SC-017: SBOM inclusion ✓

**Phase 6 Target Metrics**:
- All 19 success criteria validated ✓

## Next Steps

1. **Review this plan** with maintainers for approval
2. **Run `/speckit.tasks`** to generate detailed task breakdown for Phase 1
3. **Create feature branch contracts** in `specs/003-github-actions-cicd/contracts/` (workflow input/output specs)
4. **Begin Phase 1 implementation**: quality-scan.yml workflow and support scripts
5. **Iterate**: Complete each phase sequentially (or Phase 4 || Phase 5), validate against success criteria, adjust as needed
