# Feature Specification: Comprehensive GitHub Actions CI/CD Pipeline

**Feature Branch**: `003-github-actions-cicd`  
**Created**: 2025-01-28  
**Status**: Draft  
**Input**: User description: "Implement comprehensive GitHub Actions CI/CD pipeline with code quality scanning, multi-architecture builds (Debian Trixie: armhf, arm64, amd64), APT package publishing, Pi-gen image creation, and automated releases"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Code Quality Feedback (Priority: P1)

A developer pushes code to a feature branch and immediately receives automated feedback on code quality, including static analysis, style compliance, and security issues, allowing them to fix problems before code review.

**Why this priority**: Essential for maintaining code quality at scale. Catches issues early when they're cheapest to fix. Enables developers to self-correct without reviewer intervention.

**Independent Test**: Push code with intentional style violations to a feature branch, verify workflow runs within 2 minutes, and quality report is available as workflow output and PR comment.

**Acceptance Scenarios**:

1. **Given** a developer pushes code to a feature branch, **When** the push is detected, **Then** CI workflow starts within 30 seconds and runs lint checks (clang-format, clang-tidy, cppcheck)
2. **Given** code quality checks complete, **When** issues are found, **Then** workflow fails and posts detailed report as PR comment with file locations and suggested fixes
3. **Given** code passes quality checks, **When** workflow completes, **Then** green checkmark appears on PR and developer receives success notification
4. **Given** a commit message contains `[skip ci]` or `[ci skip]`, **When** code is pushed, **Then** quality checks are skipped

---

### User Story 2 - Fast Iteration Feedback (Priority: P1)

A developer working on a feature branch needs quick build feedback to verify their changes compile correctly without waiting for full multi-architecture builds on every push.

**Why this priority**: Critical for developer productivity. Full multi-arch builds take 15-20 minutes; amd64-only builds complete in 3-5 minutes. Enables rapid iteration.

**Independent Test**: Push code change to feature branch, verify amd64-only build completes within 5 minutes, artifacts are available for download.

**Acceptance Scenarios**:

1. **Given** code is pushed to a non-main branch, **When** CI workflow triggers, **Then** only amd64 build executes (not arm64/armhf)
2. **Given** amd64 build completes successfully, **When** developer checks artifacts, **Then** amd64 DEB package is available for download
3. **Given** amd64 build fails, **When** developer checks logs, **Then** clear error message with file and line number is displayed
4. **Given** code is pushed to `main` or `develop` branch, **When** CI workflow triggers, **Then** all three architectures (amd64, arm64, armhf) are built

---

### User Story 3 - Automated Package Publishing (Priority: P1)

When code is merged to main, DEB packages for all architectures are automatically built and published to the APT repository (nightly channel), making them immediately available for testing on real hardware.

**Why this priority**: Core delivery mechanism. Automated publishing ensures consistency, eliminates manual errors, and enables rapid deployment to test systems.

**Independent Test**: Merge PR to main, verify all three architecture DEBs are built, published to nightly APT repository within 30 minutes, and installable via `apt install`.

**Acceptance Scenarios**:

1. **Given** PR is merged to main branch, **When** merge is detected, **Then** CI workflow builds amd64, arm64, and armhf packages in parallel
2. **Given** all three architecture builds succeed, **When** build completes, **Then** workflow automatically triggers APT publish workflow with artifact IDs
3. **Given** APT publish workflow starts, **When** packages are processed, **Then** packages are GPG-signed and published to `nightly` channel within 5 minutes
4. **Given** packages are published, **When** user runs `apt update && apt install crankshaft-core` on Raspberry Pi, **Then** latest nightly version installs successfully
5. **Given** any architecture build fails, **When** workflow completes, **Then** APT publish is NOT triggered and team is notified

---

### User Story 4 - Stable Release Creation (Priority: P2)

A maintainer tags a release (e.g., `v1.2.0`) and the system automatically creates a GitHub release with comprehensive release notes, all architecture DEB packages, checksums, and SBOM, ready for public distribution.

**Why this priority**: Critical for production releases but less frequent than development builds. Automates tedious manual release process, ensures consistency, and improves release quality.

