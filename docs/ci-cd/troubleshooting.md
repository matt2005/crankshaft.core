# CI/CD Troubleshooting Guide

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Developers, Build Engineers, Maintainers

## Overview

This guide covers common CI/CD issues in the Crankshaft project and their solutions. Issues are organized by workflow and include diagnosis steps, root causes, and fixes.

---

## Top Issues Quick Reference

| # | Issue | Symptom | Severity | Time to Fix |
|---|-------|---------|----------|------------|
| 1 | Quality gate failure | PR shows "Quality Gate: ✗" | Medium | 5-15 min |
| 2 | Build timeout | Build job exceeds 45 min | High | 10-30 min |
| 3 | Artifact not found | "Artifact not found" error | High | 5-10 min |
| 4 | APT publish fails | "Repository verification failed" | High | 15-30 min |
| 5 | GPG signing error | "GPG signature failed" | Critical | 10-20 min |
| 6 | Release creation fails | "Release job failed" | Medium | 10-20 min |
| 7 | Pi-Gen image won't boot | Image boots to black screen | High | 30-60 min |
| 8 | Secret not available | "Secret X not found" | Critical | 5-10 min |
| 9 | Workflow concurrency lock | "Workflow queued" indefinitely | Medium | 5-15 min |
| 10 | Out of disk space | Build fails with "No space left" | Critical | 10-20 min |

---

## Issue #1: Quality Gate Failure

### Symptom
- PR shows status: "Quality Gate: ✗"
- PR comment contains code violations
- Merge blocked until resolved

### Root Causes
1. Code style violations (spacing, naming)
2. Potential memory leaks (detected by clang-tidy)
3. Security issues (detected by CodeQL)
4. Code duplication above threshold

### Diagnosis Steps

1. **Check PR comment**
   - Quality workflow posts detailed violation list
   - Click "Show more" to expand violation details

2. **Review violations by category**
   ```
   Category examples:
   - clang-tidy: Modernisation, Performance, Readability
   - cppcheck: Memory leak, null pointer, bounds check
   - CodeQL: SQL injection, buffer overflow, etc.
   ```

3. **Identify which check failed**
   - Each check shown separately in comment
   - Look for "❌" mark to find failing checks

### Solutions

**For C++ code violations**:

1. **View detailed violation message**:
   ```bash
   # Click violation in PR comment
   # Shows file:line:col and explanation
   ```

2. **Fix locally**:
   ```bash
   # Format code to match style
   cd crankshaft-mvp
   ./scripts/format_cpp.sh fix
   
   # Run clang-tidy to find issues
   ./scripts/lint_cpp.sh clang-tidy
   
   # Fix violations based on output
   ```

3. **Verify fix**:
   ```bash
   # Push changes
   git add .
   git commit -m "Fix: Quality gate violations - #123"
   git push origin feature/my-feature
   
   # Wait 5 minutes for quality workflow
   # Should show "Quality Gate: ✓"
   ```

**Common violations and fixes**:

| Violation | Cause | Fix |
|-----------|-------|-----|
| `modernize-use-nullptr` | Using NULL instead of nullptr | Replace `NULL` with `nullptr` |
| `readability-named-parameter` | Unused parameter | Prefix with `/*unused*/` or remove |
| `performance-unnecessary-copy-initialization` | Unnecessary copy | Use reference or move semantics |
| `misc-unused-parameters` | Function parameter not used | Remove or prefix with `[[maybe_unused]]` |

### Prevention
- Run quality checks locally before pushing:
  ```bash
  ./scripts/format_cpp.sh check
  ./scripts/lint_cpp.sh clang-tidy
  ```
- Fix violations before push:
  ```bash
  ./scripts/format_cpp.sh fix
  ```

---

## Issue #2: Build Timeout

### Symptom
- Build job shows "Workflow execution timed out"
- Log shows incomplete build (stopped mid-compile)
- Status: "Build: ✗"

### Root Causes
1. Parallel jobs too numerous (building all architectures)
2. Slow Docker image build
3. Dependency compilation taking too long
4. Insufficient build cache
5. Large source code changes

### Diagnosis Steps

1. **Check job duration**:
   - Go to `Actions → Platform Builds → [Run]`
   - Look at "Build job [architecture]" duration
   - Timeout threshold: 45 minutes

2. **Check build log for bottleneck**:
   ```bash
   # In GitHub Actions UI
   Click job → Scroll to find slowest step
   Look for step taking >10 minutes
   ```

