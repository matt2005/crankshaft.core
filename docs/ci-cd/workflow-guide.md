# CI/CD Workflow Guide

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Developers, Maintainers, Build Engineers

## Overview

This guide provides a comprehensive overview of all GitHub Actions workflows in the Crankshaft CI/CD system. It explains the purpose, triggers, configuration, and usage of each workflow.

---

## Quick Reference Table

| Workflow | File | Trigger | Duration | Purpose | Status |
|----------|------|---------|----------|---------|--------|
| **Quality Feedback** | `quality.yml` | Pull Request | ~5 min | Detect code quality issues early | ✅ Production |
| **Platform Builds** | `build.yml` | Push to main/feature branches | ~25 min | Build binaries for amd64, arm64, armhf | ✅ Production |
| **APT Repository** | `apt.yml` | Successful build on main | ~10 min | Publish packages to APT repo | ✅ Production |
| **Release** | `release.yml` | Version tag or manual dispatch | ~30 min | Create GitHub releases with artifacts | ✅ Production |
| **Pi-Gen Images** | `pi-gen.yml` | Manual dispatch or scheduled | ~90 min | Build Raspberry Pi OS images | ✅ Production |
| **Documentation** | `docs.yml` | Push to main or PR | ~3 min | Build and deploy documentation | ✅ Production |

---

## Workflow Details

### 1. Quality Feedback Workflow (`quality.yml`)

**Purpose**: Provide rapid feedback on code quality issues in pull requests

**Trigger Events**:
- Pull request opened, synchronised, or reopened
- Push to any branch (with filter for documentation-only changes)

**Key Steps**:
1. Check out code
2. Run quality checks (clang-tidy, cppcheck, CodeQL, etc.)
3. Post quality report as PR comment
4. Set status check pass/fail

**Configuration**:
- **Runs on**: Ubuntu latest
- **Concurrency**: 1 per PR (cancels previous runs)
- **Timeout**: 10 minutes
- **Success Criteria**: All checks pass

**Usage**:
```bash
# Automatically triggered on PR creation
git push origin feature/my-feature
# Wait for quality feedback in PR comments
```

**Expected Output**:
- PR comment with violations summary
- Status check showing "Quality Gate" pass/fail
- Links to detailed reports

---

### 2. Platform Builds Workflow (`build.yml`)

**Purpose**: Build binaries for all supported architectures (amd64, arm64, armhf)

**Trigger Events**:
- Push to `main` branch
- Push to `feature/*` or `release/*` branches
- Manual dispatch (workflow_dispatch) with optional architecture filter

**Key Steps**:
1. Determine target architectures based on branch
2. Set up build environment (Docker, dependencies)
3. Run multi-architecture build
4. Upload artifacts to GitHub Actions
5. Generate build report

**Configuration**:
- **Main branch**: Builds all architectures (amd64, arm64, armhf)
- **Feature branches**: Builds amd64 only (fast feedback)
- **Release branches**: Builds all architectures
- **Parallel jobs**: One per architecture
- **Artifact retention**: 30 days
- **Timeout**: 45 minutes

**Usage**:
```bash
# Automatic on push to main
git push origin main

# Automatic on feature branch (amd64 only)
git push origin feature/my-feature

# Manual trigger with all architectures
# Use GitHub Actions UI → "Run workflow" → select all architectures
```

**Expected Output**:
- Build artifacts (deb packages) for each architecture
- Build report with size, time, warnings
- Status check showing "Build" pass/fail

---

### 3. APT Repository Workflow (`apt.yml`)

**Purpose**: Publish built packages to the APT repository for Debian/Ubuntu systems

**Trigger Events**:
- Successful build.yml completion on main branch
- Manual dispatch with package list

**Key Steps**:
1. Download artifacts from build workflow
2. Add packages to APT repository
3. Generate repository metadata
4. Update GPG signatures
5. Deploy to package server
6. Run APT repository tests

**Configuration**:
- **Distribution**: Debian Trixie
- **Sections**: main
- **GPG signing**: Enabled with signing key
- **Artifact retention**: Permanent (in repository)
- **Timeout**: 20 minutes

**Usage**:
```bash
# Automatic after successful build
# Packages available within 5 minutes:
apt-get update
apt-get install crankshaft-ui crankshaft-core

# Manual dispatch for specific packages
# Use GitHub Actions UI → "Run workflow" → enter package paths
```

**Expected Output**:
- Updated APT repository metadata
- Packages indexed by architecture
- Repository signature validation passes

---

### 4. Release Workflow (`release.yml`)

**Purpose**: Create GitHub releases and publish artifacts

**Trigger Events**:
- Push of version tag (v*.*.*)
- Manual dispatch (workflow_dispatch) with optional existing build-run-id

**Key Steps**:

**Mode A: Tag-triggered release**:
1. Trigger build workflow for new artifacts
2. Wait for build completion
3. Download artifacts
4. Create GitHub release
5. Upload artifacts to release
6. Generate release notes
7. Publish release