**Independent Test**: Create and push a version tag, verify GitHub release is created within 10 minutes with all artifacts, release notes, and proper formatting.

**Acceptance Scenarios**:

1. **Given** maintainer pushes a tag matching `v*.*.*` pattern, **When** tag is detected, **Then** release workflow triggers automatically
2. **Given** release workflow starts, **When** builds complete, **Then** all three architecture DEBs are included as release assets
3. **Given** release artifacts are collected, **When** release is created, **Then** release notes include:
   - Version number and commit SHA
   - Installation instructions for each architecture
   - Changelog (commits since last tag)
   - SBOM (Software Bill of Materials)
   - SHA256 checksums for all packages
4. **Given** release is created, **When** maintainer views GitHub releases page, **Then** release appears at top with "Latest" badge
5. **Given** stable release is created, **When** APT publish workflow runs, **Then** packages are published to `stable` channel (not nightly)

---

### User Story 5 - Raspberry Pi Image Distribution (Priority: P2)

A maintainer initiates Pi-gen image build and the system creates bootable Raspberry Pi images (armhf and arm64) with Crankshaft pre-installed, ready for flashing to SD cards for quick setup.

**Why this priority**: Simplifies user onboarding. Pre-built images eliminate complex manual setup. High value but lower frequency (released with major versions).

**Independent Test**: Trigger Pi-gen workflow manually, verify armhf and arm64 images are created within 4 hours, images boot on real hardware with Crankshaft running.

**Acceptance Scenarios**:

1. **Given** maintainer triggers `build-pi-gen-lite` workflow manually, **When** workflow starts, **Then** two parallel jobs execute (armhf on master branch, arm64 on arm64 branch)
2. **Given** Pi-gen builds are running, **When** images are created, **Then** Crankshaft packages from specified version are pre-installed
3. **Given** Pi-gen builds complete, **When** artifacts are uploaded, **Then** compressed images (.img.xz) with SHA256 checksums are available
4. **Given** images are created, **When** maintainer enables auto-release option, **Then** images are automatically attached to corresponding GitHub release
5. **Given** user downloads image, **When** image is flashed to SD card and booted on Raspberry Pi 4, **Then** Crankshaft UI starts automatically without additional setup

---

### User Story 6 - Manual Release Control (Priority: P3)

A maintainer needs to create a release from an existing build (e.g., after extended testing) without re-running builds, allowing them to promote tested artifacts to production.

**Why this priority**: Useful for controlled release processes but not essential for day-to-day development. Provides flexibility for testing before public release.

**Independent Test**: Trigger release workflow manually with specific build run ID, verify release is created using those exact artifacts without rebuilding.

**Acceptance Scenarios**:

1. **Given** maintainer has a successful build run ID, **When** they manually trigger release workflow with that ID, **Then** artifacts from that specific build are downloaded
2. **Given** release workflow downloads artifacts, **When** release is created, **Then** no new builds are executed (reuses existing artifacts)
3. **Given** maintainer specifies `create_draft: true`, **When** release is created, **Then** release is marked as draft (not published) for review
4. **Given** draft release exists, **When** maintainer reviews and approves, **Then** they can publish release manually from GitHub UI

---

### Edge Cases

- **Build timeout**: What happens when Pi-gen image build exceeds 4-hour timeout? System should fail gracefully, notify maintainer, and allow manual retry.
- **Partial architecture failure**: If arm64 build succeeds but armhf fails, should APT publish proceed with available packages? No - all architectures must succeed for consistency.
- **Concurrent releases**: What happens if two maintainers push tags simultaneously? GitHub Actions serializes workflows by default; second release waits for first to complete.
- **APT repository corruption**: How does system handle APT publish failure mid-process? Use transactional approach - publish to staging first, then promote atomically.
- **Artifact expiration**: GitHub artifacts expire after 90 days - how to handle release from old build? Workflow should fail with clear message if artifacts are no longer available.
- **Large image files**: Pi-gen images can be 2-4GB compressed - will GitHub release support this? Yes, GitHub supports up to 2GB per file, 10GB per release; compress aggressively.
- **Network failures during publish**: What if APT package upload fails halfway? Implement retry logic with exponential backoff (3 attempts, 1s/2s/4s delays).
- **Invalid version tags**: What happens if tag doesn't follow semver (e.g., `random-tag`)? Release workflow should validate tag format and fail early with clear error.
- **Missing GPG keys**: How does APT publish handle missing or expired GPG signing keys? Workflow should check key validity before starting publish, fail fast if invalid.
- **Cross-repository dependencies**: What if AASDK or OpenAuto dependencies change? Build should pull latest compatible versions from APT repository or specified version tags.

