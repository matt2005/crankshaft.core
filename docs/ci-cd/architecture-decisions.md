# Architecture Decisions

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Architects, Technical Leads, Senior Engineers

## Overview

This document records major architectural decisions made in the Crankshaft CI/CD system. Each decision includes context, considered options, rationale, consequences, and status.

---

## Decision Template

```markdown
## ADR-XXX: [Title]

**Status**: Proposed | Accepted | Deprecated | Superseded

**Context**
What situation prompted the need for this decision?

**Options Considered**
1. Option A: ...
2. Option B: ...
3. Option C: ...

**Rationale**
Why did we choose this option?

**Consequences**
- Positive: ...
- Negative: ...
- Unknown: ...

**Alternatives**
How could we change direction if needed?

**Implementation**
What was/will be implemented?

**Date**: YYYY-MM-DD  
**Author**: Name
```

---

## ADR-001: GitHub Actions as Workflow Orchestrator

**Status**: Accepted

**Context**
Crankshaft needed a CI/CD solution that could:
- Run on multiple platforms (Linux, including Raspberry Pi)
- Support multi-architecture builds (amd64, arm64, armhf)
- Integrate tightly with GitHub repository
- Provide good free tier for open source
- Have large community and ecosystem

**Options Considered**
1. GitHub Actions (native to GitHub)
2. GitLab CI (excellent feature set)
3. Jenkins (self-hosted, powerful)
4. CircleCI (cloud-based, multi-platform)
5. Travis CI (popular, but slowing development)

**Rationale**
- **GitHub Actions**: Integrated with repository, free for open source, no external account needed, YAML configuration in repo, excellent documentation
- **GitLab CI**: More powerful, but requires migration away from GitHub
- **Jenkins**: Powerful, but requires self-hosted infrastructure
- **CircleCI**: Good, but less integrated with GitHub
- **Travis CI**: Limited platform support, decreasing community activity

GitHub Actions chosen for:
- Zero setup (already available in repo)
- Cost (free for open source)
- Integration (runs from GitHub, no external logins)
- Community (massive ecosystem of actions)

**Consequences**
- Positive:
  - No operational overhead
  - Deep GitHub integration
  - Excellent YAML editor with validation in VS Code
  - Free for public projects
  - Large community of reusable actions
  
- Negative:
  - Workflow runtime limit (35 hours per job)
  - Storage limitations (5 GB per repo, 30 day retention)
  - Concurrency limits on free tier
  - Vendor lock-in (GitHub-specific YAML)

- Unknown:
  - Long-term pricing changes
  - Feature deprecations

**Alternatives**
If GitHub Actions becomes insufficient:
- Migrate to self-hosted Jenkins
- Evaluate newer platforms (Temporal, Dagger)
- Use hybrid approach (Actions + external build service)

**Implementation**
- Created 6 core workflows in `.github/workflows/`
- Integrated with GitHub Issues and Pull Requests
- Used GitHub Releases for artifact storage

**Date**: 2024-10-01  
**Author**: OpenCarDev Team

---

## ADR-002: Workflow per User Story vs. Monolithic Pipeline

**Status**: Accepted

**Context**
System needed to balance:
- Clarity of what each workflow does
- Ability to trigger workflows independently
- Avoiding code duplication
- Maintaining consistency

**Options Considered**
1. **Per-User Story**: Separate workflow for each feature (Quality, Build, APT, Release, etc.)
2. **Monolithic**: Single workflow with all steps
3. **Hierarchical**: Parent workflow triggering child workflows

**Rationale**
Chose **Per-User Story** because:
- **Clarity**: Each workflow has single responsibility (quality feedback, build artifacts, etc.)
- **Independence**: Can disable/update one workflow without affecting others
- **Testability**: Can test individual workflow in isolation
- **Documentation**: Self-documenting (workflow name tells you what it does)
- **Reusability**: workflows can be called from multiple triggers

Monolithic pipeline would have created:
- 6000+ line YAML file (unmaintainable)
- Single point of failure
- Difficult to test changes
- Hard to understand flow

**Consequences**
- Positive:
  - Clean separation of concerns
  - Easy to understand
  - Simple to add new workflows
  - Can reorder without full refactor
  
- Negative:
  - More context switching between files
  - Requires passing artifacts between workflows
  - More boilerplate for common patterns
  - Harder to enforce consistency

**Alternatives**
Could still adopt monolithic approach if workflows become too numerous (>10), but not recommended for team clarity.

