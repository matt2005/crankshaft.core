# Maintainer Handbook

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Project Maintainers, Release Engineers, DevOps Engineers

## Overview

This handbook covers advanced CI/CD operations, maintenance tasks, and troubleshooting for project maintainers. It includes workflows beyond normal development, debugging complex issues, and managing releases.

---

## Core Responsibilities

### Daily

- **Monitor builds**: Check dashboard for failures
- **Review PRs**: Ensure quality standards
- **Respond to issues**: Triage new issues
- **Watch notifications**: GitHub alerts for critical failures

### Weekly

- **Review metrics**: Build times, success rates, failures
- **Update dependencies**: Security patches, minor versions
- **Check disk space**: On self-hosted runners
- **Audit secrets**: Verify all are still needed

### Monthly

- **Performance review**: Identify bottlenecks
- **Capacity planning**: Prepare for growth
- **Documentation review**: Keep guides current
- **Team retrospective**: Discuss improvements

### Quarterly

- **Major version updates**: Dependencies, tools
- **Architecture review**: Evaluate tool choices
- **Security audit**: Secrets, permissions, access control
- **Capacity upgrade**: Runners, storage, compute

---

## Workflow Management

### Enabling / Disabling Workflows

```bash
# List all workflows
gh workflow list --repo opencardev/crankshaft

# Disable workflow (pause temporarily)
gh workflow disable {workflow-id}
# Or via UI: Settings → Actions → General → Disable workflows

# Re-enable workflow
gh workflow enable {workflow-id}

# View workflow details
gh workflow view {workflow-id}
```

### Modifying Workflow Triggers

```yaml
# Example: Change trigger schedule
# File: .github/workflows/pi-gen.yml

on:
  # Add scheduled trigger
  schedule:
    - cron: '0 2 * * 1'  # Monday 2 AM UTC
  
  # Or manual trigger
  workflow_dispatch:
    inputs:
      apt_channel:
        description: 'APT channel'
        required: true
        type: choice
        options:
          - stable
          - nightly
```

### Creating New Workflows

```bash
# Template location
.github/workflows/template.yml

# Steps to create new workflow
1. Copy template
2. Update triggers
3. Define jobs and steps
4. Test with workflow_dispatch
5. Enable once tested
6. Document in workflow-guide.md
```

---

## Release Management

### Creating a Release

#### Automatic Release (Tag-based)

```bash
# 1. Ensure main is stable
git checkout main
git pull origin main

# 2. Verify all tests pass
./scripts/build.sh --build-type Debug
ctest --test-dir build --output-on-failure

# 3. Update version
vim include/crankshaft/version.h
# Update: CRANKSHAFT_VERSION_MAJOR, MINOR, PATCH

vim CMakeLists.txt
# Update: project(crankshaft VERSION x.y.z)

# 4. Update changelog
vim docs/CHANGELOG.md
# Add section: ## [x.y.z] - YYYY-MM-DD

# 5. Commit version bump
git add include/crankshaft/version.h CMakeLists.txt docs/CHANGELOG.md
git commit -m "Chore: Prepare release v1.2.3"

# 6. Push to main
git push origin main

# 7. Wait for build completion (~25 min)
# 8. Create annotated tag
git tag -a v1.2.3 -m "Release v1.2.3

Major Features:
- Feature A
- Feature B

Bug Fixes:
- Fix for issue #123
- Fix for issue #456

Breaking Changes:
- None

Contributors:
- John Doe
- Jane Smith"

# 9. Push tag (triggers release workflow)
git push origin v1.2.3

# 10. Verify release created
gh release view v1.2.3
```

#### Manual Release (From Existing Build)

```bash
# Use for promoting tested builds to release

# 1. Find stable build run
gh run list --repo opencardev/crankshaft \
  --branch main --status success --limit 10 | head -3

# Example output:
# ID          TITLE              STATUS   CONCLUSION   UPDATED
# 12345678    Push main...       ✓        success      2025-01-15 10:30:00

BUILD_RUN_ID="12345678"

# 2. Trigger manual release
gh workflow run release.yml \
  -f build_run_id="$BUILD_RUN_ID" \
  -f create_draft=true

# 3. Verify release created
gh release list --repo opencardev/crankshaft | head -1
# Should show new draft release

# 4. Review release content
# Go to Releases → [Latest]
# Check artifacts are all present

# 5. Publish release
gh release edit v1.2.3 --draft=false

# Or via UI:
# Releases → [Draft] → Edit → Uncheck "Set as pre-release" → Publish
```