## Requirements *(mandatory)*

### Functional Requirements

**Code Quality Scanning**:

- **FR-001**: System MUST run clang-format check on all C++ source files (*.cpp, *.hpp, *.h) and fail if formatting deviates from `.clang-format` rules
- **FR-002**: System MUST run clang-tidy static analysis on all C++ files with compilation database and report warnings/errors
- **FR-003**: System MUST run cppcheck static analysis on source directories and report issues (style, performance, portability, warning categories)
- **FR-004**: System MUST check all source files for required license headers matching project template
- **FR-005**: System MUST post code quality results as PR comment with file locations, line numbers, and suggested fixes (if violations found)
- **FR-006**: System MUST allow skipping CI checks via `[skip ci]` or `[ci skip]` in commit message for documentation-only changes

**Multi-Architecture Builds**:

- **FR-007**: System MUST build DEB packages for three target architectures: amd64 (x86_64), arm64 (aarch64), armhf (armv7l)
- **FR-008**: System MUST target Debian Trixie (testing) as base distribution with Qt6 dependencies
- **FR-009**: System MUST use cross-compilation or QEMU emulation for arm64/armhf builds on amd64 runners
- **FR-010**: System MUST generate version strings in format `YYYY.MM.DD+git.SHA` (e.g., `2025.01.28+git.a1b2c3d`)
- **FR-011**: System MUST build only amd64 packages for feature branches to optimize CI speed (3-5 minute target)
- **FR-012**: System MUST build all three architectures for `main` and `develop` branches (15-20 minute target acceptable)
- **FR-013**: System MUST upload architecture-specific DEB packages as workflow artifacts with 90-day retention
- **FR-014**: System MUST generate CMake build configuration with Release build type for all architectures
- **FR-015**: System MUST include debug symbols in separate `-dbg` packages for each architecture

**APT Package Publishing**:

- **FR-016**: System MUST publish packages to two channels: `nightly` (from main branch) and `stable` (from version tags)
- **FR-017**: System MUST sign all packages with project GPG key before publishing to APT repository
- **FR-018**: System MUST organize packages by architecture in directory structure: `pool/trixie/{nightly,stable}/c/crankshaft/{amd64,arm64,armhf}/`
- **FR-019**: System MUST generate Packages.gz and Release files for each architecture and channel
- **FR-020**: System MUST validate package integrity (lintian checks) before publishing
- **FR-021**: System MUST update APT repository metadata atomically to prevent partial updates
- **FR-022**: System MUST trigger APT publish workflow only when ALL architecture builds succeed (not on partial failures)
- **FR-023**: System MUST support manual re-publish of existing artifacts via workflow_dispatch with build run ID parameter

**Pi-gen Image Creation**:

- **FR-024**: System MUST build two Raspberry Pi images: armhf (32-bit, master branch) and arm64 (64-bit, arm64 branch)
- **FR-025**: System MUST pre-install Crankshaft packages from specified version or latest nightly in images
- **FR-026**: System MUST configure images with custom stage definitions in `image_builder/pi-gen-stages/`
- **FR-027**: System MUST compress final images with xz compression (target: <800MB compressed for lite image)
- **FR-028**: System MUST generate SHA256 checksums for all image files
- **FR-029**: System MUST support manual workflow trigger with parameters: debian_release (trixie/bookworm), auto_release (true/false), create_draft (true/false)
- **FR-030**: System MUST timeout Pi-gen builds after 240 minutes to prevent hung processes
- **FR-031**: System MUST upload Pi-gen images as workflow artifacts AND optionally attach to GitHub release

