# CI/CD Success Criteria Validation Checklist

**Template Version**: 1.0  
**Date**: [Fill in date]  
**Milestone**: [e.g., MVP, v1.0, Phase 2]  
**Validation Lead**: [Name]

---

## Overview

This checklist validates that all success criteria (SC-001 through SC-019) defined for the Crankshaft CI/CD system are met. Use this template to:
- Measure actual performance against targets
- Document validation results
- Identify gaps
- Plan improvements

---

## SC-001: Quality Feedback in <2 minutes

**Requirement**: Developers receive code quality feedback on PRs within 2 minutes of push

### Measurement

| Test Case | Expected | Actual | Status | Notes |
|-----------|----------|--------|--------|-------|
| Simple style violation | <2 min | ___ min | ☐ Pass | Push code with clang-format violation |
| Clang-tidy violation | <2 min | ___ min | ☐ Pass | Push code with clang-tidy issue |
| CodeQL violation | <2 min | ___ min | ☐ Pass | Push code with security issue |

**Test Procedure**:
1. Create PR with intentional violation
2. Record time when PR is created
3. Record time when quality comment appears
4. Calculate: comment_time - creation_time

**Pass Criteria**: All three tests <2 minutes

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-002: Build succeeds on all platforms within 45 minutes

**Requirement**: Multi-architecture builds (amd64, arm64, armhf) complete within 45 minutes

### Measurement

| Architecture | Expected | Actual | Status | Notes |
|--------------|----------|--------|--------|-------|
| amd64 | <15 min | ___ min | ☐ Pass | Desktop/typical system |
| arm64 | <20 min | ___ min | ☐ Pass | Raspberry Pi 4 64-bit |
| armhf | <25 min | ___ min | ☐ Pass | Raspberry Pi 4 32-bit |
| **Total all** | <45 min | ___ min | ☐ Pass | When run in parallel |

**Test Procedure**:
1. Push to main branch (triggers all-platform build)
2. Monitor Actions dashboard
3. Record start and end time for each job
4. Note: Parallel execution, so total ≠ sum

**Pass Criteria**: All platforms complete, longest <45 min

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-003: amd64-only build on feature branches in <15 minutes

**Requirement**: Feature branches build amd64 architecture only in <15 minutes for fast feedback

### Measurement

| Scenario | Expected | Actual | Status | Notes |
|----------|----------|--------|--------|-------|
| Feature branch push | <15 min | ___ min | ☐ Pass | Only amd64 builds |
| Build succeeds | Always | _____ | ☐ Pass | No compilation errors |
| Artifacts created | Always | _____ | ☐ Pass | Build artifacts present |

**Test Procedure**:
1. Create feature branch
2. Push to feature/test-branch
3. Monitor Actions → Platform Builds
4. Record completion time

**Pass Criteria**: Build completes in <15 minutes

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-004: APT packages published within 10 minutes of successful build

**Requirement**: After build succeeds, APT packages are available for installation within 10 minutes

### Measurement

| Step | Expected | Actual | Status | Notes |
|------|----------|--------|--------|-------|
| Build completes | - | ___ | ☐ Pass | Record completion time |
| APT workflow triggered | Auto | _____ | ☐ Pass | Automatic on main success |
| Packages indexed | <5 min after build | ___ min | ☐ Pass | APT metadata updated |
| Installation works | Yes | _____ | ☐ Pass | `apt-get install` succeeds |

**Test Procedure**:
1. Merge PR to main (triggers build)
2. Monitor Actions → APT Repository
3. After APT workflow completes, test install:
   ```bash
   sudo apt-get update
   sudo apt-get install crankshaft-ui
   ```
4. Verify installation succeeds

**Pass Criteria**: Packages installable <10 min after build completion

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-005: Releases created with all artifacts in <30 minutes

**Requirement**: From tag push to release with artifacts takes <30 minutes

### Measurement

| Step | Expected | Actual | Status | Notes |
|------|----------|--------|--------|-------|
| Tag created | - | ___ | ☐ Pass | Record creation time |
| Build triggered | Auto | _____ | ☐ Pass | Automatic on tag |
| Release created | <30 min | ___ min | ☐ Pass | Release exists with artifacts |
| Artifacts present | All | _____ | ☐ Pass | deb, sha256sums, etc. |