**Implementation**
- 6 workflows created: Quality, Build, APT, Release, Pi-Gen, Docs
- Each workflow focuses on specific "User Story"
- Workflows triggered by previous workflow success or specific events

**Date**: 2024-10-15  
**Author**: OpenCarDev Team

---

## ADR-003: Quality Checks in PR vs. Blocking Release

**Status**: Accepted

**Context**
Quality checking needed to:
- Provide immediate feedback to developers
- Prevent bad code merging
- Not introduce false positives that block legitimate changes
- Balance strictness with pragmatism

**Options Considered**
1. **Strict**: All violations block merge (no exceptions)
2. **Strict with Override**: Violations block by default, maintainer can force merge
3. **Warnings**: Violations shown but don't block merge
4. **Risk-Based**: Critical violations block, others are warnings

**Rationale**
Chose **Strict with Override**:
- Developers get immediate feedback in PR
- Maintains code quality bar
- Flexibility for edge cases (e.g., experimental branches)
- Prevents accumulation of technical debt

Implementation details:
- clang-tidy: Modernisation, Performance, Readability violations **block**
- cppcheck: Memory safety violations **block**
- CodeQL: Security violations **block**
- Custom rules: Formatting **block**
- Maintainer override available if needed

**Consequences**
- Positive:
  - Forces quality improvement upfront
  - Prevents quality regressions
  - Easier to review code
  
- Negative:
  - Might be frustrating for developers
  - False positives can be annoying
  - Adds review cycle time

**Alternatives**
- Switch to warnings-only if too many false positives
- Add per-rule exceptions in YAML
- Create experimental branch with relaxed rules

**Implementation**
- Status checks must pass before merge
- Quality report posted as PR comment
- Developers must fix violations or request override
- Maintainers can dismiss check if necessary

**Date**: 2024-10-20  
**Author**: OpenCarDev Team

---

## ADR-004: Platform-Specific Builds in Feature vs. All-Platform on Main

**Status**: Accepted

**Context**
Build strategy needed to balance:
- Fast feedback for developers (minimize build time)
- Confidence in multi-platform support (must build on all platforms before merge)
- Cost (GitHub Actions minutes are limited)
- Coverage (detect platform-specific issues early)

**Options Considered**
1. **All platforms on every branch**: Comprehensive but expensive
2. **amd64-only on features, all on main**: Fast feedback, validated before merge
3. **Developer chooses**: Flexibility but inconsistent
4. **Scheduled nightly all-platform builds**: Delayed feedback

**Rationale**
Chose **amd64-only on features, all-platform on main**:
- Fast feedback (amd64 build: 10-15 min vs 25 min for all)
- All-platform validation before merge (comprehensive testing)
- Efficient cost ($$ for GitHub Actions)
- Developer experience (quick local iteration)

**Consequences**
- Positive:
  - Developers see results in 10-15 min instead of 25
  - All-platform validation still happens (on main)
  - Cost-effective
  - Detects platform-specific issues before release
  
- Negative:
  - Platform-specific bugs might reach main (caught in full build)
  - Developers can't run full builds locally easily
  - Some surprises during all-platform build

**Alternatives**
- Revert to all-platform on all branches if needed
- Add self-hosted ARM runners for faster feedback
- Implement parallel builds to reduce time

**Implementation**
- Feature branches (`feature/*`, `fix/*`): amd64 only
- Main branch (`main`): amd64, arm64, armhf
- Release branches (`release/*`): amd64, arm64, armhf
- Manual dispatch: User selects architectures

**Date**: 2024-10-25  
**Author**: OpenCarDev Team

---

## ADR-005: Atomic Repository Publishing via Symlink Swap

**Status**: Accepted