3. **Estimate remaining time**:
   - If 90% done at timeout: likely to succeed next attempt
   - If 50% done: need optimization

### Solutions

**Immediate fix (retry)**:
```bash
# Via GitHub CLI
gh run rerun {run_id} --failed

# Via UI
Actions → [Run] → Re-run failed jobs
```

**For repeated timeouts**:

1. **Reduce build scope for feature branches**:
   - Feature branches build amd64 only (default)
   - Main branch builds all architectures
   - Check: Are you on a feature branch?

2. **Clear Docker cache** (if Docker build slow):
   ```bash
   # Via GitHub CLI
   gh run list --branch main --status success --limit 1 | \
     xargs -I {} gh run view {} --json number | \
     jq '.run.number'
   
   # Then use that run's cache
   ```

3. **Check for large uncommitted files**:
   ```bash
   # Look for binary files in commit
   git show HEAD --stat
   
   # Remove if added accidentally
   git reset HEAD~1 --soft
   git reset HEAD <large-file>
   ```

4. **Profile build locally**:
   ```bash
   # Time build on local machine
   wsl
   time ./scripts/build.sh --build-type Debug
   
   # If >30 min locally, optimize code before pushing
   ```

### Prevention
- Keep feature branches focused (small changes)
- Commit only necessary files (avoid binaries)
- Test builds locally before pushing large changes

---

## Issue #3: Artifact Not Found

### Symptom
- Downstream workflow (APT, Release) fails
- Error: "Artifact 'build-artifacts-amd64' not found"
- Status: "Build: ✗" or "APT Publish: ✗"