**Mode B: Manual release from existing build**:
1. Download artifacts from specified build-run-id
2. Validate artifacts exist and are valid
3. Create GitHub release (draft if requested)
4. Upload artifacts
5. Publish release

**Configuration**:
- **Tag pattern**: v[0-9]+.[0-9]+.[0-9]+*
- **Artifact retention**: Permanent (in release)
- **Draft mode**: Supported for manual review
- **Timeout**: 60 minutes

**Usage**:

**Creating release from new tag**:
```bash
# Tag and push triggers release automatically
git tag v1.2.3
git push origin v1.2.3
# Release created automatically with fresh artifacts
```

**Creating release from existing build**:
```bash
# Via GitHub Actions UI:
# 1. Go to Actions → Release
# 2. Click "Run workflow"
# 3. Enter build-run-id (e.g., "12345")
# 4. Select create_draft=true for review
# 5. Workflow uses existing artifacts
```

**Expected Output**:
- GitHub Release with version tag
- Artifacts attached (deb, sha256sums, etc.)
- Release notes with changelog

---

### 5. Pi-Gen Images Workflow (`pi-gen.yml`)

**Purpose**: Build customised Raspberry Pi OS images with Crankshaft pre-installed

**Trigger Events**:
- Manual dispatch (workflow_dispatch)
- Scheduled (optional: weekly build)
- Successful APT publish (on main branch)

**Key Steps**:
1. Clone/update pi-gen repository
2. Configure APT repository (stable or nightly)
3. Set up build environment
4. Build Pi OS images (lite, full)
5. Verify image boots
6. Upload images as artifacts
7. Generate image report (checksum, size)

**Configuration**:
- **APT channel**: Stable (production) or Nightly (testing)
- **Image types**: Lite (minimal), Full (with UI)
- **Architecture support**: armhf, arm64
- **Build environment**: Privileged container
- **Artifact retention**: 30 days
- **Timeout**: 120 minutes

**Usage**:
```bash
# Manual trigger for custom build
# Use GitHub Actions UI → "Run workflow"
# Select: apt_channel (stable/nightly), image_types

# Scheduled weekly build (optional)
# Automatically runs every Monday at 02:00 UTC
```

**Expected Output**:
- Compressed Pi OS images (.xz)
- Checksums (SHA256)
- Boot verification report
- Installation instructions

---

### 6. Documentation Workflow (`docs.yml`)

**Purpose**: Build and deploy project documentation

**Trigger Events**:
- Push to main branch
- Push to branches with documentation changes
- Manual dispatch

**Key Steps**:
1. Check out documentation source
2. Build documentation (Sphinx/Doxygen)
3. Validate links and formatting
4. Deploy to GitHub Pages (on main only)
5. Create build report

**Configuration**:
- **Builder**: Sphinx + Doxygen
- **Deployment**: GitHub Pages
- **Timeout**: 15 minutes
- **Artifact retention**: 7 days (temporary)

**Usage**:
```bash
# Automatic on documentation changes
git push origin main

# Documentation available at:
# https://opencardev.github.io/crankshaft/
```

**Expected Output**:
- Built documentation in HTML
- Published to GitHub Pages
- Link validation report

---

## Workflow Interactions

```
Developer push
     ↓
Quality.yml runs
     ↓ (passes)
Build.yml triggered
     ├─ Builds amd64 (feature branch)
     └─ Builds all archs (main branch)
     ↓ (success)
Apt.yml triggered (if main branch)
     ├─ Publishes to APT repo
     └─ Triggers Pi-gen.yml (on main)
          └─ Builds Pi OS images
                ↓
Tag push (v*.*.*)
     ↓
Release.yml triggered
     ├─ Uses latest build artifacts
     └─ Creates GitHub Release
```

---

## Concurrency & Cancellation

**Quality Feedback**:
- Concurrency key: `pr-{pull_number}`
- Cancellation: Previous runs cancelled by new push

**Platform Builds**:
- Concurrency key: `build-{branch}`
- Cancellation: Previous runs cancelled by new push
- Exception: Manual dispatch runs are not cancelled

**APT Repository**:
- Concurrency key: `apt-publish`
- Cancellation: Only one publish at a time

**Release**:
- No concurrency limits (each release is independent)

---

## Status Checks

All workflows post status checks to pull requests and commits:

| Check | Pass Criteria | Fail Behaviour |
|-------|---------------|----------------|
| **Quality Gate** | All quality checks pass | Blocks merge |
| **Build** | All platforms build successfully | Blocks merge |
| **APT Publish** | Repository valid, tests pass | Manual retry in Actions |
| **Release** | Artifacts verified, release created | Manual retry in Actions |
| **Pi-Gen Build** | Images boot successfully | Notifies maintainers |

---

## Manual Workflow Triggers

### Quality Feedback
**Location**: `Actions → Quality Feedback → Run workflow`

**Inputs**:
- `branch`: Target branch (default: main)

### Platform Builds
**Location**: `Actions → Platform Builds → Run workflow`

**Inputs**:
- `architectures`: Comma-separated list (amd64, arm64, armhf)
- `branch`: Target branch