**Context**
APT repository publishing needed to be:
- Atomic (no partial updates visible)
- Safe (no corruption if interrupted)
- Rollback-able (revert to previous state)
- Efficient (don't re-publish everything)

**Options Considered**
1. **In-place updates**: Edit metadata directly (risk of corruption)
2. **Temporary directory swap**: Build new repo, atomically swap
3. **Versioned directories**: Keep multiple versions, switch symlink
4. **Git-based**: Push to separate branch, use webhook

**Rationale**
Chose **Symlink swap**:
- Atomic: Single `ln -s` operation completes or fails entirely
- Safe: Always readable from previous symlink if new one fails
- Rollback: Just swap symlink back to previous version
- Efficient: Build parallel, swap when ready
- Standard: Used by many deployment systems

Implementation:
```
/apt-repo/
  ├── stable/ → symlink to /var/apt-releases/v123-2025-01-01
  └── nightly/ → symlink to /var/apt-releases/v124-2025-01-02

/var/apt-releases/
  ├── v123-2025-01-01/
  │   ├── dists/
  │   └── pool/
  └── v124-2025-01-02/
      ├── dists/
      └── pool/
```

When new packages ready:
1. Build metadata in v125-2025-01-03
2. Verify with tests
3. Atomically swap: `ln -sf v125... /apt-repo/stable`

**Consequences**
- Positive:
  - Atomic (no partial updates)
  - Safe (never intermediate state)
  - Rollback-able (swap back)
  - Auditable (all versions kept)
  
- Negative:
  - Uses more disk (keeps multiple versions)
  - Complex symbolic link management
  - Not all environments support symlinks

**Alternatives**
- Use versioned URLs instead of symlinks
- Use Git branches for repository state
- Use S3/cloud storage with versions

**Implementation**
- APT workflow creates timestamped directory
- Workflow verifies repository integrity
- Atomically swaps symlink
- Keeps last 5 versions for rollback

**Date**: 2024-11-01  
**Author**: OpenCarDev Team

---

## ADR-006: GPG Signing for Package Authenticity

**Status**: Accepted

**Context**
APT repository needed to:
- Guarantee package authenticity
- Prevent man-in-the-middle attacks
- Enable users to verify package source
- Follow Debian packaging standards

**Options Considered**
1. **No signing**: Simplest, but no authenticity guarantees
2. **GPG signing**: Standard Debian approach
3. **TLS certificates only**: Not standard for APT
4. **Multiple signatures**: Added security, complexity

**Rationale**
Chose **GPG signing** because:
- **Standard**: Required for Debian/Ubuntu packages
- **Widely supported**: `apt-key` and `apt-secure` built-in
- **User expectation**: Users expect signed packages
- **Prevents tampering**: Detects modified packages
- **Industry standard**: Used by all major distributions

**Consequences**
- Positive:
  - Follows Debian standards
  - Users can verify authenticity
  - Protects against tampering
  - Required for major distributions
  
- Negative:
  - Must manage GPG keys securely
  - Key expiration management needed
  - One-time setup complexity
  - Requires secret management

**Alternatives**
- Skip signing for now (not recommended)
- Use other signing schemes (not standard)
- Sign binaries separately from APT metadata

**Implementation**
- Generated project GPG key
- Stored in GitHub Secrets (GPG_SIGNING_KEY, GPG_KEY_PASSPHRASE)
- APT workflow signs Release file
- Release.gpg created automatically
- Users import key and trust automatically

**Date**: 2024-11-05  
**Author**: OpenCarDev Team

---

## ADR-007: Workflow Concurrency to Prevent Race Conditions

**Status**: Accepted

**Context**
Parallel workflows needed to:
- Prevent multiple APT publishes overwriting each other
- Prevent multiple releases updating same branch
- Allow other workflows to run independently
- Provide clear queuing semantics

**Options Considered**
1. **No concurrency control**: Simple, but race conditions
2. **Global lock**: Serialize all workflows (slow)
3. **Per-workflow locks**: Serialize by workflow type
4. **Resource-based locks**: Serialize by resource (branch, repo section)

**Rationale**
Chose **Per-resource locks**:
- APT publish concurrency key: `apt-publish` (only one at a time)
- Release concurrency key: `release-{tag}` (per-version)
- Build concurrency key: `build-{branch}` (per branch)
- Cancel previous: `true` (don't queue indefinitely)

This prevents race conditions while allowing parallelism where safe.

**Consequences**
- Positive:
  - No race conditions
  - Prevents resource conflicts
  - Clear queuing semantics
  - Developers see status immediately
  
- Negative:
  - May queue workflows longer
  - Adds latency to sequential operations
  - Requires careful concurrency key design

**Alternatives**
- Use GitHub environment protection rules
- Implement distributed locking system
- Use database-level locking

**Implementation**
```yaml
concurrency:
  group: apt-publish
  cancel-in-progress: true
```

**Date**: 2024-11-10  
**Author**: OpenCarDev Team

---

## ADR-008: Manual Release Mode for Promotion

**Status**: Accepted

**Context**
Release workflow needed to support:
- Creating releases from existing builds (promotion)
- Rebuilding and releasing simultaneously (automation)
- Avoiding rebuild of thoroughly-tested artifacts
- Emergency releases without full rebuild

**Options Considered**
1. **Tag-only**: Only releases from new tags (rebuild always)
2. **Manual mode**: Specify build-run-id to reuse
3. **Hybrid**: Tag rebuilds, manual mode reuses
4. **Database-driven**: Track build status in database

**Rationale**
Chose **Hybrid mode**:
- Default: Tag push rebuilds and releases (auto-release, safest)
- Alternative: Specify build-run-id to reuse existing artifacts (manual promotion)

Use cases:
- Tag push: Automatic release of latest changes
- Manual dispatch: Promote thoroughly-tested old build to release

**Consequences**
- Positive:
  - Flexibility (rebuild or reuse)
  - Automation default (tag-based)
  - Manual promotion available (for emergencies)
  - No build duplication
  
- Negative:
  - More complex logic
  - Artifacts must not expire (30 day limit)
  - Risk of releasing old code if not careful

**Alternatives**
- Only tag-based (no manual option)
- Only manual (no automation)
- Database to track builds (overkill)

**Implementation**
- `workflow_dispatch` allows `build_run_id` input
- If provided: download existing artifacts
- If not provided: trigger new build
- Either way: same release creation process

**Date**: 2024-11-15  
**Author**: OpenCarDev Team

---

## ADR-009: Separate Nightly & Stable APT Channels

**Status**: Accepted

**Context**
APT repository needed to support:
- Nightly builds for testing (every main push)
- Stable releases for production (manual)
- User choice of stability level
- Easy testing of pre-release versions

**Options Considered**
1. **Single channel**: One packages, all versions mixed
2. **Pre-release tags**: Mark pre-release vs. stable (e.g., 1.2.3~nightly)
3. **Separate channels**: `stable/` and `nightly/` subdirectories
4. **Docker-style tags**: `latest`, `stable`, `nightly`

**Rationale**
Chose **Separate channels**:
- Clear distinction (different repos, not same)
- User control (explicitly choose nightly)
- Testing convenience (can run nightly version)
- Rollback simplicity (revert channel, not version)

**Consequences**
- Positive:
  - Clear user choice
  - Easy to test new features
  - Simple to rollback (switch channel)
  - Standard approach (many projects use)
  
- Negative:
  - Duplicate packages in repository
  - Users must understand channels
  - More complex repository structure

**Alternatives**
- Single channel with version numbers
- Use distribution release names (experimental, testing, stable)
- Use feature flags

**Implementation**
- APT repo structure:
  ```
  dists/trixie/
    ├── stable/
    └── nightly/
  ```
- Users configure in `/etc/apt/sources.list.d/crankshaft.list`:
  ```
  # Stable
  deb https://apt.opencardev.com debian trixie/stable main
  # Or nightly
  deb https://apt.opencardev.com debian trixie/nightly main
  ```

**Date**: 2024-11-20  
**Author**: OpenCarDev Team

---

## ADR-010: Raspberry Pi Customization via pi-gen

**Status**: Accepted

**Context**
Raspberry Pi images needed to:
- Include Crankshaft pre-installed
- Customize Raspberry Pi OS for automotive
- Be reproducible
- Minimize build time

**Options Considered**
1. **From scratch**: Build OS from source (very slow)
2. **pi-gen modification**: Extend official pi-gen (Raspberry Pi official approach)
3. **Disk image cloning**: Clone and reconfigure (not reproducible)
4. **Cloud image + provisioning**: Use generic image + Ansible/Chef (not automotive-tuned)

**Rationale**
Chose **pi-gen modification**:
- Official approach: Raspberry Pi uses pi-gen for official images
- Reproducible: Same input → same output
- Maintainable: Upstream maintains base OS
- Customizable: Can add automotive-specific packages/config
- Well-documented: Large community, documentation

**Consequences**
- Positive:
  - Reproducible builds
  - Follows Raspberry Pi practices
  - Can add custom stages
  - Full source available
  
- Negative:
  - Slow builds (~60-90 min)
  - Complex build environment (privileged)
  - Dependent on pi-gen upstream
  - Large image sizes

**Alternatives**
- Use Ubuntu Server on Raspberry Pi (different base OS)
- Build completely custom (lots of work)
- Pre-install on existing images (less reproducible)

**Implementation**
- Extended pi-gen with Crankshaft stages
- Stages add:
  - Crankshaft packages from APT
  - Automotive-specific configuration
  - Qt6 and dependencies
  - Performance tuning
- Builds on GitHub Actions with Docker

**Date**: 2024-11-25  
**Author**: OpenCarDev Team

---

## ADR-011: Artifact Storage Strategy

**Status**: Accepted

**Context**
Artifacts needed to:
- Be stored for release creation
- Not accumulate indefinitely (cost)
- Be available for promotion to releases
- Have reasonable retention policy

**Options Considered**
1. **No storage**: Rebuild for every release (expensive)
2. **Short retention**: 7 days (might expire before release)
3. **Medium retention**: 30 days (balanced)
4. **Long retention**: 365 days (storage cost)
5. **Permanent**: Move to releases, delete from Actions (best practice)

**Rationale**
Chose **30 days + permanent in releases**:
- Default retention: 30 days (covers typical release cycle)
- Release retention: Permanent (in GitHub Releases)
- Cost-effective: Balance retention vs. storage
- Safety: Artifacts don't disappear unexpectedly

**Consequences**
- Positive:
  - Artifacts last through typical release cycle
  - Cost-effective
  - Users always have release artifacts
  - Auditable (git tags point to releases)
  
- Negative:
  - Older builds expire (rebuild needed)
  - Some storage cost
  - Artifacts may not exist for promotion

**Alternatives**
- Extend to 60-90 days (higher cost)
- Archive to S3 (external dependency)
- Permanent storage in Actions (expensive)

**Implementation**
- Workflow artifacts: 30 days (default)
- Release artifacts: Permanent (via GitHub Releases)
- Old artifacts: Automatically deleted after 30 days

**Date**: 2024-11-30  
**Author**: OpenCarDev Team

---

## ADR-012: Documentation Format and Tools

**Status**: Accepted

**Context**
Documentation needed to:
- Be version-controlled (with code)
- Be easy to write and maintain
- Support code examples
- Be deployable to web

**Options Considered**
1. **Markdown in repo**: Simple, version-controlled
2. **Wiki**: Separate from code, diverges over time
3. **Sphinx with RST**: More powerful but harder to write
4. **Doxygen for code docs**: Good for API reference only
5. **Confluence/Notion**: External, requires access, not version-controlled

**Rationale**
Chose **Markdown in repo**:
- Version-controlled: Docs with code
- Accessible: Easy to write and review
- Portable: Plain text, not tool-dependent
- Standard: Most developers familiar
- Future-proof: Works with any generator

Structure:
```
docs/
├── ci-cd/
│   ├── workflow-guide.md
│   ├── troubleshooting.md
│   ├── developer-handbook.md
│   ├── maintainer-handbook.md
│   └── architecture-decisions.md
├── architecture/
├── guides/
└── api/
```

**Consequences**
- Positive:
  - Stays with code (better consistency)
  - Easy to update (just edit file)
  - Version history (git log)
  - Can review in PR
  
- Negative:
  - No fancy formatting (compared to Confluence)
  - Must manually deploy (not auto-published)
  - Less discoverability (not searchable web)

**Alternatives**
- Add search with Docusaurus or mkdocs
- Auto-deploy to GitHub Pages
- Use Sphinx for more power

**Implementation**
- Markdown files in `docs/ci-cd/`
- GitHub Actions workflow (docs.yml) builds and deploys
- Links in main README point to docs

**Date**: 2024-12-01  
**Author**: OpenCarDev Team

---

## Future Decisions

Topics for future ADRs:

1. **Code signing for releases**: Sign binaries with certificate
2. **Secrets rotation**: Automated GPG key rotation
3. **Multi-region deployment**: Distribute artifacts globally
4. **Cost optimization**: Reduce GitHub Actions spending
5. **Scaling architecture**: Handle growth to multiple teams
6. **Security hardening**: Advanced SBOM, vulnerability scanning
7. **Rate limiting**: API rate limits and caching
8. **Disaster recovery**: Backup and restore procedures

---

## ADR Revision Process

### Creating New ADR

1. Create ADR-XXX file (number sequentially)
2. Use template above
3. Set status to "Proposed"
4. Submit as PR for discussion
5. Update to "Accepted" when consensus reached
6. Merge to main

### Updating ADR

1. Change status to "Superseded" or "Deprecated"
2. Link to new ADR that replaces it
3. Document migration path
4. Announce to team

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version with 12 core decisions |

