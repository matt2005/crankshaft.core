# Crankshaft Release Process

This document describes the automated release process for Crankshaft, covering version management, release workflows, and distribution through GitHub and APT repositories.

## Overview

The Crankshaft release process is fully automated through GitHub Actions, enabling consistent, reproducible releases from development to production. The process handles:

- Semantic versioning validation
- Automated builds or reuse of existing builds
- Release notes generation with changelog and SBOM
- GitHub release creation with assets
- APT repository publishing for stable versions

## Versioning Scheme

Crankshaft follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., `1.2.0`)
- **Pre-release versions** (e.g., `1.2.0-alpha.1`, `1.2.0-rc.1`)
- **Build metadata** not used in versioning

### Version Format

Valid versions must match the pattern: `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$`

Examples:
- ✅ `1.0.0` (stable release)
- ✅ `1.2.3` (stable release)
- ✅ `1.2.0-alpha` (pre-release)
- ✅ `1.2.0-rc.1` (release candidate)
- ❌ `1.2` (missing patch version)
- ❌ `1.2.0.` (trailing dot)
- ❌ `v1.2.0` (version tags are stored without 'v', added automatically)

## Release Workflows

### Automatic Release (Recommended)

**Trigger**: Push a semantic version tag

```bash
# Create and push a version tag
git tag v1.2.0
git push origin v1.2.0
```

**Process**:
1. ✅ Validate version format
2. ✅ Automatically trigger build workflow
3. ✅ Poll for build completion (45-minute timeout)
4. ✅ Generate release notes and SBOM
5. ✅ Create GitHub release
6. ✅ Publish to stable APT channel (non-prerelease only)

**Duration**: ~5-10 minutes (depending on build time)

### Manual Release with New Build

**Trigger**: GitHub Actions workflow_dispatch

```
Actions tab → Release → Run workflow
  version: v1.2.0
  build-run-id: (leave empty)
  create-draft: false
```

**Process**: Same as automatic release but triggered manually

### Manual Release with Existing Build

**Scenario**: Reuse packages from previous build

```
Actions tab → Release → Run workflow
  version: v1.2.0
  build-run-id: 1234567890
  create-draft: false
```

**Process**:
1. ✅ Validate version format
2. ⏭️ Skip build (use provided run ID)
3. ✅ Generate release notes and SBOM
4. ✅ Create GitHub release
5. ✅ Publish to stable APT channel (non-prerelease only)

**Duration**: ~2-3 minutes

### Draft Release

Create a release for review before publishing:

```
Actions tab → Release → Run workflow
  version: v1.2.0
  build-run-id: (optional)
  create-draft: true
```

Draft releases are marked as such on GitHub and are not automatically published to APT.

## Release Channels

### Nightly Channel

- **Trigger**: Automatic on every merge to `main` and `develop` branches
- **Distribution**: `/apt/nightly/`
- **Retention**: Latest build only
- **Packages**: All architectures (amd64, arm64, armhf)
- **Stability**: Development/testing versions

**Installation**:
```bash
echo "deb [arch=amd64,arm64,armhf] https://apt.opencardev.com/nightly jammy main" | sudo tee /etc/apt/sources.list.d/crankshaft-nightly.sources
sudo apt update
sudo apt install crankshaft
```

### Stable Channel

- **Trigger**: Manual release workflow with non-prerelease version
- **Distribution**: `/apt/stable/`
- **Retention**: All released versions
- **Packages**: All architectures (amd64, arm64, armhf)
- **Stability**: Production-ready versions

**Installation**:
```bash
echo "deb [arch=amd64,arm64,armhf] https://apt.opencardev.com/stable jammy main" | sudo tee /etc/apt/sources.list.d/crankshaft.sources
sudo apt update
sudo apt install crankshaft
```

### Pre-release Channel

Pre-release versions (alpha, beta, rc) are:
- Published to GitHub releases
- NOT published to stable APT channel
- Must be manually installed from GitHub releases

**Manual installation**:
```bash
wget https://github.com/opencardev/crankshaft-mvp/releases/download/v1.2.0-rc.1/crankshaft-amd64_1.2.0-rc.1_amd64.deb
sudo dpkg -i crankshaft-amd64_1.2.0-rc.1_amd64.deb
```

## Release Workflow Jobs

### validate

Validates the release version and determines pre-release status.