**Test Procedure**:
1. Create and push version tag: `git tag v1.2.3 && git push origin v1.2.3`
2. Monitor Actions → Release workflow
3. Check Releases page for new release
4. Verify all artifacts present

**Pass Criteria**: Release with artifacts available <30 min after tag push

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-006: Pi-Gen images build successfully within 90 minutes

**Requirement**: Custom Raspberry Pi OS images build and boot within 90 minutes

### Measurement

| Image Type | Expected | Actual | Status | Notes |
|------------|----------|--------|--------|-------|
| Lite image | <60 min | ___ min | ☐ Pass | Minimal install |
| Full image | <90 min | ___ min | ☐ Pass | With UI |
| Boot test | Success | _____ | ☐ Pass | Boots on Raspberry Pi 4 |

**Test Procedure**:
1. Trigger Pi-Gen Images workflow
2. Select apt_channel=stable, image_types=lite
3. Monitor workflow progress
4. Download resulting image
5. Write to SD card and boot on Raspberry Pi 4

**Pass Criteria**: Images build in time, boot successfully

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-007: Zero build errors and warnings meeting quality standards

**Requirement**: All builds complete with zero blocking violations

### Measurement

| Check | Expected | Actual | Status | Notes |
|-------|----------|--------|--------|-------|
| Compilation errors | 0 | ____ | ☐ Pass | Clean build |
| clang-tidy violations | 0 blocking | ____ | ☐ Pass | Quality gate passes |
| cppcheck violations | 0 blocking | ____ | ☐ Pass | Memory safety checks |
| CodeQL violations | 0 blocking | ____ | ☐ Pass | Security checks |

**Test Procedure**:
1. Build locally: `./scripts/build.sh --build-type Debug`
2. Run format check: `./scripts/format_cpp.sh check`
3. Run linters: `./scripts/lint_cpp.sh clang-tidy`
4. Verify no violations

**Pass Criteria**: All builds pass all quality checks

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-008: 95%+ test pass rate across all platforms

**Requirement**: Unit tests pass on all supported platforms at 95%+ rate

### Measurement

| Platform | Total Tests | Passed | Pass % | Status | Notes |
|----------|------------|--------|--------|--------|-------|
| amd64 | ____ | ____ | ___% | ☐ Pass | ≥95% |
| arm64 | ____ | ____ | ___% | ☐ Pass | ≥95% |
| armhf | ____ | ____ | ___% | ☐ Pass | ≥95% |

**Test Procedure**:
1. Build all platforms
2. Run tests: `ctest --test-dir build --output-on-failure`
3. Record pass/fail counts
4. Calculate percentage

**Pass Criteria**: All platforms ≥95% pass rate

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-009: APT packages install and execute without errors

**Requirement**: Installed packages run without errors or missing dependencies

### Measurement

| Test | Expected | Actual | Status | Notes |
|------|----------|--------|--------|-------|
| Installation | Success | _____ | ☐ Pass | Package installs cleanly |
| Dependencies | Resolved | _____ | ☐ Pass | No unmet dependencies |
| Execution | Success | _____ | ☐ Pass | Binary runs without error |
| Config | Valid | _____ | ☐ Pass | Config files parse |

**Test Procedure**:
```bash
# On Raspberry Pi or test system
sudo apt-get update
sudo apt-get install -y crankshaft-ui crankshaft-core

# Verify installation
crankshaft-ui --version
crankshaft-core --version

# Check configuration
test -f /etc/crankshaft/config.yaml
```

**Pass Criteria**: All tests pass, no errors

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-010: Artifacts secured with GPG signatures

**Requirement**: All release artifacts signed with valid GPG key

### Measurement

| Artifact | Signed | Verification | Status | Notes |
|----------|--------|--------------|--------|-------|
| Release files | Yes | Valid | ☐ Pass | Release.gpg present |
| Checksums | Yes | Valid | ☐ Pass | SHA256SUMS signed |
| Packages | Yes | Valid | ☐ Pass | DEB packages signed |