#### Release Checklist

```markdown
# Release v1.2.3 Checklist

## Pre-Release
- [ ] Update version numbers in code
- [ ] Update CHANGELOG.md
- [ ] Run full build on main
- [ ] All tests pass
- [ ] Code review complete
- [ ] Documentation updated
- [ ] Pi-Gen images tested

## Release
- [ ] Tag created and pushed
- [ ] Release workflow triggered
- [ ] All artifacts present
- [ ] GPG signature valid
- [ ] APT packages tested on Pi
- [ ] Images boot on Raspberry Pi 4

## Post-Release
- [ ] GitHub release published
- [ ] Announcement posted
- [ ] Documentation links updated
- [ ] Upgrade guide published
- [ ] Community notified
```

---

## Rollback Procedures

### Scenario: Critical Bug in Released Version

```bash
# Example: v1.2.3 has critical crash

# Option 1: Immediate Rollback
# Create maintenance branch from previous release

git checkout v1.2.2
git checkout -b hotfix/v1.2.3-rollback

# Revert problematic commit
git log --oneline | head -5
git revert <commit-hash>

# Push and release
git push origin hotfix/v1.2.3-rollback
# Create release from this branch

# Option 2: Patch Release
# Fix issue on main, release as v1.2.4

git checkout main
# Fix issue
git add .
git commit -m "Fix: Critical crash in v1.2.3"
git push origin main

# Wait for build
# Tag and release v1.2.4
git tag -a v1.2.4 -m "Patch: Fix crash from v1.2.3"
git push origin v1.2.4

# Option 3: Mark as problematic
# If rollback not needed, add warning to release

gh release edit v1.2.3 \
  --notes "⚠️ **KNOWN ISSUES**: Crash in notification system.
  
Affected users should upgrade to v1.2.4 immediately.

See #789 for details."
```

### Deleting a Release

```bash
# Delete from GitHub (release + tag)
gh release delete v1.2.3 --yes
git push origin :refs/tags/v1.2.3

# Verify deletion
gh release list | grep v1.2.3
# Should not appear

# Note: Artifacts remain available via GitHub Actions
# Download from Actions → [Build Run] → Artifacts
```

---

## APT Repository Management

### Publishing Packages

```bash
# Automatic (on main branch push)
# When build completes → apt.yml runs automatically

# Manual publish
gh workflow run apt.yml \
  -f apt_channel=stable

# Wait for completion (~10 min)

# Verify packages published
apt-get update
apt-cache search crankshaft
apt-cache policy crankshaft-ui

# Test installation
sudo apt-get install crankshaft-ui
```

### Repository Structure

```
packages/
├── apt-artifacts/
│   └── debian/
│       ├── dists/
│       │   └── trixie/
│       │       ├── InRelease         (signed metadata)
│       │       ├── Release           (unsigned metadata)
│       │       ├── Release.gpg       (signature)
│       │       ├── stable/           (stable packages)
│       │       └── nightly/          (testing packages)
│       └── pool/
│           └── trixie/
│               ├── c/
│               │   └── crankshaft/   (packages by name)
│               └── liba/
│                   └── ...
```

### Promoting Packages

```bash
# From nightly to stable (manual process)

# 1. Identify tested package
apt-cache policy crankshaft-ui
# Shows: "Candidate: 1.2.3-1~nightly" (from nightly)

# 2. Trigger APT workflow with stable channel
gh workflow run apt.yml \
  -f apt_channel=stable \
  -f package_paths="crankshaft-ui crankshaft-core"

# 3. Verify promotion
apt-get update
apt-cache policy crankshaft-ui
# Should show: "Candidate: 1.2.3-1" (from stable, no nightly suffix)
```

### Removing Packages

