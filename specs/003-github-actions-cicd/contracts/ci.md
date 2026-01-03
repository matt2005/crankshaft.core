# Workflow Contract: CI (Continuous Integration)

**Purpose**: Pull request quality gate that verifies code quality and builds before merge.

**Specification Version**: 1.0.0  
**Feature**: 003-github-actions-cicd  
**Task**: T012 (Integration Contract)  
**Status**: Production (Phase 3)

---

## Workflow Identification

- **Workflow Name**: CI
- **Workflow File**: `.github/workflows/ci.yml`
- **Workflow Type**: Main CI workflow (triggered on PR, push)
- **Primary Purpose**: Quality gate and build verification for feature branches

---

## Trigger Conditions

### On `pull_request`

- **Trigger**: PR opened, updated, or synchronized
- **Paths**: Changes in core/, ui/, scripts/, cmake/, workflows/
- **Effect**: Run full quality checks + amd64-only build
- **Blocking**: Yes - quality failures block merge

### On `push`

- **Trigger**: Commit pushed to any branch
- **Paths**: Same as pull_request
- **Effect**: Full CI pipeline (quality + architectures based on branch)
- **Blocking**: No - informational only

### On `workflow_dispatch`

- **Trigger**: Manual trigger from Actions tab
- **Inputs**: `amd64only` (optional, boolean)
- **Effect**: Build amd64 only if input is true
- **Purpose**: Debug builds, quick iteration

---

## Job Execution Flow

```
check-skip
  ↓ (parallel with code-quality)
code-quality (uses quality-scan.yml) ─→ quality-scan checks all 4 tools
  ↓
post-quality-results (if PR) ────────→ Post comment with results
  ↓
build-packages (uses build.yml) ────→ Build for specified architectures
  ↓
dispatch-cd-fastpath (if dispatch + amd64) → Trigger CD workflow
```

---

## Jobs

### 1. `check-skip`

**Purpose**: Determine if CI should be skipped based on commit message

**Triggers**:
- `[skip ci]` in commit message → skip entire CI
- `[ci skip]` in commit message → skip entire CI

**Output**: 
- `skip`: 'true' or 'false'

**Dependencies**: None (runs first)

### 2. `code-quality`

**Purpose**: Run comprehensive quality checks

**Configuration**:
- Uses reusable workflow: `./.github/workflows/quality-scan.yml`
- Runner: `ubuntu-latest`
- Build type: `Debug`
- JSON output: `true`

**Checks Performed**:
1. Code formatting (clang-format)
2. Static analysis (clang-tidy)
3. Code analysis (cppcheck)
4. License headers verification

**Success Criteria**:
- ✅ Formatting: No changes needed (OR fixed with --fix)
- ✅ License headers: All present
- ⚠️ Clang-tidy: Warnings allowed
- ⚠️ Cppcheck: Informational

**Dependencies**: 
- `check-skip`

**Conditions**:
- `needs.check-skip.outputs.skip != 'true'`

### 3. `post-quality-results`

**Purpose**: Post quality check results as PR comment

**Trigger**: Only on pull requests (`github.event_name == 'pull_request'`)

**Behavior**:
- ✅ Pass: Shows success message with all checks passing
- ❌ Fail: Shows failure message with guidance for each check
- Creates new comment or updates existing quality comment

**Comment Format**:
```markdown
## 📊 Quality Check Results

✅ **All quality checks passed!**

- ✓ Code formatting (clang-format)
- ✓ Static analysis (clang-tidy)
- ✓ Code analysis (cppcheck)
- ✓ License headers verified

[View full logs](...)
```

**Dependencies**:
- `code-quality`

**Condition**:
- `always() && github.event_name == 'pull_request'`

### 4. `build-packages`

**Purpose**: Build binaries for specified architectures

**Configuration**:
- Uses reusable workflow: `./.github/workflows/build.yml`
- Architectures: Conditional based on branch/event:
  - Feature branch: `amd64` only (fast feedback, FR-011)
  - Main/develop: `amd64 arm64 armhf` (full matrix)
  - Dispatch with `amd64only`: Override to `amd64`

**Time Estimate**: 
- amd64 only: ~10-15 minutes
- All architectures: ~30-45 minutes

**Dependencies**:
- `code-quality` (must pass for build to start)

**Condition**:
- `needs.check-skip.outputs.skip != 'true'`

### 5. `dispatch-cd-fastpath`

**Purpose**: Auto-trigger CD workflow for manual dispatch builds

**Trigger**: Only when manually dispatched with `amd64only=true`

**Behavior**:
- Finds CD workflow
- Dispatches with same git ref and `amd64only=true` input
- Allows rapid iteration during development

**Dependencies**:
- `build-packages`

**Condition**:
- `github.event_name == 'workflow_dispatch' && github.event.inputs.amd64only == 'true'`