**Test Procedure**:
```bash
# Download release
gh release download v1.2.3

# Verify signature
gpg --verify Release.gpg Release

# Verify checksum
sha256sum -c SHA256SUMS
```

**Pass Criteria**: All signatures valid, checksums match

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-011: Secrets never exposed in logs

**Requirement**: GitHub secrets never appear in workflow logs

### Measurement

| Secret | Exposure | Status | Notes |
|--------|----------|--------|-------|
| GPG_SIGNING_KEY | Not visible | ☐ Pass | Masked in logs |
| GPG_KEY_PASSPHRASE | Not visible | ☐ Pass | Masked in logs |
| GITHUB_TOKEN | Not visible | ☐ Pass | Auto-masked |
| Deploy keys | Not visible | ☐ Pass | Masked in logs |

**Test Procedure**:
1. Examine workflow logs from Actions
2. Search for secret patterns
3. Verify no plaintext secrets shown

**Pass Criteria**: No secrets visible in any logs

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-012: Workflow concurrency prevents race conditions

**Requirement**: No concurrent conflicts, workflows queue properly

### Measurement

| Scenario | Expected | Actual | Status | Notes |
|----------|----------|--------|--------|-------|
| Parallel APT publishes | Queued | _____ | ☐ Pass | Only one at a time |
| Release + PR build | Run independently | _____ | ☐ Pass | No conflicts |
| Multiple tags | Run sequentially | _____ | ☐ Pass | Per-tag concurrency |

**Test Procedure**:
1. Trigger multiple workflows simultaneously
2. Monitor Actions for concurrency behavior
3. Verify proper queueing without errors

**Pass Criteria**: No race conditions, proper queueing

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-013: Documentation complete and accessible

**Requirement**: All documentation exists and is accurate

### Measurement

| Document | Exists | Current | Accessible | Status | Notes |
|----------|--------|---------|------------|--------|-------|
| workflow-guide.md | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |
| troubleshooting.md | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |
| developer-handbook.md | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |
| maintainer-handbook.md | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |
| architecture-decisions.md | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |
| README with links | ☐ Yes | ☐ Yes | ☐ Yes | ☐ Pass | |

**Test Procedure**:
1. Check each document exists in `docs/ci-cd/`
2. Verify links from main README work
3. Check dates (within 3 months)

**Pass Criteria**: All documents exist, linked, current

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-014: Failure recovery and rollback procedures work

**Requirement**: Can recover from failures and rollback to previous state

### Measurement

| Scenario | Recovery Time | Success | Status | Notes |
|----------|---------------|---------|--------|-------|
| Build failure retry | <5 min | ☐ Yes | ☐ Pass | Re-run succeeds |
| Release rollback | <10 min | ☐ Yes | ☐ Pass | Can revert release |
| APT package removal | <15 min | ☐ Yes | ☐ Pass | Can remove from repo |
| Artifact restoration | <20 min | ☐ Yes | ☐ Pass | Can restore from backup |

**Test Procedure**:
1. Trigger controlled failure
2. Execute recovery procedure
3. Verify successful recovery

**Pass Criteria**: All recovery procedures work within target time

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-015: Observability and logging adequate for debugging

**Requirement**: Sufficient logging for troubleshooting issues

### Measurement

| Aspect | Adequate | Status | Notes |
|--------|----------|--------|-------|
| Workflow logs | Yes | ☐ Pass | Can diagnose failures |
| Error messages | Clear | ☐ Pass | Not cryptic |
| Debug info available | Yes | ☐ Pass | Can enable if needed |
| Log retention | 90+ days | ☐ Pass | Not lost quickly |

**Test Procedure**:
1. Trigger failure scenario
2. Review logs for clarity
3. Attempt diagnosis from logs alone

**Pass Criteria**: Can diagnose issues from available logs

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-016: Cost-effective GitHub Actions usage

**Requirement**: Efficient use of GitHub Actions minutes and storage

### Measurement

| Metric | Target | Actual | Status | Notes |
|--------|--------|--------|--------|-------|
| Minutes/month | <2000 | ___ | ☐ Pass | Within budget |
| Storage/month | <10 GB | ___ | ☐ Pass | Artifact cleanup works |
| Artifact retention | 30 days | ____ | ☐ Pass | Auto-cleanup |