**Release Automation**:

- **FR-032**: System MUST automatically trigger release workflow when version tag matching `v*.*.*` pattern is pushed
- **FR-033**: System MUST support manual release creation via workflow_dispatch with parameters: build_run_id, version, create_draft
- **FR-034**: System MUST download build artifacts from specified build run ID (validates artifacts exist before proceeding)
- **FR-035**: System MUST generate comprehensive release notes including:
  - Version number and commit SHA
  - Build date and workflow run ID
  - Installation instructions for each architecture
  - Changelog (git log since previous tag)
  - SBOM reference (Software Bill of Materials)
  - SHA256 checksums for all packages
- **FR-036**: System MUST attach all architecture DEB packages to GitHub release as assets
- **FR-037**: System MUST optionally attach Pi-gen images to release (if available from concurrent build)
- **FR-038**: System MUST create release as draft if `create_draft: true` parameter is set (for manual review before publishing)
- **FR-039**: System MUST publish packages to `stable` APT channel when release is created from version tag (not `nightly`)

**Workflow Orchestration**:

- **FR-040**: System MUST implement reusable workflow pattern for build jobs (workflow_call) to enable reuse across CI/CD/release workflows
- **FR-041**: System MUST chain workflows using workflow_dispatch to trigger downstream steps (e.g., CI → CD → APT publish)
- **FR-042**: System MUST pass artifact metadata between workflows (build run IDs, version strings, architecture lists)
- **FR-043**: System MUST implement conditional logic: amd64-only for branches, full multi-arch for main/develop
- **FR-044**: System MUST run quality checks BEFORE builds to fail fast on code quality issues
- **FR-045**: System MUST support parallel matrix execution for multi-arch builds and Pi-gen images

## Constitution Check (mandatory)

### Impacted Principles

**Code Quality**:
- ✅ Addressed: FR-001 to FR-006 implement comprehensive code quality scanning (clang-format, clang-tidy, cppcheck, license headers)
- Measurable criteria: SC-001 (quality feedback within 2 minutes), SC-002 (zero false positives)

**Testing**:
- ✅ Addressed: Quality scans include static analysis which catches bugs before runtime
- Measurable criteria: SC-003 (catch 90% of style violations automatically)

**Performance**:
- ✅ Addressed: FR-011 implements fast amd64-only builds for feature branches (3-5 min target)
- Measurable criteria: SC-004 (amd64 builds under 5 minutes), SC-005 (full multi-arch under 20 minutes)

**Observability**:
- ✅ Addressed: FR-035 requires comprehensive release notes with build metadata, workflow run IDs, and traceability
- Measurable criteria: SC-008 (workflow status visible in real-time)

**Security**:
- ✅ Addressed: FR-017 (GPG signing), FR-020 (package validation), supply chain considerations
- Measurable criteria: SC-009 (all packages GPG-signed), SC-010 (no unsigned packages published)

**Maintainability**:
- ✅ Addressed: FR-040 (reusable workflows), FR-041 (workflow chaining), modular design
- Measurable criteria: SC-011 (workflows reusable across repositories)

**No Deviations**: This spec does not propose any deviations from constitution principles.

### Key Entities *(data involved)*

- **Build Artifact**: Represents compiled DEB package for a specific architecture
  - Attributes: architecture (amd64/arm64/armhf), version string, file path, SHA256 checksum, build run ID, creation timestamp
  - Relationships: One build run produces three artifacts (one per architecture)

- **Workflow Run**: Represents execution of GitHub Actions workflow
  - Attributes: run ID, workflow name, trigger type (push/tag/manual), status (success/failure), start time, duration, commit SHA
  - Relationships: One workflow run produces multiple artifacts; release workflow references build workflow run ID

- **APT Package**: Represents published package in APT repository
  - Attributes: package name, version, architecture, channel (nightly/stable), GPG signature, publish timestamp, repository path
  - Relationships: Each build artifact becomes one APT package after publishing