```bash
# Mark package as obsolete (rare, security reason)

# 1. Remove from repository metadata
# (Via APT maintainer tools or SSH to server)

# 2. Announce deprecation
gh release edit v1.2.2 \
  --notes "⚠️ **DEPRECATED**: Use v1.2.3 or later.
  
This release had security vulnerabilities and is no longer 
available in the APT repository."

# 3. Users upgrading automatically
apt-get update
apt-get upgrade
# Will upgrade to latest available version
```

---

## Monitoring & Metrics

### Workflow Performance

```bash
# View workflow metrics
# GitHub UI: Settings → Code security & analysis → Security overview

# Via GitHub CLI
gh run list --repo opencardev/crankshaft --limit 30 --json name,conclusion,createdAt,updatedAt | \
  jq -r '.[] | "\(.name): \(.conclusion) (\(.createdAt | split("T")[0]))"'

# Calculate average build time
gh run list --repo opencardev/crankshaft \
  --workflow=build.yml --status success --limit 10 --json durationMinutes | \
  jq '[.[].durationMinutes] | add / length'
```

### Failure Rate Tracking

```bash
# Count failures in last 7 days
gh run list --repo opencardev/crankshaft \
  --created ">$(date -d '7 days ago' '+%Y-%m-%d')" \
  --json name,conclusion | \
  jq 'group_by(.name) | map({workflow: .[0].name, success: map(select(.conclusion=="success")) | length, total: length})'
```

### Artifacts Storage

```bash
# Check artifact storage usage
# GitHub UI: Settings → Billing & plans → Storage

# Or estimate via API
gh api repos/opencardev/crankshaft/actions/artifacts | \
  jq '.artifacts | map(.size_in_bytes) | add / 1024 / 1024 | "Storage used: \(.)MB"'
```

---

## Advanced Debugging

### Workflow Execution Debugging

```bash
# Enable debug logging
gh secret set ACTIONS_STEP_DEBUG --body "true"

# Re-run failed workflow
gh run rerun {run_id} --failed

# Read logs with debug output
gh run view {run_id} --log | grep -A5 "::debug::"

# Disable debug when done (prevents secret exposure)
gh secret delete ACTIONS_STEP_DEBUG
```

### Docker Image Debugging

```bash
# Pull build image to debug locally
docker pull ghcr.io/opencardev/crankshaft-build-env:latest

# Run container interactively
docker run -it --rm \
  -v $(pwd):/workspace \
  ghcr.io/opencardev/crankshaft-build-env:latest \
  bash

# Inside container
cd /workspace
./scripts/build.sh --build-type Debug
```

### Job Logs Analysis

```bash
# Download full logs
gh run view {run_id} --log > run.log

# Analyze for patterns
grep ERROR run.log | sort | uniq -c | sort -rn
grep WARNING run.log | sort | uniq -c | sort -rn

# Find slowest steps
grep "::group" run.log | tee steps.txt
grep "::endgroup" run.log >> steps.txt

# Identify bottlenecks
cat run.log | grep "Elapsed"
```

---

## Secrets Management

### Rotating Secrets

```bash
# List all secrets
gh secret list --repo opencardev/crankshaft

# View secret metadata (not value)
gh secret list --repo opencardev/crankshaft | grep GPG

# Update secret with new value
gh secret set GPG_SIGNING_KEY < <(gpg --export-secret-keys [KEY-ID])

# Verify update
# Create test workflow to confirm secret works

# Remove old secret
# (can't delete individual secret, only update)
```

### Secret Best Practices

```bash
# 1. Store secrets in GitHub, not in code
#    ✓ gh secret set NAME < value.txt
#    ✗ git add config-with-secrets.yml

# 2. Mask secrets in logs
# Automatically masked by GitHub:
# - GitHub token
# - Repository secrets
# - Organization secrets

# 3. Rotate sensitive secrets quarterly
#    - SSH keys for deployments
#    - GPG keys (extend expiration)
#    - API tokens

# 4. Audit secret access
#    GitHub UI: Settings → Secrets and variables → Actions
#    Shows: Last used, Created date

# 5. Use branch-specific secrets for sensitive operations
#    (e.g., production deployment only on main)
```

### Adding New Secrets

