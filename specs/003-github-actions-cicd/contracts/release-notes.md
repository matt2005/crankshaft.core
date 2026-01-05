# Workflow Contract: Release Notes Generation

**Purpose**: Reusable GitHub Actions workflow for generating comprehensive release notes with changelog, SBOM, and checksums.

**Specification Version**: 1.0.0  
**Feature**: 003-github-actions-cicd  
**Task**: T047  
**Status**: Production (Phase 6)

---

## Workflow Identification

- **Workflow Name**: `Release Notes (Reusable)`
- **Workflow File**: `.github/workflows/release-notes.yml`
- **Workflow Type**: Reusable (called via `workflow_call`)
- **Primary Purpose**: Generate comprehensive release documentation before GitHub release creation

---

## Inputs

### `version` (Required)

- **Type**: String
- **Description**: Release version number (e.g., v1.2.0 or 1.2.0)
- **Valid Format**: Semantic versioning (X.Y.Z)
- **Usage**: Used in changelog headers and metadata

### `from-tag` (Optional)

- **Type**: String
- **Default**: Previous git tag (auto-detected)
- **Description**: Starting git tag for changelog generation
- **Usage**: Determines commit range for changelog parsing

### `include-sbom` (Optional)

- **Type**: Boolean
- **Default**: `true`
- **Description**: Include SBOM (Software Bill of Materials) in release notes
- **Usage**: When false, only generates changelog without dependencies document

---

## Outputs

### `release-notes`

- **Type**: String (Markdown)
- **Format**: Complete release notes with sections
- **When Available**: Always available
- **Purpose**: Ready-to-publish release notes for GitHub releases

**Sections Included**:
1. Version header with date
2. Highlights section
3. What's New (Features, Fixes, Improvements, Breaking Changes)
4. Installation instructions
5. Verification procedures
6. Support links

### `changelog`

- **Type**: String (Markdown)
- **Format**: Pure changelog without installation instructions
- **When Available**: Always available
- **Purpose**: Can be used standalone for changelog files

### `sbom-file`

- **Type**: String (SPDX tag-value format)
- **Format**: SPDX 2.3 compliant BOM
- **When Available**: Only if `include-sbom` input is `true`
- **Purpose**: Dependency documentation for compliance and auditing

### `checksums`

- **Type**: String (SHA256 checksums)
- **Format**: `sha256sum` command output format
- **When Available**: When DEB artifacts available
- **Purpose**: Package integrity verification

---

## Generation Process

### 1. Changelog Parsing

**Input**: Git commit log from `from-tag` to HEAD  
**Processing**:
- Extract commit messages
- Categorize by type: feat, fix, perf, refactor, docs, breaking
- Remove duplicates
- Sort alphabetically within categories

**Output**: Structured changelog with counts per category

### 2. SBOM Generation

**Input**: Project dependencies (CMakeLists.txt, external submodules)  
**Processing**:
- Extract primary dependencies (Qt6, AASDK, Protobuf, etc.)
- Document license information
- Define relationships between components
- Generate SPDX 2.3 format

**Output**: Machine-readable and human-readable BOM

### 3. Artifact Processing

**Input**: Build artifacts from previous workflow run  
**Processing**:
- Download all DEB packages
- Generate SHA256 checksums
- Create checksum file

**Output**: Checksums file for verification

### 4. Release Notes Assembly

**Input**: Changelog, SBOM, checksums  
**Processing**:
- Combine into single markdown document
- Add installation instructions
- Add verification procedures
- Format for GitHub release

**Output**: Complete release notes ready for publication

---

## Integration Points

### Upstream Dependencies

- **Git Repository**: Must have semantic version tags (v*.*.*)
- **Build Artifacts**: DEBs from previous build workflow (via run-id)
- **Commit History**: Git log with conventional commits (feat:, fix:, etc.)

### Downstream Dependencies

- **Release Workflow**: Triggered by release.yml after tag validation
- **GitHub Release API**: Release notes used as release body
- **APT Repository**: Changelog may be published to website

---

## Failure Modes and Recovery

### No Previous Tag Found

**When**: First release (no previous tag exists)  
**Response**:
1. Generates changelog for all commits (HEAD~0)
2. Clearly marks as initial release
3. Includes full commit history in notes

**Recovery**: Normal; no action required

### Missing DEB Artifacts

**When**: Build run ID provided but artifacts expired/missing  
**Response**:
1. Generates changelog and SBOM successfully
2. Skips checksum generation
3. Continues with release notes (incomplete but functional)

**Recovery**: Warn user that checksums unavailable; can rerun build if needed

### Invalid Version Format

**When**: Version doesn't match semantic versioning  
**Response**:
1. Workflow exits with error
2. Release.yml should not proceed
3. Developer must provide valid version

**Recovery**: Correct version format and retry

---

## Success Criteria

- Changelog generated with commit categories
- All commits since last tag included
- SBOM generated in SPDX 2.3 format (if enabled)
- Checksums generated for all artifacts
- Release notes formatted as valid markdown
- Completion within 2 minutes

---

## Example Output

### Release Notes Output

```markdown
# Crankshaft Release 1.2.0

**Release Date**: January 03, 2026
**Git Commit**: abc1234

## Highlights

- Comprehensive multi-architecture CI/CD pipeline
- Automated quality checks and packaging
- APT repository publishing with atomic updates

## What's New

### New Features
- Add --architecture flag for cross-compilation
- Implement atomic APT promotion with symlink swap
- Add QEMU caching for arm64/armhf builds

### Bug Fixes
- Fix Docker cache invalidation with CMakeLists.txt hash
- Correct SPDX format in SBOM generation

## Installation

### From APT Repository

[installation instructions...]

## Verification

Verify checksums:
```bash
sha256sum -c SHA256SUMS
```

---

*Total commits since last release: 42*
```

---

## Implementation Notes

### Performance Targets

- Changelog generation: < 30 seconds
- SBOM generation: < 30 seconds
- Checksum generation: < 10 seconds
- Total workflow: < 2 minutes

### Output Formats

- **Changelog**: Markdown (human-readable, version-control friendly)
- **SBOM**: SPDX tag-value (parseable, standards-compliant)
- **Checksums**: SHA256 format (compatible with `sha256sum -c`)

### Git Commit Format

Uses conventional commits for parsing:
- `feat: Description` → Features section
- `fix: Description` → Bug Fixes section
- `perf: Description` → Improvements section
- `refactor: Description` → Improvements section
- `docs: Description` → Improvements section
- `BREAKING CHANGE: Description` → Breaking Changes section

---

## Future Enhancements

- Custom changelog templates
- Multi-language release notes
- Automated release note translation
- Integration with issue tracking for detailed commits
- Dependency update highlights
