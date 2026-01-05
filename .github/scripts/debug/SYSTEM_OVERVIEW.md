# Workflow Investigation & Resolution System

## System Overview

You now have a complete workflow investigation system to diagnose and resolve GitHub Actions failures. This system consists of three components:

### 1. **investigate-workflow.sh** - Interactive CLI Tool
- **Purpose**: Fast diagnosis of workflow failures
- **Location**: `./.github/scripts/debug/investigate-workflow.sh`
- **Input**: Run ID or "latest" for current branch
- **Output**: Status, failed jobs, error messages, fix suggestions

### 2. **export-workflow-logs.sh** - Log Exporter  
- **Purpose**: Complete log export and analysis
- **Location**: `./.github/scripts/debug/export-workflow-logs.sh`
- **Input**: Run ID or "latest"
- **Output**: JSON exports, logs, and markdown analysis report

### 3. **Documentation**
- `INVESTIGATION_GUIDE.md` - Comprehensive guide
- `QUICK_REFERENCE.md` - Fast lookup commands
- This file - System overview

---

## System Capabilities

### Automated Features

✅ **Automatic Run Resolution**
- Get latest run on current branch with: `investigate-workflow.sh latest`
- Or use specific numeric run ID: `investigate-workflow.sh 20692908702`

✅ **Error Detection & Analysis**
- Extract error messages from logs
- Pattern matching for common issues
- Error counting and categorisation

✅ **Suggested Fixes**
- Formatting issues → suggest `./scripts/format.sh`
- Build failures → suggest dependency/CMake checks
- Permission issues → suggest `git update-index --chmod`
- Test failures → suggest local test runs

✅ **Automated Fixes** (with `--fix` flag)
- Fix script execute bits
- Auto-format code
- Common configuration issues

✅ **Detailed Logging**
- Export all run metadata
- Per-job log extraction
- Error pattern analysis
- Markdown reports

---

## Quick Usage Patterns

### Pattern 1: Quick Diagnosis (30 seconds)
```bash
# See what failed and why
./.github/scripts/debug/investigate-workflow.sh latest

# Output shows:
# ✓ Run status
# ✗ Failed jobs (by name)
# ⚠ Error messages
# 💡 Suggested fixes
```

### Pattern 2: Detailed Analysis (2 minutes)
```bash
# Export full logs and generate report
./.github/scripts/debug/investigate-workflow.sh latest --export

# Results in .github/debug-logs/:
# - JSON exports (run details, jobs, logs)
# - Markdown analysis with error patterns
# - Ready for deep investigation
```

### Pattern 3: Auto-Fix & Verify
```bash
# Try automatic fixes
./.github/scripts/debug/investigate-workflow.sh latest --fix

# Test locally
./scripts/build.sh --build-type Debug

# Commit and push
git add . && git commit -m "fix: Resolve workflow issues" && git push

# Monitor new run
gh run watch
```

### Pattern 4: Direct gh CLI Investigation
```bash
# See failed jobs
gh run view 20692908702 --json status,conclusion,jobs

# Get logs for specific job
gh api repos/{owner}/{repo}/actions/jobs/JOB_ID/logs

# Rerun only failed jobs
gh run rerun 20692908702 --failed
```

---

## Architecture

### Data Flow

```
GitHub Actions Run
        ↓
investigate-workflow.sh
        ↓
    ├─→ Extract Status
    ├─→ Get Jobs List
    ├─→ Analyse Failed Jobs
    ├─→ Extract Error Messages
    └─→ Suggest Fixes
        ↓
    [Display Results]
        ↓
Optional: --export flag
        ↓
export-workflow-logs.sh
        ↓
    ├─→ Save Run Metadata
    ├─→ Save All Logs
    ├─→ Analyse Patterns
    └─→ Generate Report
        ↓
    .github/debug-logs/
    ├─ run-ID-details.json
    ├─ run-ID-jobs.json
    ├─ run-ID-job-*.log
    └─ run-ID-analysis.md
```