```bash
# 1. Generate secret (example: SSH key)
ssh-keygen -t ed25519 -f deploy_key -N ""

# 2. Add to GitHub
gh secret set DEPLOY_SSH_KEY < deploy_key

# 3. Update workflow to use secret
env:
  DEPLOY_KEY: ${{ secrets.DEPLOY_SSH_KEY }}

# 4. Clean up local copy
rm -f deploy_key deploy_key.pub

# 5. Document secret in operations guide
# (Where applicable, without exposing value)
```

---

## Incident Response

### Workflow Failure Alert

```bash
# When workflow fails:

# 1. Assess severity
#    Critical: Build broken, main branch affected
#    Major: Release blocked, specific platforms affected
#    Minor: Feature branch only, optional workflow

# 2. Check if it's infrastructure
gh run list --status failure --limit 5 | \
  jq -r '.[] | "\(.name): \(.status)"'

# 3. Check recent commits
git log --oneline -10

# 4. If commit caused failure
#    Option A: Revert commit
git revert HEAD
git push origin main

#    Option B: Fix in new commit
# Fix issue locally
git add .
git commit -m "Fix: Address build failure"
git push origin main

# 5. Monitor next build
gh run watch  # Wait for completion
```

### Out of Disk Space on Runner

```bash
# If running self-hosted runners:

# 1. SSH to runner machine
ssh runner-host

# 2. Check disk usage
df -h
du -sh /var/lib/docker/*
du -sh /home/runner/*

# 3. Clean up Docker
docker system prune -f --all
docker volume prune -f

# 4. Clean up artifacts
find /home/runner -type f -atime +7 -delete

# 5. If still insufficient
#    Add storage to runner
#    Or provision new runner
```

### Slow Builds

```bash
# If builds are >35 minutes (timeout at 45):

# 1. Identify slowest step
gh run view {run_id} --json steps | \
  jq '.[] | {name, conclusion, durationSeconds}' | \
  sort -k3 -rn

# 2. Check for:
#    - Large files being compiled
#    - Inefficient dependencies
#    - Docker image size
#    - Parallel job count

# 3. Profile locally
time ./scripts/build.sh --build-type Debug

# 4. If source code issue
#    - File bug for optimization
#    - Commit fix

# 5. If infrastructure issue
#    - Upgrade runner specs
#    - Increase cache size
#    - Reduce parallel jobs
```

---

## Capacity Management

### Monitoring Resources

```bash
# GitHub Actions dashboard
# https://github.com/organizations/opencardev/settings/actions

# Check:
- Workflow usage (minutes/month)
- Storage usage (GB/month)
- Artifact retention settings

# Self-hosted runners
# Monitor CPU, memory, disk on each runner

# Set alerts
# If usage approaches limits, notify team
```

### Optimizing Costs

```bash
# 1. Reduce artifact retention
#    Default: 30 days → reduce to 7 days for non-releases

# 2. Parallelize feature branches
#    Build only target platform (amd64) on feature branches
#    All platforms only on main

# 3. Cache dependencies
#    Docker layer caching
#    Dependency caching (if applicable)

# 4. Optimize Docker images
#    Multi-stage builds
#    Remove unnecessary layers

# 5. Review workflow runs
#    Cancel long-running builds
#    Consolidate workflows where possible
```

---

## Updates & Maintenance

### Updating Workflows

```bash
# Workflows live in .github/workflows/

# 1. Test in feature branch
git checkout -b workflow-update/improve-build

# 2. Make changes to workflow file
vim .github/workflows/build.yml

# 3. Create PR and test
# Workflow immediately uses new version

# 4. Once verified, merge to main

# 5. All subsequent builds use new workflow
```

### Updating Tools

```bash
# Update GitHub Actions versions
# Check for newer versions: https://github.com/actions/

# Example: Update checkout action
# Before
- uses: actions/checkout@v3

# After
- uses: actions/checkout@v4

# Test thoroughly before merging
# Some major versions have breaking changes
```

### Deprecation Notices

```bash
# When deprecating a tool/workflow

# 1. Add notice to release notes
gh release edit v1.2.3 --notes "**DEPRECATION**: 
The old-cli tool is deprecated as of v1.2.3.
Use new-cli instead.

old-cli will be removed in v2.0.0."

# 2. Add notice to documentation
# docs/deprecation-notices.md

# 3. Update CI to warn on old tool usage

# 4. After grace period, remove completely
```