- **Pi-gen Image**: Represents bootable Raspberry Pi image
  - Attributes: architecture (armhf/arm64), pi-gen branch, debian release (trixie/bookworm), compressed size, SHA256 checksum, included packages list
  - Relationships: One Pi-gen build produces two images (armhf + arm64); optionally linked to GitHub release

- **GitHub Release**: Represents published release on GitHub
  - Attributes: tag name, version, release notes (markdown), draft status, creation timestamp, author
  - Relationships: Contains multiple build artifacts (DEBs), optionally contains Pi-gen images, references specific workflow run ID

- **Quality Report**: Represents code quality scan results
  - Attributes: tool name (clang-format/clang-tidy/cppcheck), issue count, severity levels, file locations, suggested fixes
  - Relationships: One CI run produces multiple quality reports (one per tool)

## Success Criteria *(mandatory)*

### Measurable Outcomes

**Code Quality**:

- **SC-001**: Developers receive code quality feedback within 2 minutes of pushing code to feature branch
- **SC-002**: Code quality checks have zero false positive rate requiring manual investigation (all reported issues must be actionable)
- **SC-003**: Automated quality scanning catches at least 90% of style violations before human code review

**Build Performance**:

- **SC-004**: amd64-only builds for feature branches complete in under 5 minutes from push to artifact availability
- **SC-005**: Full multi-architecture builds (amd64 + arm64 + armhf) complete in under 20 minutes
- **SC-006**: Pi-gen image builds complete within 4-hour timeout window 95% of the time

**Reliability**:

- **SC-007**: Build success rate for valid code (passes local build) is above 95% (account for transient infrastructure failures)
- **SC-008**: Workflow status is visible in real-time on GitHub PR with clear indication of which stage is running/failed
- **SC-009**: 100% of published packages are GPG-signed (zero unsigned packages in APT repository)
- **SC-010**: APT repository updates are atomic with zero downtime or partial-state visibility to users

**Release Automation**:

- **SC-011**: Release creation from version tag to published GitHub release completes in under 30 minutes
- **SC-012**: Release notes are comprehensive enough that 90% of users do not need to read commit history to understand changes
- **SC-013**: Installation instructions in release notes work on first attempt for 95% of users across all architectures

**Developer Experience**:

- **SC-014**: Developers can trigger CI workflow for specific architecture via manual dispatch (useful for debugging arm64/armhf issues)
- **SC-015**: Failed workflow logs provide clear root cause identification within first 50 lines of output (no deep log spelunking required)
- **SC-016**: Workflow reusability allows other OpenCarDev projects to adopt same patterns with minimal modification (<10 lines changed)

**Security & Compliance**:

- **SC-017**: All release artifacts include SBOM (Software Bill of Materials) for supply chain transparency
- **SC-018**: GPG key rotation process completes without breaking existing installations (backwards compatibility for 30 days)
- **SC-019**: Package validation catches 100% of packages with missing dependencies or broken metadata before publishing

## Assumptions *(documented defaults)*

- **Infrastructure**: GitHub Actions runners provide sufficient resources for cross-compilation and QEMU emulation (32GB RAM, 8 vCPUs available)
- **Dependencies**: All build dependencies (Qt6, AASDK, OpenAuto) are available via APT or buildable from source
- **GPG Keys**: Project GPG signing key is securely stored in GitHub Secrets and valid for at least 2 years
- **APT Repository**: Existing APT repository infrastructure (aptly or custom) is functional and accessible via SSH/SFTP from GitHub Actions
- **Pi-gen**: Pi-gen repository is stable and compatible with Debian Trixie; custom stages follow pi-gen conventions
- **Version Tags**: Maintainers follow semver convention (v1.2.3) and only tag stable release commits
- **Artifact Retention**: 90-day GitHub artifact retention is sufficient for all workflows (release creation within this window)
- **Build Reproducibility**: Builds are reproducible - same commit produces byte-identical packages across multiple builds
- **Network Reliability**: GitHub Actions has reliable network access to APT repositories, Docker Hub, and pi-gen dependencies
- **Concurrent Builds**: No more than 3 concurrent multi-arch builds run simultaneously (GitHub Actions concurrency limits)

