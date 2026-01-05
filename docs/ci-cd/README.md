# CI/CD Documentation

**Last Updated**: 2025-01-01

Welcome to the Crankshaft CI/CD documentation. This directory contains comprehensive guides for developers, maintainers, and operators.

---

## Quick Links

### For Developers

- **[Quality Checks Guide](quality-checks.md)** - Code quality scanning, linting, formatting
- **[Workflow Guide](workflow-guide.md)** - Overview of all workflows and when they run
- **[Troubleshooting](troubleshooting.md)** - Common CI/CD issues and solutions
- **[Developer Handbook](developer-handbook.md)** - How developers interact with CI pipeline

### For Maintainers

- **[Release Process](release-process.md)** - Creating stable releases with GitHub Actions
- **[APT Publishing Guide](apt-publishing.md)** - Package publishing to APT repository
- **[Pi-gen Images Guide](pi-gen-images.md)** - Building Raspberry Pi images
- **[Maintainer Handbook](maintainer-handbook.md)** - Advanced workflows and debugging
- **[Architecture Decisions](architecture-decisions.md)** - Why extend existing workflows vs rewrite

### Technical Reference

- **[GitHub Dependency Strategy](../.github/DEPENDENCY_STRATEGY.md)** - Build-time dependency versioning
- **[Build Flags Verification](../.github/BUILD_FLAGS_VERIFICATION.md)** - build.sh flag compatibility

---

## Workflow Overview

```
feature branch push
  ↓
ci.yml (quality-scan + amd64-only build)
  ↓
PR checks complete → merge to main
  ↓
cd.yml (all architectures + APT publish)
  ↓
nightly APT packages ready

version tag push
  ↓
release.yml (auto-trigger)
  ↓
build all architectures → generate release notes → create GitHub release
  ↓
Pi-gen builds (parallel) → attach images to release
  ↓
APT publish to stable channel
  ↓
Release complete
```

---

## Features by Phase

| Phase | Feature | Status | Documentation |
|-------|---------|--------|---|
| 1 | Setup & Dependency Docs | ✅ Complete | This file |
| 2 | Quality Scanning | 🔄 In Progress | quality-checks.md (draft) |
| 3 | Developer Feedback | ⏳ Pending | quality-checks.md |
| 4 | Fast Builds | ⏳ Pending | workflow-guide.md |
| 5 | APT Publishing | ⏳ Pending | apt-publishing.md |
| 6 | Releases | ⏳ Pending | release-process.md |
| 7 | Pi-gen Images | ⏳ Pending | pi-gen-images.md |
| 8 | Manual Control | ⏳ Pending | release-process.md |
| 9 | Polish | ⏳ Pending | All guides complete |

---

## Getting Started

1. **New to the project?** Start with [Workflow Guide](workflow-guide.md)
2. **Making code changes?** Read [Quality Checks Guide](quality-checks.md)
3. **Creating a release?** See [Release Process](release-process.md)
4. **Running into issues?** Check [Troubleshooting](troubleshooting.md)

---

## See Also

- [Project Specification](../../specs/003-github-actions-cicd/spec.md)
- [Implementation Plan](../../specs/003-github-actions-cicd/plan.md)
- [Task Breakdown](../../specs/003-github-actions-cicd/tasks.md)
- [Analysis Report](../../specs/003-github-actions-cicd/ANALYSIS_REPORT.md)

---

**Last Updated**: 2025-01-03  
**Feature**: 003-github-actions-cicd  
**Phase**: 1 (Setup)