**Outputs**:
- `version`: Semantic version (without 'v' prefix)
- `is-prerelease`: true if version contains dash, false otherwise

### build (optional)

Triggered when no `build-run-id` provided. Automatically:
1. Triggers CI workflow
2. Polls for workflow completion
3. Returns the build run ID

**Condition**: `github.event.inputs.build-run-id == '' && github.event_name == 'workflow_dispatch'`

**Timeout**: 45 minutes

**Outputs**:
- `build-run-id`: The workflow run ID of the completed build

### generate-release-notes

Generates comprehensive release documentation:

1. Downloads build artifacts from CI workflow
2. Generates changelog from git history
3. Generates SBOM (Software Bill of Materials) in SPDX format
4. Calculates SHA256 checksums for all packages
5. Assembles comprehensive release notes markdown

**Outputs**:
- `release-notes`: Markdown with installation, changelog, verification, and SBOM info

**Artifacts Uploaded**:
- `RELEASE_NOTES.md` - Complete release documentation
- `CHANGELOG.md` - Changes only
- `SBOM.spdx` - Software Bill of Materials
- `SHA256SUMS` - Package checksums

### create-release

Creates a GitHub release with:
- Tag: `v{version}`
- Name: `Crankshaft {version}`
- Body: Release notes from previous job
- Draft: Conditional based on input
- Pre-release: true if version contains dash
- Assets: All .deb packages and SHA256SUMS

### publish-stable

Publishes packages to stable APT channel for non-prerelease versions.

**Condition**: `needs.validate.outputs.is-prerelease == 'false'`

**Uses**: `apt-publish.yml` reusable workflow

**Inputs**:
- `build-run-id`: Build run ID
- `channel`: stable
- `architectures`: amd64 arm64 armhf

### publish-success

Final job that always runs to report success/failure.

**Outputs**: Summary message with release details and next steps

## Failed Release Recovery

### Scenario: Build Failed

If the automatic build fails:

1. Check the build workflow logs for errors
2. Fix the issue in source code
3. Push fixes to main branch
4. Re-trigger release with same version tag (force push if needed):
   ```bash
   git tag -d v1.2.0
   git push --delete origin v1.2.0
   git tag v1.2.0
   git push origin v1.2.0
   ```

### Scenario: Release Created but Build Artifacts Corrupted

If release was created but packages are invalid:

1. Delete the GitHub release
2. Delete the git tag:
   ```bash
   git tag -d v1.2.0
   git push --delete origin v1.2.0
   ```
3. Verify build artifacts
4. Re-trigger release with new attempt

### Scenario: Partial Publish (APT Publish Failed)

If GitHub release succeeded but APT publishing failed:

1. Check `publish-stable` job logs for specific error
2. Manual APT sync can be triggered via workflow_dispatch
3. Version remains available on GitHub until fixed

## Changelog Generation

Release notes are automatically generated from git history using conventional commits:

### Conventional Commit Format

```
<type>(<scope>): <subject>
```

**Types** (included in changelog):
- `feat:` - Features
- `fix:` - Bug fixes
- `perf:` - Performance improvements
- `refactor:` - Code refactoring
- `docs:` - Documentation (not in changelog)
- `test:` - Tests (not in changelog)
- `chore:` - Build/CI (not in changelog)

**Breaking Changes**:
- Any commit with `BREAKING CHANGE:` in footer is listed separately
- Pre-release versions with major changes recommended

### Example Changelog

```markdown
## 1.2.0 - 2025-01-15

### Features
- feat(ui): Add dark mode support
- feat(api): New event system for extensions
- feat(media): Support for multiple audio outputs

### Bug Fixes
- fix(bluetooth): Reconnection after device loss
- fix(ui): Theme switching persistence

### Improvements
- perf(core): Reduce memory footprint by 30%
- refactor(extension): Simplified manifest loading

### Breaking Changes
- BREAKING CHANGE: Extension manifest format v2 required
- BREAKING CHANGE: Removed deprecated WebSocket API
```

## Software Bill of Materials (SBOM)

Each release includes a comprehensive SBOM in SPDX 2.3 format documenting:

- All dependencies and exact versions
- License information for each component
- Component relationships and dependency tree
- Known vulnerabilities (when available)

**File**: `crankshaft-sbom-{version}.spdx`

**Format**: SPDX tag-value format
- Human-readable text
- Machine-parseable for vulnerability tracking
- Compatible with SBOM tools and security scanners