## Out of Scope

- **Manual Testing**: Automated functional testing of built packages on real hardware (separate QA process)
- **Performance Benchmarking**: Automated performance regression testing (future enhancement)
- **Security Scanning**: Dependency vulnerability scanning (e.g., Snyk, Dependabot) - separate security initiative
- **Documentation Generation**: Automated Doxygen/Sphinx documentation builds (handled separately)
- **Migration from Existing**: Migration strategy for existing releases/packages in old APT structure (one-time manual effort)
- **Multi-Distribution Support**: Building for distributions other than Debian Trixie (Ubuntu, Fedora, etc.) - future consideration
- **Code Coverage**: Automated code coverage reporting and tracking (separate testing initiative)
- **Notification Integrations**: Slack/Discord/email notifications on build failure (future enhancement)
- **Build Caching**: Advanced caching strategies beyond GitHub Actions default cache (optimization later)
- **Container Registry**: Publishing Docker images to registry (separate containerization effort)

## Dependencies & Constraints

### External Dependencies

- **GitHub Actions**: Platform availability, runner capacity, pricing limits (2000 min/month free for public repos)
- **GitHub Releases**: API rate limits (5000 requests/hour), storage limits (2GB per file, 10GB per release)
- **APT Repository Server**: SSH/SFTP access, disk space (50GB minimum for stable+nightly channels), bandwidth
- **GPG Keyserver**: Availability for key distribution (keys.openpgp.org or keyserver.ubuntu.com)
- **Pi-gen**: Raspberry Pi Foundation's pi-gen project stability, Debian archive availability
- **Docker Hub**: Image pulls for cross-compilation toolchains (rate limits: 100 pulls/6 hours for anonymous)
- **Debian Mirrors**: Availability of Trixie packages for builds (fallback to multiple mirrors if primary fails)

### Technical Constraints

- **Build Time**: Pi-gen images require 3-4 hours to build; cannot be significantly optimized without major engineering effort
- **Artifact Size**: GitHub artifacts limited to 10GB per workflow run (Pi-gen images ~3GB, DEBs ~50MB - within limits)
- **Concurrency**: GitHub Actions free tier allows 20 concurrent jobs; paid tiers up to 180 concurrent jobs
- **Storage**: GitHub packages storage limited to 500MB for free tier (use external APT hosting instead)
- **QEMU Performance**: Emulated arm64/armhf builds are 3-5x slower than native builds (acceptable for CI)
- **Network Bandwidth**: Large artifact uploads/downloads consume significant bandwidth (GitHub has no hard limits but may throttle)

### Security Constraints

- **GPG Key Storage**: Private GPG key must be stored in GitHub Secrets (encrypted at rest, masked in logs)
- **APT Server Access**: SSH keys for APT publish must be stored securely and rotated every 90 days
- **Build Reproducibility**: Cannot guarantee byte-identical builds due to timestamps in DEB packages (acceptable)
- **Supply Chain**: Must verify checksums of downloaded dependencies during build (apt-get uses GPG verification by default)

### Process Constraints

- **Tag Naming**: Version tags must follow semver (v1.2.3) enforced by regex `^v[0-9]+\.[0-9]+\.[0-9]+$`
- **Branch Protection**: Main and develop branches require PR reviews before merge (enforced by GitHub settings)
- **Release Approval**: Stable releases require maintainer approval even with automation (draft release review step)
- **Breaking Changes**: Must maintain backwards compatibility with existing APT installations (package upgrade path)

## Integration Points

### Existing Workflows to Extend

1. **build.yml** (Reusable Build Workflow):
   - Current: Multi-arch builds with matrix strategy, version generation
   - Enhancement: Add quality scanning as pre-build step, improve artifact metadata

2. **ci.yml** (Continuous Integration):
   - Current: Basic lint checks, conditional builds, workflow chaining
   - Enhancement: Add clang-tidy, cppcheck, license header checks, PR comment reporting

3. **release.yml** (Release Creation):
   - Current: Manual release with artifacts and basic notes
   - Enhancement: Auto-trigger on version tags, include Pi-gen images, richer changelog generation