### GitHub API Integration

The tools use:
- **gh CLI**: Command-line interface (easier, more reliable)
- **GitHub REST API**: For detailed queries and data extraction
- **jq**: JSON processing for parsing API responses

---

## Implementation Details

### investigate-workflow.sh Features

**Capabilities:**
- Resolve run IDs from branch names or numeric IDs
- Fetch run status and job details
- Analyse job conclusions (success/failure/skipped)
- Extract last 15 error lines per failed job
- Match errors against known patterns
- Generate contextual fix suggestions
- Optional integration with log exporter
- Optional auto-fix mode

**Code Structure:**
```bash
check_gh_cli()           # Verify gh is installed and authenticated
resolve_run_id()         # Convert branch/latest to numeric ID
get_run_status()         # Get run metadata and conclusion
analyse_failed_jobs()    # List all failed jobs
get_error_details()      # Extract errors from job logs
suggest_fixes()          # Pattern-based fix suggestions
export_logs_for_run()    # Call exporter if --export
auto_fix_issues()        # Try common fixes if --fix
main()                   # Orchestrate all steps
```

### export-workflow-logs.sh Features

**Capabilities:**
- Export run metadata as JSON
- Export all jobs list
- Extract logs for failed jobs only
- Analyse error patterns
- Generate markdown analysis report
- Calculate error statistics
- Create investigation index

**Output Structure:**
```
run-20692908702-details.json    # Run metadata
run-20692908702-jobs.json       # Jobs summary
run-20692908702-job-*.log       # Individual job logs
run-20692908702-analysis.md     # Comprehensive report
```

---

## Common Workflow Issues (Pre-built Solutions)

### Issue 1: Missing Dependencies
```bash
Error: CMake Error: "FindQt6.cmake" not found
Fix: Add qt6-base-dev, qt6-tools-dev to workflow
Tool Output: Suggests updating workflow YAML
```

### Issue 2: Script Permissions
```bash
Error: ./scripts/build.sh: Permission denied
Fix: git update-index --chmod=+x scripts/*.sh
Tool Output: Detects and suggests --fix flag to auto-correct
```

### Issue 3: Code Formatting
```bash
Error: Code does not conform to required style
Fix: ./scripts/format.sh
Tool Output: Suggests running format script
```

### Issue 4: Build Failures
```bash
Error: Multiple compilation errors
Fix: Depends on error type; tool extracts first 15 error lines
Tool Output: Shows error context and suggests local reproduction
```

### Issue 5: Test Failures
```bash
Error: Test failures detected
Fix: ctest --test-dir build --output-on-failure
Tool Output: Directs to test logs for analysis
```

---

## Integration Points

### Pre-commit Integration
```bash
# In .git/hooks/pre-commit:
if ! ./.github/scripts/debug/investigate-workflow.sh latest --fix; then
  echo "Failed to auto-fix workflow issues"
  exit 1
fi
```

### GitHub Actions Integration
```yaml
- name: Investigate on failure
  if: failure()
  run: |
    ./.github/scripts/debug/investigate-workflow.sh ${{ github.run_id }} --export
    
- name: Upload logs
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: workflow-debug-logs
    path: .github/debug-logs/
```

### CI/CD Pipeline Integration
```bash
# In your build script:
if ! gh run view --log-failed &>/dev/null; then
  ./.github/scripts/debug/investigate-workflow.sh latest
  exit 1
fi
```

---

## Requirements