---

## Architecture Selection Logic

```
IF manual dispatch + amd64only == 'true'
  → Use 'amd64'
ELSE IF main OR develop branch (push or PR base)
  → Use 'amd64 arm64 armhf' (full matrix)
ELSE
  → Use 'amd64' (feature branch, fast feedback)
```

**Rationale**:
- **Fast Feedback (FR-011)**: Feature branches build amd64 only (~15 min)
- **Full Validation**: Main/develop builds all ARM architectures (~45 min)
- **Manual Override**: dispatch with amd64only allows quick build during development

---

## Quality Check Results Comment

Posted automatically on PRs (T011 implementation):

**When posted**: After `code-quality` job completes
**Updated on**: Subsequent pushes to the PR
**Dismissed**: PR closed or merged
**Visibility**: All PR reviewers see feedback immediately

**Comment Content**:
- Build URL for detailed logs
- Pass/fail status for each of 4 checks
- Guidance for fixing failures:
  - Formatting: `./scripts/format.sh`
  - License: Add GPL3 header
  - Tidy: Review warnings
  - Cppcheck: Check findings

---

## Exit Codes & Merge Blocking

**Quality checks block merge if**:
- ❌ Formatting check fails (CR-003)
- ❌ License header check fails (CR-001)
- ⚠️ Build fails (missing dependencies, compilation errors)

**Quality checks don't block if**:
- ⚠️ Clang-tidy warnings (informational)
- ⚠️ Cppcheck findings (informational)

**Note**: The `quality-scan.yml` reusable workflow will:
- Fail the job if formatting or license checks fail
- Report (but not fail) if tidy/cppcheck finds issues
- Fail the overall job (blocking build) if build step fails

---

## Performance Targets

| Stage | Time | Target Met? |
|-------|------|-------------|
| Check skip | <1s | ✅ Yes |
| Code quality (4 checks + build) | ~7m | ✅ Yes (SC-001: < 10m) |
| Post comment | <10s | ✅ Yes |
| Build amd64 only | ~15m | ✅ Yes (FR-011) |
| Build all archs | ~45m | ✅ Acceptable |
| **Total (PR, feature branch)** | **~22m** | ✅ Good |
| **Total (push, main)** | **~50m** | ✅ Acceptable |

---

## Parallel Execution

The following jobs run in parallel:
- `check-skip` (first, outputs used by others)
- `code-quality` (after check-skip)
- `post-quality-results` (after code-quality, in parallel with build)
- `build-packages` (after code-quality)

**Critical Path**: check-skip → code-quality → build-packages

---

## Troubleshooting

### "CI workflow failed"

**Check**:
1. View workflow run in Actions tab
2. Check `code-quality` job for specific failure
3. Look at `post-quality-results` comment on PR for guidance

### "Quality checks passed locally but failed in CI"

**Cause**: Tool version differences
**Solution**:
```bash
# Update local tools
apt-get install --upgrade clang-format clang-tidy cppcheck

# Or use container
docker run -v $(pwd):/code -w /code ubuntu:trixie ./scripts/build.sh
```

### "Build timeout on ARM architectures"

**Cause**: Full matrix build takes 45+ minutes
**Solution**:
- Use `amd64only` input for quick iteration
- Merge to feature branch when confident
- Main builds all architectures for comprehensive testing

### "PR comment not appearing"

**Cause**: Workflow permissions or PR event context
**Condition**: `post-quality-results` only runs on `pull_request` events
**Solution**: Push to PR again to retrigger workflow

---

## Related Documentation

- [Quality Scan Contract](quality-scan.md) - Reusable workflow specification
- [Build Workflow Contract](build-workflow.md) - Build orchestration details
- [Developer Handbook](../../docs/ci-cd/developer-handbook.md) - Developer interaction guide
- [Workflow Guide](../../docs/ci-cd/workflow-guide.md) - All workflows overview

---

## Change Log

**Version 1.0.0** (2025-01-03)
- ✅ Initial CI workflow contract from Feature 003 Phase 3
- ✅ Integrated quality-scan reusable workflow
- ✅ Added PR comment job for quality feedback
- ✅ Documented architecture selection logic
- ✅ Specified merge-blocking criteria

---

## Security Considerations

- **Permissions**: `pull-requests: write` only for comment job
- **Secrets**: No secrets used in CI workflow (quality checks only)
- **Code Execution**: Scripts use `set -euo pipefail` for safety
- **Dependency Pinning**: Actions use pinned versions (`@v4`, `@v7`)

---

## Future Enhancements (Backlog)

- [ ] Cache build artifacts between runs
- [ ] Parallel execution of 4 quality checks (currently sequential)
- [ ] Store quality metrics history
- [ ] Auto-fix formatting and commit back to PR branch
- [ ] Performance regression detection
