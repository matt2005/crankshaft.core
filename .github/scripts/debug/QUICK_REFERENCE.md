# Workflow Investigation Quick Reference

## Fast Commands

### Investigate Latest Failure
```bash
./.github/scripts/debug/investigate-workflow.sh
```
**Output:** Run status, failed jobs, error messages, fix suggestions

### Export Complete Logs & Report
```bash
./.github/scripts/debug/investigate-workflow.sh latest --export
```
**Output:** `.github/debug-logs/` directory with JSON exports and markdown analysis

### Auto-Fix Common Issues
```bash
./.github/scripts/debug/investigate-workflow.sh latest --fix
```
**Fixes:** Script permissions, code formatting, common errors

### Specific Run ID
```bash
./.github/scripts/debug/investigate-workflow.sh 20692908702
```

---

## gh CLI Direct Commands

### Quick Status
```bash
gh run view --log-failed
```

### List Recent Runs
```bash
gh run list --branch 003-github-actions-cicd --limit 5
```

### Extract Failed Job IDs
```bash
gh api repos/{owner}/{repo}/actions/runs/RUN_ID/jobs \
  --jq '.jobs[] | select(.conclusion == "failure") | .id'
```

### Get Job Logs
```bash
gh api repos/{owner}/{repo}/actions/jobs/JOB_ID/logs
```

### Rerun Failed Jobs
```bash
gh run rerun RUN_ID --failed
```

---

## Common Issues & Quick Fixes

| Issue | Command |
|-------|---------|
| **Missing Qt6** | Update workflow to add qt6-base-dev, qt6-tools-dev |
| **Permission denied** | `./.github/scripts/debug/investigate-workflow.sh latest --fix` |
| **Format errors** | `./scripts/format.sh` then push |
| **Build failure** | `./scripts/build.sh --build-type Debug` locally |
| **Test failure** | `ctest --test-dir build --output-on-failure` |

---

## Investigation Workflow

1. **See what failed** → `./.github/scripts/debug/investigate-workflow.sh`
2. **Get error details** → Check output or use `--export` for full logs
3. **Fix locally** → Apply suggested fixes
4. **Test** → `./scripts/build.sh && ctest`
5. **Push** → `git add . && git commit && git push`
6. **Monitor** → `gh run watch` or investigate again

---

## Useful Aliases

Add to your shell config:

```bash
# Investigate latest workflow
alias investigate='./.github/scripts/debug/investigate-workflow.sh latest'

# Investigate with logs
alias investigate-full='./.github/scripts/debug/investigate-workflow.sh latest --export'

# Auto-fix workflow issues
alias fix-workflow='./.github/scripts/debug/investigate-workflow.sh latest --fix'

# Watch current run
alias watch-ci='gh run watch'

# See failed logs
alias show-failed='gh run view --log-failed'
```

---

## Troubleshooting

**gh CLI not found?**
```bash
# Install
brew install gh  # macOS
sudo apt install gh  # Linux
```

**Not authenticated?**
```bash
gh auth login
```

**jq not found?**
```bash
# Needed for JSON parsing
brew install jq  # macOS
sudo apt install jq  # Linux
```

---

For detailed guide: `./.github/scripts/debug/INVESTIGATION_GUIDE.md`