### System Requirements
- **gh CLI**: GitHub command-line interface (https://cli.github.com)
- **jq**: JSON processor (install via apt/brew)
- **bash**: 4.0+
- **git**: For commit operations

### Installation
```bash
# macOS
brew install gh jq

# Debian/Ubuntu
sudo apt install gh jq

# Verify
gh version
jq --version
bash --version
```

### GitHub Credentials
```bash
# Authenticate gh CLI
gh auth login

# Verify
gh auth status

# Check API access
gh api user
```

---

## Troubleshooting

### "gh CLI not found"
```bash
# Install from: https://cli.github.com
# Or: brew install gh
# Or: sudo apt install gh
```

### "Not authenticated"
```bash
gh auth login
# Follow prompts to authenticate
```

### "jq: command not found"
```bash
# Install JSON processor
brew install jq  # macOS
sudo apt install jq  # Linux
```

### "Permission denied on script"
```bash
# Make scripts executable
chmod +x ./.github/scripts/debug/*.sh
# Or via git
git update-index --chmod=+x ./.github/scripts/debug/*.sh
```

### "Run ID not found"
```bash
# Verify you're in correct branch
git rev-parse --abbrev-ref HEAD

# List recent runs
gh run list --limit 5

# Check authentication
gh auth status
```

---

## Best Practices

### Recommended Workflow

1. **Commit and push** your changes
2. **Monitor the run**: `gh run watch`
3. **If failed**, immediately investigate: `./.github/scripts/debug/investigate-workflow.sh latest`
4. **Apply fixes** based on suggestions
5. **Test locally**: `./scripts/build.sh && ctest`
6. **Commit fixes**: Clear commit message with issue details
7. **Push again** to trigger new run
8. **Verify success**: Monitor new run

### Investigation Checklist

- [ ] Check gh CLI authentication: `gh auth status`
- [ ] Identify latest run: `./.github/scripts/debug/investigate-workflow.sh latest`
- [ ] Note failed jobs and error messages
- [ ] Check if issue is in workflows or code
- [ ] Apply suggested fixes
- [ ] Verify locally: `./scripts/build.sh`
- [ ] Commit with descriptive message
- [ ] Push and monitor new run
- [ ] Document solution in PR if non-obvious

---

## Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| `INVESTIGATION_GUIDE.md` | Complete guide with examples | Detailed learners |
| `QUICK_REFERENCE.md` | Fast lookup commands | Experienced users |
| `SYSTEM_OVERVIEW.md` | This file | Architecture understanding |
| `investigate-workflow.sh` | Interactive investigation tool | Automatic usage |
| `export-workflow-logs.sh` | Log exporter | Detailed analysis |

---

## Example Session

```bash
# 1. Notice CI failed on latest push
$ gh run watch
# Run failed!

# 2. Quick investigation
$ ./.github/scripts/debug/investigate-workflow.sh latest

# Output shows:
# ✗ code-quality / Quality Checks failed
# ⚠ Found error: "CMake Error: FindQt6.cmake not found"
# 💡 Suggestion: Update GitHub Actions workflow to install Qt6

# 3. Fix the issue
$ vim .github/workflows/quality-scan.yml
# Add qt6-base-dev, qt6-tools-dev to dependencies

# 4. Test locally
$ ./scripts/build.sh --build-type Debug
# ✓ Build successful

# 5. Commit and push
$ git add . && git commit -m "fix(ci): Add Qt6 dependencies to quality-scan workflow"
$ git push

# 6. Monitor
$ gh run watch
# ✓ All jobs passed!
```

---

## Future Enhancements

Potential additions:
- [ ] Automatic PR comments with investigation results
- [ ] Slack/email notifications of failures
- [ ] Historical trend analysis
- [ ] Performance metrics extraction
- [ ] Docker image for isolated investigation
- [ ] Web UI for log visualization
- [ ] Integration with issue tracker

---

## Support & Questions

- Check `INVESTIGATION_GUIDE.md` for detailed documentation
- Review `QUICK_REFERENCE.md` for common commands
- See GitHub CLI docs: https://cli.github.com/manual
- GitHub API Reference: https://docs.github.com/en/rest/actions

---

**Version**: 1.0  
**Last Updated**: 2026-01-04  
**Status**: Production Ready
