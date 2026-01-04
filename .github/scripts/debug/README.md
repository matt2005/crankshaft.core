# Workflow Debugging & Investigation Tools

Complete toolset for diagnosing and resolving GitHub Actions workflow failures in the Crankshaft project.

## Quick Start

### Investigate Latest Failure (30 seconds)
```bash
./.github/scripts/debug/investigate-workflow.sh latest
```

### Get Full Analysis & Logs
```bash
./.github/scripts/debug/investigate-workflow.sh latest --export
cat .github/debug-logs/run-*-analysis.md
```

### Auto-Fix Common Issues
```bash
./.github/scripts/debug/investigate-workflow.sh latest --fix
```

---

## Available Tools

### 1. investigate-workflow.sh
**Fast, interactive workflow failure diagnosis**

```bash
# Quick diagnosis of latest run
./.github/scripts/debug/investigate-workflow.sh

# Diagnose specific run
./.github/scripts/debug/investigate-workflow.sh 20692908702

# With verbose output
./.github/scripts/debug/investigate-workflow.sh latest --verbose

# Export logs and generate report
./.github/scripts/debug/investigate-workflow.sh latest --export

# Auto-fix issues
./.github/scripts/debug/investigate-workflow.sh latest --fix

# Combine options
./.github/scripts/debug/investigate-workflow.sh latest --verbose --export
```

**Features:**
- ✅ Automatic run resolution (latest/branch/ID)
- ✅ Status and conclusion analysis
- ✅ Failed job detection
- ✅ Error message extraction
- ✅ Fix suggestions
- ✅ Auto-fix mode for permissions and formatting
- ✅ Integration with log exporter

### 2. export-workflow-logs.sh
**Comprehensive log export and analysis**

```bash
# Export latest run
./.github/scripts/debug/export-workflow-logs.sh latest

# Export specific run
./.github/scripts/debug/export-workflow-logs.sh 20692908702

# Export from specific branch
./.github/scripts/debug/export-workflow-logs.sh 003-github-actions-cicd

# Custom output directory
./.github/scripts/debug/export-workflow-logs.sh latest ./my-logs
```

**Output:**
```
.github/debug-logs/
├── run-20692908702-details.json       # Run metadata
├── run-20692908702-jobs.json          # Jobs list and status
├── run-20692908702-job-59403624492-code-quality.log  # Job logs
└── run-20692908702-analysis.md        # Analysis report
```

---

## Documentation

### For Quick Lookups
→ **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)**
- Fast command reference
- Common issues & fixes
- Useful aliases
- Troubleshooting tips

### For Detailed Learning
→ **[INVESTIGATION_GUIDE.md](./INVESTIGATION_GUIDE.md)**
- Complete usage guide
- 5 common issues with solutions
- Direct gh CLI usage
- Workflow integration examples
- Debugging tips

### For Architecture Understanding
→ **[SYSTEM_OVERVIEW.md](./SYSTEM_OVERVIEW.md)**
- System capabilities
- Usage patterns
- Implementation details
- Integration points
- Best practices

---

## Example Workflows

### Pattern: Quick Fix Cycle
```bash
# 1. See what failed
./.github/scripts/debug/investigate-workflow.sh latest

# 2. Fix locally
./scripts/build.sh --build-type Debug

# 3. Test
ctest --test-dir build --output-on-failure

# 4. Commit & push
git add . && git commit -m "fix: [issue]" && git push

# 5. Monitor
gh run watch
```

### Pattern: Deep Investigation
```bash
# 1. Export everything
./.github/scripts/debug/investigate-workflow.sh latest --export

# 2. Review generated report
cat .github/debug-logs/run-*-analysis.md

# 3. Check specific job logs
cat .github/debug-logs/run-*-job-*.log | grep -A5 "error"

# 4. Fix and test
# ... apply fixes ...

# 5. Verify
./scripts/build.sh && ctest
```