**Test Procedure**:
1. Review GitHub billing dashboard
2. Check Actions usage metrics
3. Compare to budget

**Pass Criteria**: Usage within budget targets

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-017: All workflows accessible to right users/teams

**Requirement**: Proper access control, no unauthorized access

### Measurement

| Workflow | Dev Access | Maintainer | Public |
|----------|------------|-----------|--------|
| Quality Feedback | ☐ Yes | ☐ Yes | ☐ Yes |
| Platform Builds | ☐ Yes | ☐ Yes | ☐ Yes |
| APT Publish | ☐ No | ☐ Yes | ☐ No |
| Release | ☐ No | ☐ Yes | ☐ No |
| Pi-Gen | ☐ Limited | ☐ Yes | ☐ No |

**Test Procedure**:
1. Test as developer: Can trigger quality, build
2. Test as maintainer: Can trigger all
3. Test as public: Cannot trigger sensitive workflows

**Pass Criteria**: Access control properly enforced

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-018: Infrastructure scales with team growth

**Requirement**: Can handle increased commit/PR volume

### Measurement

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Concurrent builds | 5+ | ____ | Can run parallel |
| PR feedback time | <2 min | ____ | Still responsive |
| Build queue | <10 min wait | ____ | Not bottlenecked |

**Test Procedure**:
1. Run stress test: Create multiple PRs simultaneously
2. Monitor response times
3. Check queue depths

**Pass Criteria**: No degradation under 5+ concurrent builds

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## SC-019: Reproducible builds (same input = same output)

**Requirement**: Building same commit produces identical artifacts

### Measurement

| Test | Expected | Actual | Status | Notes |
|------|----------|--------|--------|-------|
| Rebuild same commit | Identical | _____ | ☐ Pass | SHA256 matches |
| Different timestamps | No difference | _____ | ☐ Pass | Artifacts identical |
| Cross-platform | Consistent | _____ | ☐ Pass | Same version info |

**Test Procedure**:
1. Build commit SHA: abc123
2. Generate artifact hash
3. Rebuild same commit
4. Compare artifact hashes

**Pass Criteria**: Hashes match (reproducible)

**Result**: ☐ PASS ☐ FAIL

**Notes**: _______________________________________________

---

## Summary

### Overall Results

| Category | Status | Pass Rate | Notes |
|----------|--------|-----------|-------|
| **Performance** (SC-001 to 006) | ☐ Pass | ___% | Build times and feedback |
| **Quality** (SC-007 to 009) | ☐ Pass | ___% | Code quality and tests |
| **Security** (SC-010 to 012) | ☐ Pass | ___% | Signing and protection |
| **Operations** (SC-013 to 019) | ☐ Pass | ___% | Documentation and procedures |

### Final Score

**Overall**: ☐ PASS ☐ FAIL

- **PASS**: All 19 success criteria met
- **FAIL**: One or more criteria not met

### Gaps Identified

| Criteria | Issue | Severity | Action |
|----------|-------|----------|--------|
| SC-___ | | High/Med/Low | |
| SC-___ | | High/Med/Low | |
| SC-___ | | High/Med/Low | |

### Action Items

1. [ ] **Issue**: _________________ **Owner**: _____ **Due**: _____
2. [ ] **Issue**: _________________ **Owner**: _____ **Due**: _____
3. [ ] **Issue**: _________________ **Owner**: _____ **Due**: _____

### Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Validation Lead | __________ | _____ | __________ |
| Technical Lead | __________ | _____ | __________ |
| Project Manager | __________ | _____ | __________ |

---

## Appendices

### A. Detailed Measurements

[Add detailed measurements, charts, graphs here]

### B. Supporting Evidence

- Build logs
- Performance metrics
- Test results
- Screenshots

### C. References

- Success Criteria Definition: [Link]
- CI/CD Architecture: docs/ci-cd/architecture-decisions.md
- Troubleshooting: docs/ci-cd/troubleshooting.md

---

**Document prepared**: ____________  
**Last reviewed**: ____________  
**Next review**: ____________

