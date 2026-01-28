# Quality Scan Optimisation - Verification Checklist

## Pre-Deployment Verification

- [ ] All test files pass locally
- [ ] Workflow file syntax is valid (YAML lint)
- [ ] clang-tidy configuration is valid
- [ ] Scripts have execute permissions
- [ ] Cache key is stable
- [ ] No regression in code quality detection

## Post-Deployment Checklist

### Immediate (First 24 hours)

- [ ] Monitor first workflow run completion time
  - Expected: 12-15 minutes (cold cache)
  - Alert if: > 30 minutes
  
- [ ] Verify cache creation
  - Check Actions > All Workflows > Cache
  - Expected: ~500MB for ccache
  
- [ ] Confirm no quality regressions
  - Compare violations with previous runs
  - Should be same or better (fewer violations)
  
- [ ] Check build step logs
  - Verify Ninja is used
  - Confirm Release build mode
  - Check slim UI enabled

### Short-term (Week 1)

- [ ] Second workflow run uses cache
  - Expected time: 3-5 minutes
  - Alert if: > 15 minutes
  
- [ ] Monitor for cache misses
  - Should be < 10% of runs
  - Track CMakeLists.txt changes
  
- [ ] Verify clang-tidy parallelisation
  - Check logs for parallel execution
  - Should see multiple files processing simultaneously
  
- [ ] Test local script
  - Run `./scripts/quality-check.sh`
  - Verify output and timing

### Medium-term (Month 1)

- [ ] Analyse metric trends
  - Track build times over time
  - Identify any regressions
  
- [ ] Collect developer feedback
  - Local development experience
  - CI/CD pipeline satisfaction
  
- [ ] Review false positive rate
  - Compare with previous check set
  - Adjust if needed
  
- [ ] Document known issues
  - File timeouts
  - Memory spikes
  - Cache invalidations

## Performance Benchmarks

### Target Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Cold build time | < 15 min | — | Pending |
| Warm build time | < 5 min | — | Pending |
| Cache hit rate | > 80% | — | Pending |
| clang-tidy speedup | 5-6x | — | Pending |
| Total workflow | < 20 min (cold) | — | Pending |
| | < 6 min (warm) | — | Pending |

## Quality Assurance

### Code Quality
- [ ] Same bugs detected vs. old workflow
- [ ] No new false positives introduced
- [ ] Formatting issues still caught
- [ ] License header checks working
- [ ] Static analysis results consistent

### Performance
- [ ] Build parallelisation functional
- [ ] Cache properly isolating builds
- [ ] Ninja improving build speed
- [ ] ccache hits tracked correctly

### Reliability
- [ ] Workflow completes successfully
- [ ] No race conditions in parallel execution
- [ ] Error handling working
- [ ] Logs are clear and actionable

## Testing Scenarios

### Scenario 1: First Run (Cold Cache)
```bash
# Steps:
1. Clear all cache (GitHub Actions settings)
2. Trigger workflow manually
3. Monitor timing (expected: 12-15 min)
4. Verify all checks pass
5. Check final artifact cache

# Acceptance:
- Total time < 20 minutes
- All checks complete successfully
- Cache created (≈500MB)
```

### Scenario 2: Subsequent Runs (Warm Cache)
```bash
# Steps:
1. Make small code change (comment only)
2. Trigger workflow manually
3. Monitor timing (expected: 3-5 min)
4. Verify cache used
5. Confirm same quality results

# Acceptance:
- Total time < 10 minutes
- Cache hit reported in logs
- Build artifacts reused
```

### Scenario 3: Large Change
```bash
# Steps:
1. Make significant code changes
2. Trigger workflow manually
3. Monitor resource usage
4. Verify all checks still run
5. Confirm no timeouts

# Acceptance:
- No workflow timeouts
- All checks complete
- Quality issues properly reported
```

### Scenario 4: Local Development
```bash
# Steps:
1. Run ./scripts/quality-check.sh locally
2. Modify code
3. Run again
4. Fix reported issues
5. Re-run and verify

# Acceptance:
- Local script works reliably
- Parallel execution visible
- Fix suggestions helpful
```

## Rollback Plan

If optimisations cause issues:

### Step 1: Disable Caching
```yaml
# In .github/workflows/quality-scan.yml
# Comment out cache step
# - name: Cache build artifacts
#   uses: actions/cache@v3
```

### Step 2: Use Debug Build
```yaml
-DCMAKE_BUILD_TYPE=Debug  # Instead of Release
```

### Step 3: Disable Slim UI
```yaml
-DENABLE_SLIM_UI=OFF  # Instead of ON
```

### Step 4: Disable Parallelisation
```bash
CLANG_TIDY_JOBS=1  # Run sequentially
```

### Step 5: Revert to Previous Workflow
```bash
git checkout HEAD~1 -- .github/workflows/quality-scan.yml
```

## Issues & Resolutions

### Common Issues

| Issue | Detection | Resolution |
|-------|-----------|-----------|
| Build timeout | > 30 min runtime | Increase parallelism |
| OOM errors | Process killed | Reduce CLANG_TIDY_JOBS |
| Cache miss | > 20% miss rate | Review CMakeLists changes |
| False positives | Excessive warnings | Review clang-tidy config |
| Slow clang-tidy | No parallelisation | Verify xargs installed |

## Documentation Review

- [ ] README.md updated with new options
- [ ] Contributing guide updated
- [ ] Troubleshooting guide created
- [ ] Configuration reference complete
- [ ] Performance guide documented

## Team Communication

- [ ] Announcement sent to dev team
- [ ] Training session scheduled (if needed)
- [ ] FAQ document created
- [ ] Support channel monitored
- [ ] Feedback collection started

## Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| Developer | — | — | Pending |
| Code Reviewer | — | — | Pending |
| Infrastructure | — | — | Pending |
| QA | — | — | Pending |

## Follow-up Actions

### Week 1 Post-Deployment
- [ ] Collect initial feedback
- [ ] Monitor for stability issues
- [ ] Document any edge cases
- [ ] Plan next optimisation phase

### Month 1
- [ ] Analyse comprehensive metrics
- [ ] Plan incremental scanning
- [ ] Evaluate distributed matrix approach
- [ ] Document best practices

### Quarter Review
- [ ] Full performance audit
- [ ] ROI analysis
- [ ] Developer satisfaction survey
- [ ] Plan next improvements

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Owner:** Infrastructure Team  
**Status:** In Progress