### Pattern: Auto-Fix & Verify
```bash
# 1. Try automatic fixes
./.github/scripts/debug/investigate-workflow.sh latest --fix

# 2. Test
./scripts/build.sh --build-type Debug

# 3. If successful, commit
git add . && git commit -m "fix: Auto-fix workflow issues" && git push
```

---

## Supported Issues

These are pre-configured issue patterns the tools can diagnose:

| Issue | Detection | Fix Suggestion |
|-------|-----------|----------------|
| **Missing Dependencies** | CMake: FindQt6.cmake not found | Add to workflow install step |
| **Script Permissions** | Permission denied on ./scripts | `git update-index --chmod=+x` |
| **Code Formatting** | Code style violations | Run `./scripts/format.sh` |
| **Build Failures** | Compilation errors | Check CMakeLists.txt, dependencies |
| **Test Failures** | ctest failures | Run locally, check output |

---

## Requirements

### Install gh CLI
```bash
# macOS
brew install gh

# Debian/Ubuntu
sudo apt install gh

# Other: https://cli.github.com/manual/gh_help
```

### Install jq (JSON processor)
```bash
# macOS
brew install jq

# Debian/Ubuntu
sudo apt install jq
```

### Authenticate
```bash
gh auth login
```

---

## Troubleshooting

### Tools not working?
Check prerequisites:
```bash
gh version          # Should show version
gh auth status      # Should show "Logged in"
jq --version        # Should show version
bash --version      # Should be 4.0+
```

### Scripts not executable?
```bash
git update-index --chmod=+x ./.github/scripts/debug/*.sh
git commit -m "fix: Make debug scripts executable"
git push
```

### Can't find run?
```bash
# Check current branch
git branch

# List recent runs
gh run list --limit 5

# Specify branch explicitly
./.github/scripts/debug/investigate-workflow.sh latest --branch 003-github-actions-cicd
```

---

## Integration with GitHub Actions

Add to your CI workflow to auto-investigate failures:

```yaml
- name: Investigate workflow failure
  if: failure()
  run: |
    ./.github/scripts/debug/investigate-workflow.sh ${{ github.run_id }} --export
    
- name: Upload debug logs
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: workflow-debug-logs
    path: .github/debug-logs/
```

---

## Command Cheat Sheet

```bash
# Investigation
./.github/scripts/debug/investigate-workflow.sh           # Latest run
./.github/scripts/debug/investigate-workflow.sh latest --export  # With logs
./.github/scripts/debug/investigate-workflow.sh latest --fix      # Auto-fix

# Logs
./.github/scripts/debug/export-workflow-logs.sh latest    # Export logs
./.github/scripts/debug/export-workflow-logs.sh 20692908702  # Specific run

# Direct gh CLI
gh run view --log-failed                    # Quick failed logs
gh run list --limit 5                       # Recent runs
gh run watch                                # Monitor current
gh run rerun --failed                       # Retry failures

# Local verification
./scripts/build.sh --build-type Debug       # Build locally
ctest --test-dir build --output-on-failure  # Run tests
./scripts/format.sh                         # Fix formatting
```

---

## Next Steps

1. **Explore**: Read the appropriate documentation for your use case
   - Quick task? → [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
   - Learning? → [INVESTIGATION_GUIDE.md](./INVESTIGATION_GUIDE.md)
   - Deep dive? → [SYSTEM_OVERVIEW.md](./SYSTEM_OVERVIEW.md)

2. **Try it out**: Run an investigation on the latest workflow
   ```bash
   ./.github/scripts/debug/investigate-workflow.sh latest
   ```

3. **Bookmark**: Save commands you use frequently
   ```bash
   # Add to ~/.bashrc or ~/.zshrc:
   alias investigate='./.github/scripts/debug/investigate-workflow.sh latest'
   ```

---

## Support

- **Documentation**: See files in this directory
- **GitHub CLI**: https://cli.github.com/manual
- **GitHub API**: https://docs.github.com/en/rest/actions

---

**Status**: Production Ready  
**Version**: 1.0  
**Last Updated**: 2026-01-04