### APT Repository
**Location**: `Actions → APT Repository → Run workflow`

**Inputs**:
- `apt_channel`: stable or nightly
- `package_paths`: Paths to package files

### Release
**Location**: `Actions → Release → Run workflow`

**Inputs**:
- `build_run_id`: (Optional) Use existing build artifacts
- `create_draft`: (Optional) Create as draft for review

### Pi-Gen Images
**Location**: `Actions → Pi-Gen Images → Run workflow`

**Inputs**:
- `apt_channel`: stable or nightly
- `image_types`: Comma-separated (lite, full)

---

## Environment Variables & Secrets

### Required Secrets

| Secret | Purpose | Setup |
|--------|---------|-------|
| `ACTIONS_ARTIFACT_KEY` | Encryption key for artifacts | Set in repo secrets |
| `APT_REPO_DEPLOY_KEY` | SSH key for APT server | Set in repo secrets |
| `GPG_SIGNING_KEY` | GPG key for package signing | Set in repo secrets |
| `GPG_KEY_PASSPHRASE` | Passphrase for GPG key | Set in repo secrets |
| `GITHUB_TOKEN` | GitHub API access | Auto-provided by Actions |

### Useful Variables

| Variable | Value | Used In |
|----------|-------|---------|
| `REGISTRY` | ghcr.io | All workflows |
| `IMAGE_NAME` | crankshaft-build-env | Build workflow |
| `ARTIFACT_RETENTION` | 30 | Build, Pi-Gen |
| `APT_DISTRO` | trixie | APT, Pi-Gen |

---

## Debugging Workflows

### View Workflow Logs
```bash
# Via GitHub UI
Actions → [Workflow Name] → [Run] → Logs

# Via GitHub CLI
gh run list --repo opencardev/crankshaft
gh run view {run_id} --log
```

### Re-run Failed Jobs
```bash
# Via GitHub CLI
gh run rerun {run_id} --failed
```

### Download Artifacts
```bash
# Via GitHub UI
Actions → [Run] → Artifacts → Download

# Via GitHub CLI
gh run download {run_id} --name {artifact_name}
```

---

## Common Scenarios

### Scenario 1: Fix Code Quality Issue

1. Push code to feature branch
2. Quality workflow runs (automatic)
3. Review violations in PR comment
4. Fix issues locally
5. Push fix (workflow runs again)
6. Quality passes → Ready to merge

**Time to feedback**: ~5 minutes

### Scenario 2: Test Build on All Architectures

1. Feature branch created
2. Push triggers build (amd64 only by default)
3. To test all architectures:
   - Go to `Actions → Platform Builds → Run workflow`
   - Select all architectures
   - Click "Run workflow"
4. Download artifacts and test locally

**Time to all-arch build**: ~25 minutes

### Scenario 3: Publish Update to APT Repository

1. Merge PR to main
2. Build workflow runs → artifacts created
3. APT workflow runs → repository updated
4. Packages available on systems running:
   ```bash
   apt-get update
   apt-get upgrade crankshaft-ui
   ```

**Time to APT availability**: ~15 minutes total

### Scenario 4: Create Release

**Option A: Automatic (tag-based)**
```bash
git tag v1.2.3
git push origin v1.2.3
# Release created automatically
```

**Option B: Manual (from existing build)**
1. Identify stable build-run-id (from Actions)
2. Go to `Actions → Release → Run workflow`
3. Enter build-run-id
4. Create as draft for review
5. When ready, publish release
6. Release becomes official

**Time to release**: ~5-30 minutes (depending on freshness of build)

### Scenario 5: Build Custom Pi OS Images

1. Go to `Actions → Pi-Gen Images → Run workflow`
2. Select:
   - `apt_channel`: stable (for production) or nightly (for testing)
   - `image_types`: lite (minimal) or full (with UI)
3. Wait for build (~90 minutes)
4. Download images
5. Write to SD card and boot on Raspberry Pi 4

**Time to ready-to-boot images**: ~90 minutes

---

## Troubleshooting Quick Guide

| Issue | Solution | Reference |
|-------|----------|-----------|
| Quality checks failing | Review PR comment, fix violations, push again | See `troubleshooting.md` |
| Build timeout | Reduce parallel jobs, check build.yml | See `troubleshooting.md` |
| APT publish fails | Verify repository access, check GPG setup | See `troubleshooting.md` |
| Release missing artifacts | Verify build-run-id valid, check artifact retention | See `troubleshooting.md` |
| Pi-Gen images won't boot | Check APT channel, verify kernel compatibility | See `troubleshooting.md` |

See `troubleshooting.md` for detailed troubleshooting steps.

---

## Next Steps

- **Read about workflows in detail**: See workflow YAML files in `.github/workflows/`
- **Troubleshoot issues**: See `troubleshooting.md`
- **Understand architecture**: See `architecture-decisions.md`
- **Developer tasks**: See `developer-handbook.md`
- **Maintenance tasks**: See `maintainer-handbook.md`

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version with all 6 core workflows |