---

## Documentation Maintenance

### Keeping Docs Current

```bash
# Review documentation quarterly
ls -la docs/ci-cd/

# Update modified dates in headers
vim docs/ci-cd/*.md
# Update "Last Updated: YYYY-MM-DD"

# Check for broken links
# Use link checker tool

# Verify all examples still work
# Run through example commands
```

### Adding New Documentation

```bash
# Template for new doc
cat > docs/ci-cd/new-topic.md << 'EOF'
# Topic Name

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Target audience

## Overview

## Content

## Next Steps

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version |
EOF

# Add to documentation index
# Update docs/ci-cd/README.md with link to new doc
```

---

## Team Communication

### Status Reports

```bash
# Weekly build summary

# Build metrics
TOTAL=$(gh run list --repo opencardev/crankshaft \
  --created ">$(date -d '7 days ago' '+%Y-%m-%d')" | wc -l)

SUCCESS=$(gh run list --repo opencardev/crankshaft \
  --created ">$(date -d '7 days ago' '+%Y-%m-%d')" \
  --status success | wc -l)

echo "Weekly Report
Build success rate: $SUCCESS / $TOTAL"

# Distribution by workflow
gh run list --repo opencardev/crankshaft \
  --created ">$(date -d '7 days ago' '+%Y-%m-%d')" \
  --json name | jq -r '.[] | .name' | sort | uniq -c
```

### Escalation Path

```
Developer → Failing test
         ↓
Review PR → Can't merge due to failures
         ↓
Maintainer → Assess issue, help debug
          ↓
Severe issue → Create incident issue
           ↓
Critical incident → Email team, page on-call
```

---

## Checklists

### Pre-Release Checklist

```markdown
# Release v1.2.3 Pre-Release

## Code Quality
- [ ] All PR checks passing
- [ ] Tests >95% passing rate
- [ ] No critical bugs reported
- [ ] Security audit complete

## Builds
- [ ] Main branch builds successfully
- [ ] All platforms build (amd64, arm64, armhf)
- [ ] Build time reasonable (<45 min)
- [ ] Artifacts generated correctly

## Documentation
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Migration guide if breaking changes
- [ ] API documentation current

## APT Repository
- [ ] Packages built successfully
- [ ] Package dependencies correct
- [ ] Installation tested on Raspberry Pi

## Pi-Gen Images
- [ ] Images build successfully
- [ ] Images boot on Raspberry Pi 4
- [ ] Default configuration works

## Go / No Go Decision
- [ ] All checks passed? → GO
- [ ] Issues found? → Fix or HOLD
```

### Monthly Maintenance Checklist

```markdown
# Monthly Maintenance

## Monitoring
- [ ] Review build success rates
- [ ] Check artifact storage usage
- [ ] Monitor runner health
- [ ] Review failure patterns

## Security
- [ ] Audit secret usage
- [ ] Check for exposed credentials
- [ ] Review access permissions
- [ ] Update security patches

## Updates
- [ ] Check for dependency updates
- [ ] Update GitHub Actions versions
- [ ] Review deprecation notices
- [ ] Plan major version upgrades

## Documentation
- [ ] Update "Last Updated" dates
- [ ] Review for accuracy
- [ ] Fix broken links
- [ ] Add examples where needed

## Team
- [ ] 1:1 with team members
- [ ] Discuss blockers and improvements
- [ ] Review workload distribution
- [ ] Plan next month priorities
```

---

## Useful Commands Reference

```bash
# Most useful commands

# List recent runs
gh run list --limit 10

# View specific run
gh run view {run-id} --log

# Download artifacts
gh run download {run-id} --name {artifact-name}

# Rerun failed
gh run rerun {run-id} --failed

# Cancel workflow
gh run cancel {run-id}

# View workflow status
gh workflow list

# Manually trigger workflow
gh workflow run {workflow-name} -f key=value

# Manage secrets
gh secret list
gh secret set NAME < value.txt
gh secret delete NAME

# Manage releases
gh release create {tag}
gh release list
gh release view {tag}
gh release edit {tag} --notes "Updated notes"

# Manage issues
gh issue list
gh issue create --title "..." --body "..."
```

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version |