4. **trigger-apt-publish.yml** (APT Publishing):
   - Current: Manual trigger for APT package publishing
   - Enhancement: Auto-trigger from CI on successful builds, implement atomic publish

5. **build-pi-gen-lite.yml** (Pi-gen Images):
   - Current: Manual Pi-gen builds with matrix strategy
   - Enhancement: Integrate with release workflow, auto-attach images to releases

### New Workflows to Create

1. **quality-scan.yml**: Dedicated reusable workflow for code quality checks (used by ci.yml and PR checks)
2. **apt-validate.yml**: Package validation before publishing (lintian, dependency checks)
3. **release-notes.yml**: Reusable workflow for generating comprehensive release notes from git history

### External System Integrations

1. **APT Repository Server**:
   - Protocol: SSH/SFTP for package upload
   - Authentication: SSH key in GitHub Secrets
   - Directory Structure: `/var/www/packages/pool/trixie/{stable,nightly}/c/crankshaft/{amd64,arm64,armhf}/`

2. **GPG Keyserver**:
   - Protocol: HTTPS for key distribution
   - Public Key: Published to keys.openpgp.org
   - Key ID: Referenced in APT source list configuration

3. **GitHub API**:
   - Release Creation: POST /repos/{owner}/{repo}/releases
   - Artifact Download: GitHub Actions artifacts API
   - Workflow Dispatch: POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches

### Workflow Communication Patterns

```
┌─────────────┐
│   Push to   │
│   Feature   │
│   Branch    │
└──────┬──────┘
       │
       v
┌─────────────┐       ┌─────────────┐
│   ci.yml    ├──────>│  quality-   │
│  (trigger)  │       │   scan.yml  │
└──────┬──────┘       └─────────────┘
       │
       v
┌─────────────┐
│  build.yml  │
│ (amd64 only)│
└─────────────┘

┌─────────────┐
│  Push to    │
│    main     │
└──────┬──────┘
       │
       v
┌─────────────┐       ┌─────────────┐
│   ci.yml    ├──────>│  quality-   │
│  (trigger)  │       │   scan.yml  │
└──────┬──────┘       └─────────────┘
       │
       v
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  build.yml  ├──────>│     cd.     ├──────>│   trigger-  │
│(multi-arch) │       │   yml       │       │ apt-publish │
└─────────────┘       └─────────────┘       └─────────────┘

┌─────────────┐
│  Push Tag   │
│   v1.2.3    │
└──────┬──────┘
       │
       v
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│ release.yml ├──────>│ release-    ├──────>│   trigger-  │
│ (auto)      │       │  notes.yml  │       │ apt-publish │
└─────────────┘       └─────────────┘       │  (stable)   │
                                             └─────────────┘
       │
       v (parallel)
┌─────────────┐
│  build-pi-  │
│  gen-lite   │
│   (attach)  │
└─────────────┘
```

## Future Considerations

- **Code Coverage Reporting**: Integrate gcov/lcov for C++ code coverage visualization
- **Performance Benchmarking**: Automated performance regression detection using criterion or custom benchmarks
- **Security Scanning**: Dependency vulnerability scanning (Dependabot, Snyk) and SAST tools (CodeQL)
- **Multi-Distribution Support**: Expand to Ubuntu 24.04 LTS, Fedora 40, Arch Linux ARM
- **Notification Integrations**: Slack/Discord webhooks for build failures and release announcements
- **Build Caching**: Advanced caching of CMake build outputs and dependencies (reduce build time by 40%)
- **Reproducible Builds**: Achieve byte-identical builds using SOURCE_DATE_EPOCH and fixed build environments
- **Container Registry**: Publish Docker images for containerized deployments (separate from Pi images)
- **Test Automation**: Integrate hardware-in-the-loop testing on real Raspberry Pi devices post-build
- **Documentation Generation**: Automated Doxygen docs with GitHub Pages deployment
- **Analytics Dashboard**: Build metrics dashboard showing success rates, build times, artifact sizes over time
- **Cross-Project Reuse**: Extract workflows into shared repository for use across all OpenCarDev projects