**Contents**:
```
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: Crankshaft SBOM

PackageName: Qt6Core
SPDXID: SPDXRef-Qt6Core
PackageVersion: 6.x.x
PackageDownloadLocation: https://qt.io
FilesAnalyzed: false
PackageLicenseConcluded: LGPL-2.0-or-later

PackageName: openssl
SPDXID: SPDXRef-openssl
PackageVersion: 3.x.x
PackageDownloadLocation: https://www.openssl.org
FilesAnalyzed: false
PackageLicenseConcluded: Apache-2.0
```

## APT Repository Structure

### Repository Layout

```
/apt/
├── stable/
│   ├── dists/
│   │   └── jammy/
│   │       ├── InRelease (GPG signed)
│   │       ├── Release
│   │       ├── Release.gpg
│   │       └── {main,universe}/
│   │           └── binary-{amd64,arm64,armhf}/
│   │               ├── Packages
│   │               ├── Packages.gz
│   │               └── Release
│   └── pool/
│       └── c/
│           └── crankshaft/
│               └── crankshaft_*.deb
│
├── nightly/
│   └── (same structure as stable)
└── current → ./stable (symlink)
```

### Package Verification

Verify downloaded packages:

```bash
# Download checksums and signature
wget https://apt.opencardev.com/stable/dists/jammy/Release
wget https://apt.opencardev.com/stable/dists/jammy/Release.gpg

# Verify signature
gpg --verify Release.gpg Release

# Verify package checksums
sha256sum -c SHA256SUMS
```

## Hotfix Releases

For critical fixes to released versions:

1. Checkout release tag:
   ```bash
   git checkout v1.2.0
   git checkout -b hotfix/1.2.1
   ```

2. Apply fixes as commits
3. Update version in code (if needed)
4. Create new tag:
   ```bash
   git tag v1.2.1
   git push origin v1.2.1
   ```

5. Release workflow automatically triggers

## Pre-release Workflow

For alpha/beta/rc releases:

1. Create branch from main:
   ```bash
   git checkout -b release/1.2.0-rc.1
   ```

2. Perform final testing and fixes
3. Tag version:
   ```bash
   git tag v1.2.0-rc.1
   git push origin v1.2.0-rc.1
   ```

4. Release workflow:
   - Creates GitHub release marked as pre-release
   - Publishes packages to GitHub releases only
   - Does NOT publish to stable APT (requires explicit decision)
   - Users can opt-in to test via manual installation

5. Gather feedback and repeat for rc.2, rc.3, etc.
6. When ready, release as v1.2.0 stable

## Documentation Updates

After release, update:

1. **README.md**: Update installation instructions, version numbers
2. **CHANGELOG.md**: Add version section with release date
3. **RELEASE.txt**: Update latest version info
4. **Documentation**: Reflect new features, API changes

## Rollback Procedure

If a released version has critical issues:

1. **GitHub Release**: Mark as deprecated in release description
2. **APT Stable**: Previous version remains available (all versions kept)
3. **Users**: Manually downgrade:
   ```bash
   sudo apt install crankshaft=1.1.0
   ```
4. **Release New Fix**: Create hotfix release with version bump

## Monitoring and Alerts

Track release success via:

- GitHub Actions dashboard
- Release workflow job logs
- APT repository metrics
- Package download analytics

## Troubleshooting

### "Build timed out"
- Build took >45 minutes
- Manually trigger release with `build-run-id` from slower build
- Or increase timeout in `release.yml`

### "Invalid version format"
- Check version matches semver pattern
- Remove 'v' prefix if present
- No trailing dots or extra characters

### "APT publish failed"
- Check SSH connectivity to APT server
- Verify GPG signing key configured
- Check APT server disk space
- Manual re-trigger via workflow_dispatch

### "Missing DEB artifacts"
- Verify build run completed successfully
- Check artifact retention (90-day limit)
- Download from GitHub release instead
- Rebuild if artifacts expired

## Security Considerations

- All release artifacts are cryptographically signed
- GitHub releases are signed with commit signing keys
- APT packages are signed with GPG key
- Repository metadata (Release files) are GPG signed
- SBOM enables vulnerability tracking
- All operations logged and auditable

## Additional Resources

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [SPDX Standard](https://spdx.dev/)
- [APT Repository Format](https://wiki.debian.org/DebianRepository/Format)
- [GitHub Release Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