### Root Causes
1. Build workflow failed (didn't produce artifacts)
2. Artifact retention period expired (30 days)
3. Wrong artifact name specified
4. Wrong branch trigger
5. Concurrency cancelled previous build

### Diagnosis Steps

1. **Check build workflow status**:
   - Go to `Actions → Platform Builds`
   - Find the build that should produce artifacts
   - Status should show "✓" (success)

2. **Check artifact age**:
   - In build run, go to "Artifacts" tab
   - Note creation timestamp
   - Default retention: 30 days

3. **Check artifact name**:
   - In build run, verify artifact exists
   - Compare name with downstream workflow (apt.yml, release.yml)

### Solutions

**If build failed**:
1. Review build log for compilation errors
2. Fix errors locally
3. Push fix to same branch
4. Build runs again automatically

**If artifact expired**:
1. Rebuild on target branch:
   ```bash
   # Manual trigger
   Actions → Platform Builds → Run workflow
   Select branch and architectures
   ```

2. Extend retention period:
   ```yaml
   # In .github/workflows/build.yml
   - uses: actions/upload-artifact@v4
     with:
       retention-days: 60  # Extend from 30 to 60
   ```

**If wrong artifact name**:
1. Verify artifact name in build workflow
2. Check downstream workflow references same name
3. Fix mismatch in YAML

### Prevention
- Monitor artifact retention dates
- Don't rely on artifacts older than 2 weeks
- For long-term storage, use GitHub Releases

---

## Issue #4: APT Publish Fails

### Symptom
- APT workflow fails at "Publish to repository" step
- Error: "Repository verification failed"
- Error: "GPG signature invalid"
- Status: "APT Publish: ✗"

### Root Causes
1. GPG key issue (expired, missing passphrase)
2. Repository metadata corrupted
3. Duplicate package in repository
4. APT server connection failed
5. Insufficient disk space on APT server

### Diagnosis Steps

1. **Check GPT key status**:
   ```bash
   # Verify GPG secret exists
   gh secret list --repo opencardev/crankshaft | grep GPG
   
   # Should show: GPG_SIGNING_KEY, GPG_KEY_PASSPHRASE
   ```

2. **Check APT repository**:
   ```bash
   # Test APT update
   apt-get update
   
   # If fails, repository metadata corrupted
   ```

3. **Check for duplicate packages**:
   ```bash
   # List published packages
   apt-cache search crankshaft
   
   # Should show each package once per version
   ```

### Solutions

**GPG key issues**:

1. **Verify key is valid**:
   ```bash
   # Export key locally
   gpg --list-secret-keys
   
   # Check expiration
   gpg --list-keys <key-id> --with-colon
   ```

2. **Update expired key**:
   ```bash
   # Extend key expiration
   gpg --edit-key <key-id>
   # Type: expire
   # Select: 2y (extend 2 years)
   # Save
   
   # Update secret in GitHub
   gh secret set GPG_SIGNING_KEY < exported-key.txt
   ```

3. **Verify passphrase**:
   ```bash
   # Test passphrase works
   echo "test message" | gpg --detach-sign --passphrase "$PASS"
   
   # If fails, update GPG_KEY_PASSPHRASE secret
   ```

**Repository issues**:

1. **Rebuild repository from scratch**:
   ```bash
   # Via manual workflow
   Actions → APT Repository → Run workflow
   
   # Removes corrupted metadata and rebuilds
   ```

2. **Remove duplicate packages**:
   ```bash
   # Find duplicate
   apt-cache policy crankshaft-ui
   
   # Remove older version
   # (Contact APT maintainer)
   ```

### Prevention
- Monitor GPG key expiration (check quarterly)
- Test APT updates on regular basis
- Use apt-get clean after testing

---

## Issue #5: GPG Signing Error

### Symptom
- Workflow fails at signing step
- Error: "gpg: error while signing: unknown error"
- Error: "gpg: failed to sign"
- Status: "APT Publish: ✗" or "Release: ✗"

### Root Causes
1. GPG key expired
2. GPG key passphrase incorrect
3. GPG binary not installed
4. Insufficient entropy (on headless system)
5. GPG agent timeout

### Diagnosis Steps

1. **Check GPG installation**:
   ```bash
   gpg --version
   
   # Should output version and build info
   ```

2. **Check key status**:
   ```bash
   gpg --list-secret-keys
   
   # Should show key with [SCEA] flags
   # Check "sec  rsa4096 ... [expired: ...]"
   ```

3. **Test signing locally**:
   ```bash
   echo "test" | gpg --detach-sign --user <key-id>
   
   # If fails, key issue confirmed
   ```

### Solutions

**Check passphrase**:
```bash
# Verify passphrase works
echo "test message" | \
  gpg --batch --no-tty \
      --passphrase "$GPG_KEY_PASSPHRASE" \
      --detach-sign

# If fails: passphrase incorrect, update secret
gh secret set GPG_KEY_PASSPHRASE < <(echo "correct-passphrase")
```

**Renew expired key**:
```bash
# Get current key ID
KEY_ID=$(gpg --list-secret-keys --with-colon | \
         grep "^sec" | cut -d: -f5 | head -1)

# Extend expiration
gpg --batch --no-tty --default-key "$KEY_ID" \
    --quick-set-expire "$KEY_ID" 2y

# Export and update secret
gpg --export-secret-keys "$KEY_ID" | \
    gh secret set GPG_SIGNING_KEY
```

**For headless systems** (Linux, CI):
```bash
# Generate entropy (if system slow)
# Create /dev/urandom-fed process
rngd -r /dev/urandom

# Or skip entropy generation in GPG
echo "pinentry-program /usr/bin/pinentry-curses" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

### Prevention
- Monitor key expiration dates
- Refresh keys quarterly
- Test signing in release preview phase

---

## Issue #6: Release Creation Fails

### Symptom
- Release workflow fails
- Error: "Release creation failed"
- Error: "Tag not found"
- Status: "Release: ✗"

### Root Causes
1. Build artifacts missing (Issue #3)
2. Tag doesn't exist or not pushed
3. Release already exists
4. GitHub API rate limit exceeded
5. Insufficient permissions

### Diagnosis Steps

1. **Check if tag exists**:
   ```bash
   git tag | grep v1.2.3
   
   # If not found: tag not pushed
   git push origin v1.2.3
   ```

2. **Check if release exists**:
   ```bash
   gh release view v1.2.3
   
   # If shows "release not found", proceed with creation
   # If shows details, release already exists
   ```

3. **Check build artifacts**:
   ```bash
   # Find build run ID from logs
   gh run list --branch main --status success --limit 1
   
   # Check for artifacts
   gh run view <build-run-id> --json artifacts
   ```

### Solutions

**If tag missing**:
```bash
# Create and push tag
git tag v1.2.3
git push origin v1.2.3

# Workflow automatically triggers, creates release
```

**If release already exists** (updating):
```bash
# Delete old release and tag
gh release delete v1.2.3 --yes
git push origin :refs/tags/v1.2.3

# Recreate
git tag v1.2.3
git push origin v1.2.3
```

**If using manual release mode**:
```bash
# Go to Actions → Release → Run workflow
# Enter build-run-id from successful build
# Leave tag field empty

# Workflow uses existing artifacts without rebuilding
```

### Prevention
- Tag production releases with semantic versioning (v1.2.3)
- Use `git push origin --tags` to ensure tags pushed
- Verify release in GitHub UI before announcing

---

## Issue #7: Pi-Gen Image Won't Boot

### Symptom
- Image written to SD card
- Raspberry Pi 4 boots, shows black screen
- No SSH access, no console output
- Status: "Pi-Gen Images: ✓" (workflow succeeded)

### Root Causes
1. Wrong APT channel used (nightly vs stable)
2. Kernel version incompatible with RPi4
3. Device tree blob missing or corrupt
4. Root filesystem not extracted properly
5. SD card not fully written

### Diagnosis Steps

1. **Check which image used**:
   ```bash
   # Look at Pi-Gen workflow run
   Actions → Pi-Gen Images → [Run]
   
   Check input: apt_channel (stable/nightly)
   Check input: image_types (lite/full)
   ```

2. **Verify SD card write**:
   ```bash
   # On Linux/WSL
   lsblk  # List drives
   sudo dd if=image.img of=/dev/sdX bs=4M status=progress
   sync   # Ensure written
   ```

3. **Check for errors during build**:
   ```bash
   # In workflow logs
   Look for "ERROR" or "FAILED" messages
   Check "Boot verification" step
   ```

### Solutions

**Use stable APT channel**:
```bash
# Retry Pi-Gen build
Actions → Pi-Gen Images → Run workflow
Select apt_channel: stable (not nightly)

# Wait for completion, rewrite SD card
```

**Verify image file integrity**:
```bash
# Check SHA256 (from workflow artifacts)
sha256sum image.img
# Compare with artifacts/image.img.sha256

# If mismatch: download again and retry
```

**Test with lite image first**:
```bash
# Lite image more reliable than full
# Download lite image from workflow artifacts
# Write to SD card
# Boot and test connectivity:
ssh -i /path/to/key pi@<pi-ip>
```

**Enable HDMI debugging**:
```bash
# Create config.txt on SD card boot partition
hdmi_force_hotplug=1
hdmi_drive=2
```

### Prevention
- Always test on Raspberry Pi 4 (same hardware)
- Use stable APT channel for production
- Keep SD card with known good image for testing
- Monitor Pi-Gen build logs for warnings

---

## Issue #8: Secret Not Available

### Symptom
- Workflow fails accessing secret
- Error: "Secret 'X' not found"
- Error: "Null or empty value"
- Status: "Job failed"

### Root Causes
1. Secret not created in repository
2. Secret not inherited from organization
3. Workflow using wrong secret name
4. Secret deleted or renamed
5. Access token expired

### Diagnosis Steps

1. **Check if secret exists**:
   ```bash
   gh secret list --repo opencardev/crankshaft
   
   # Compare with secret name in workflow YAML
   # Check spelling and case
   ```

2. **Check secret scope**:
   ```bash
   # Repository secrets
   gh secret list --repo opencardev/crankshaft
   
   # Organization secrets
   gh secret list --org opencardev
   ```

3. **Check workflow variable reference**:
   ```yaml
   # Correct syntax
   - name: Use secret
     run: echo ${{ secrets.MY_SECRET }}
   
   # Incorrect (missing 'secrets.' prefix)
   run: echo ${{ MY_SECRET }}
   ```

### Solutions

**Create missing secret**:
```bash
# Option 1: GitHub CLI
gh secret set MY_SECRET < <(echo "secret-value")

# Option 2: GitHub UI
Settings → Secrets and variables → Actions → New repository secret

# Then reference in workflow
env:
  MY_SECRET: ${{ secrets.MY_SECRET }}
```

**Check secret value**:
```bash
# Can't view secret value, but can verify creation
gh secret list

# Should show "MY_SECRET" in list
```

**Fix workflow reference**:
```yaml
# Wrong
- run: echo ${{ MY_SECRET }}

# Correct
- run: echo ${{ secrets.MY_SECRET }}

# Or use env
env:
  SOME_VAR: ${{ secrets.MY_SECRET }}
- run: echo $SOME_VAR
```

### Prevention
- Document all required secrets in README
- Validate secret names match workflow references
- Periodically audit secrets (remove unused)

---

## Issue #9: Workflow Concurrency Lock

### Symptom
- Workflow appears in "Queued" state indefinitely
- Status shows yellow dot (pending)
- Not progressing even after 30+ minutes
- Other workflows on same concurrency group are running

### Root Causes
1. Previous workflow not cancelled properly
2. Concurrency group limits too restrictive
3. Zombie workflow stuck in running state
4. Race condition in concurrency key

### Diagnosis Steps

1. **Check concurrency group**:
   ```bash
   # View workflow
   Actions → [Workflow] → [Run]
   
   Look for "Concurrency group: build-main" (example)
   ```

2. **Check other runs in group**:
   ```bash
   # Via GitHub CLI
   gh run list --status in_progress | grep "build-main"
   
   # Should show only one run at a time
   ```

3. **Check run duration**:
   ```bash
   # If previous run >2 hours, likely stuck
   gh run view <run-id> --json startedAt,completedAt
   ```

### Solutions

**Cancel stuck workflow**:
```bash
# Via GitHub CLI
gh run cancel <stuck-run-id>

# Queued workflow should start immediately
```

**Monitor concurrency**:
```bash
# Check if one branch blocks others
Actions → [Workflow] → [Recent runs]

# If many "Queued" with one "In progress"
# Concurrency too restrictive, consider adjusting
```

**Increase parallel jobs**:
```yaml
# In workflow YAML, if appropriate
concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

# And increase max runners
jobs:
  build-amd64:
    runs-on: [self-hosted, amd64]
  build-arm64:
    runs-on: [self-hosted, arm64]
```

### Prevention
- Monitor workflow queue regularly
- Set reasonable timeouts (45 min for builds)
- Use `cancel-in-progress: true` to clean up old runs

---

## Issue #10: Out of Disk Space

### Symptom
- Build fails with "No space left on device"
- Docker build fails: "Write failed"
- Artifact upload fails
- Status: "Build: ✗"

### Root Causes
1. Docker images accumulating (no cleanup)
2. Build artifacts from previous runs
3. Temporary build files not cleaned
4. Insufficient disk on runner

### Diagnosis Steps

1. **Check disk usage** (on build runner):
   ```bash
   df -h
   
   # Check if root (/) or /var is full
   du -sh /*
   ```

2. **Check Docker usage**:
   ```bash
   docker system df
   
   # Should show images, containers, volumes
   ```

3. **Check temporary files**:
   ```bash
   du -sh /tmp /var/tmp ~/.cache
   
   # Large directories indicate cleanup needed
   ```

### Solutions

**Clean Docker images**:
```bash
# Remove dangling images
docker image prune -f

# Remove unused images older than 72 hours
docker image prune -f --filter "until=72h"
```

**Clean build artifacts**:
```bash
# Remove old GitHub Actions artifacts
cd ~/work

# Find and remove old directories (>7 days)
find . -type d -ctime +7 -exec rm -rf {} +
```

**Extend disk space**:
```bash
# For GitHub-hosted runners: auto-cleanup handled

# For self-hosted runners:
# 1. Add disk space to system
# 2. Or add cache cleanup job to workflow

# In workflow YAML
- name: Clean up Docker
  if: always()
  run: |
    docker system prune -f --all
    docker volume prune -f
```

**Add cleanup step to workflow**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # ... build steps ...
      
      - name: Cleanup
        if: always()
        run: |
          du -sh ~/.cache
          rm -rf ~/.cache/pip
          docker system prune -f
```

### Prevention
- Add cleanup steps to all long-running workflows
- Monitor disk usage weekly on self-hosted runners
- Set GitHub Actions artifact retention to 7-14 days

---

## Getting Help

### Information to Include When Reporting Issues

1. **Workflow name and run ID**
   ```bash
   gh run list --repo opencardev/crankshaft | head -5
   ```

2. **Full workflow log**
   ```bash
   gh run view <run-id> --log > run.log
   ```

3. **System information**
   ```bash
   uname -a
   docker --version
   cmake --version
   ```

4. **Recent commits**
   ```bash
   git log --oneline -5
   ```

### Resources

- **Workflow guide**: `docs/ci-cd/workflow-guide.md`
- **Architecture decisions**: `docs/ci-cd/architecture-decisions.md`
- **Developer handbook**: `docs/ci-cd/developer-handbook.md`
- **GitHub Actions docs**: https://docs.github.com/en/actions
- **Community issues**: https://github.com/opencardev/crankshaft/issues

### Common Support Channels

- **GitHub Issues**: Report bugs, request features
- **GitHub Discussions**: Ask questions, share knowledge
- **Slack/Discord**: Real-time chat (if enabled)
- **Email**: Submit detailed bug reports

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version with top 10 issues |
| 1.1 | 2025-01-XX | Added GPU/ARM runner specifics (pending) |

