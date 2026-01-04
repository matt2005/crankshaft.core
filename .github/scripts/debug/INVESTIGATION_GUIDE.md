# Workflow Investigation and Resolution Guide

## Overview

This guide explains how to use the workflow investigation and log exporting tools to diagnose and resolve GitHub Actions failures in the Crankshaft project.

## Tools Available

### 1. **investigate-workflow.sh** - Interactive Investigation Tool

The primary tool for diagnosing workflow failures with automated analysis and suggestions.

#### Quick Start

```bash
# Investigate latest workflow run on current branch
./.github/scripts/debug/investigate-workflow.sh

# Investigate specific run ID
./.github/scripts/debug/investigate-workflow.sh 20692908702

# Get verbose output with detailed error information
./.github/scripts/debug/investigate-workflow.sh latest --verbose

# Export complete logs and analysis report
./.github/scripts/debug/investigate-workflow.sh latest --export

# Auto-fix common issues (scripts, formatting, etc)
./.github/scripts/debug/investigate-workflow.sh latest --fix
```

#### Features

- **Automatic Run Resolution**: Identify latest run on current branch or use specific run ID
- **Status Analysis**: Display run status, conclusion, and timing information
- **Failed Job Detection**: List all failed or incomplete jobs with details
- **Error Extraction**: Extract error messages from job logs for quick analysis
- **Fix Suggestions**: Automated suggestions for common issues:
  - Code formatting problems
  - Build/CMake errors
  - Test failures
  - Permission issues
  - Missing dependencies
- **Log Export**: Optional integration with log exporter for detailed analysis
- **Auto-Fix Mode**: Attempt to automatically fix common issues like script permissions

#### Output Example

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Workflow Investigation Tool
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Checking GitHub CLI
✓ GitHub CLI found
✓ GitHub CLI authenticated

▶ Resolving Run ID
✓ Run ID: 20692908702

▶ Workflow Run Status
✓ Run completed successfully

▶ Analysing Failed Jobs
⚠ Found 1 failed job(s)
  Job: code-quality / Quality Checks (ID: 59403624492)
    Status: completed, Conclusion: failure
    URL: https://github.com/opencardev/crankshaft.core/actions/runs/20692908702/job/59403624492

▶ Extracting Error Information
ℹ Getting logs for: code-quality / Quality Checks
⚠ Error messages from: code-quality / Quality Checks
    CMake Error at CMakeLists.txt:105 (find_package):
    By not providing "FindQt6.cmake" in CMAKE_MODULE_PATH...
```

---

### 2. **export-workflow-logs.sh** - Comprehensive Log Exporter

Exports complete workflow run logs and generates detailed analysis reports.

#### Quick Start

```bash
# Export latest run on current branch
./.github/scripts/debug/export-workflow-logs.sh latest

# Export specific run ID
./.github/scripts/debug/export-workflow-logs.sh 20692908702

# Export latest run from specific branch
./.github/scripts/debug/export-workflow-logs.sh 003-github-actions-cicd

# Custom output directory
./.github/scripts/debug/export-workflow-logs.sh latest ./my-debug-logs
```

#### Output Structure

```
.github/debug-logs/
├── run-20692908702-details.json        # Run metadata
├── run-20692908702-jobs.json           # Jobs status and details
├── run-20692908702-job-59403624492-*.log  # Detailed job logs
├── run-20692908702-analysis.md         # Comprehensive analysis report
└── [more job logs...]
```

#### Generated Reports

The exporter automatically generates a markdown analysis report with:
- Run overview (status, branch, commit)
- Job summary table (passed/failed/skipped counts)
- Failed job details with links
- Error pattern analysis
- Quick links to GitHub Actions UI

#### Analysis Report Example

```markdown
# Workflow Run Analysis Report

**Run ID:** `20692908702`
**Generated:** 2026-01-04T12:30:00Z

## Overview
- **Status:** `completed`
- **Conclusion:** `failure`

## Job Summary
| Status | Count |
|--------|-------|
| ✓ Passed | 1 |
| ✗ Failed | 1 |
| ⊘ Skipped | 4 |
| **Total** | **6** |

## Failed Jobs Details
- code-quality / Quality Checks (ID: 59403624492)
  - Status: completed
  - Conclusion: failure
  - Logs: https://github.com/opencardev/crankshaft.core/...
```

---

## Common Workflow Issues and Resolution

### 1. **Missing Qt6 Dependency**

**Error Message:**
```
CMake Error at CMakeLists.txt:105 (find_package):
  By not providing "FindQt6.cmake" in CMAKE_MODULE_PATH this project has
  asked CMake to find a package configuration file provided by "Qt6", but
  CMake could not find one.
```

**Root Cause:** The GitHub Actions runner doesn't have Qt6 development packages installed.

**Resolution:**
```bash
# Investigate
./.github/scripts/debug/investigate-workflow.sh latest

# The tool will suggest:
# 1. Update GitHub Actions workflow to install Qt6
# 2. Add build dependencies: qt6-base-dev, qt6-tools-dev, etc

# Fix the workflow file (.github/workflows/quality-scan.yml):
# Add to "Install dependencies" step:
#   qt6-base-dev \
#   qt6-declarative-dev \
#   qt6-tools-dev \
#   ...
```

### 2. **Permission Denied on Scripts**

**Error Message:**
```
./scripts/build.sh: Permission denied
```

**Root Cause:** Shell scripts don't have execute bit set in git index.

**Resolution:**
```bash
# Investigate and auto-fix
./.github/scripts/debug/investigate-workflow.sh latest --fix

# Or manually:
git update-index --chmod=+x scripts/*.sh
git update-index --chmod=+x .github/scripts/**/*.sh
git commit -m "fix: Make scripts executable"
git push
```

### 3. **Code Formatting Issues**

**Error Message:**
```
Code does not conform to the required style.
```

**Resolution:**
```bash
# Investigate
./.github/scripts/debug/investigate-workflow.sh latest

# Fix locally
./scripts/format.sh

# Verify
./scripts/format_cpp.sh check

# Commit and push
git add .
git commit -m "style: Format code"
git push
```

### 4. **Build Failures**

**Investigation Steps:**
```bash
# Get detailed logs
./.github/scripts/debug/investigate-workflow.sh latest --export

# Review exported logs
cat .github/debug-logs/run-*-job-*-build.log | grep -A5 "error"

# Try to reproduce locally
./scripts/build.sh --build-type Debug

# Check dependencies
./scripts/build.sh --install-deps --component all
```

### 5. **Test Failures**

**Investigation:**
```bash
# Get test logs
./.github/scripts/debug/investigate-workflow.sh latest --export

# Review test failures
cat .github/debug-logs/run-*-job-*-test.log

# Run tests locally
ctest --test-dir build --output-on-failure

# Run specific test
ctest --test-dir build -R test_name -V
```

---

## Workflow with gh CLI

### Using gh CLI Directly

If you prefer to use gh CLI directly instead of the scripts:

```bash
# List runs
gh run list --branch 003-github-actions-cicd --limit 5

# View run details
gh run view 20692908702

# View run as JSON
gh run view 20692908702 --json status,conclusion,jobs

# Watch run in real-time
gh run watch 20692908702

# Rerun failed jobs
gh run rerun 20692908702

# View failed job logs
gh run view 20692908702 --log-failed

# Cancel run
gh run cancel 20692908702
```

### API Queries with jq

```bash
# Get all failed jobs
gh api repos/{owner}/{repo}/actions/runs/20692908702/jobs \
  --jq '.jobs[] | select(.conclusion == "failure")'

# Count jobs by status
gh api repos/{owner}/{repo}/actions/runs/20692908702/jobs \
  --jq '[.jobs[] | .conclusion] | group_by(.) | map({(.[0]): length})'

# Extract error patterns from logs
gh api repos/{owner}/{repo}/actions/jobs/59403624492/logs | grep -i error
```

---

## Automated Investigation Workflow

### Recommended Process

1. **Quick Investigation**
   ```bash
   ./.github/scripts/debug/investigate-workflow.sh latest
   ```
   - See failure summary
   - Get error messages and suggestions

2. **Detailed Analysis** (if needed)
   ```bash
   ./.github/scripts/debug/investigate-workflow.sh latest --export
   ```
   - Export all logs
   - Generate comprehensive report
   - Review `.github/debug-logs/run-*-analysis.md`

3. **Local Reproduction**
   ```bash
   # Apply any obvious fixes first
   # Then test locally
   ./scripts/build.sh --build-type Debug
   ctest --test-dir build --output-on-failure
   ```

4. **Fix and Verify**
   ```bash
   # Make necessary changes
   # Commit with clear message
   git add .
   git commit -m "fix(ci): [description of fix]"
   
   # Push to trigger new run
   git push
   ```

5. **Monitor New Run**
   ```bash
   # Watch new run
   gh run watch
   
   # Or investigate when complete
   ./.github/scripts/debug/investigate-workflow.sh latest
   ```

---

## Debugging Tips

### Enable Verbose Output

```bash
# Verbose investigation (shows full command output)
./.github/scripts/debug/investigate-workflow.sh latest --verbose

# Verbose gh cli operations
export GH_DEBUG=api
./.github/scripts/debug/investigate-workflow.sh latest
```

### Check GitHub CLI Status

```bash
# Verify authentication
gh auth status

# Show current configuration
gh config get

# Test API access
gh api user
```

### Review Workflow Files

```bash
# List all workflows
gh workflow list

# View specific workflow
gh workflow view ci.yml

# Check workflow status
gh run list --workflow=ci.yml --limit 10
```

---

## Environment Variables

### Setting Environment for Investigation Scripts

```bash
# Use custom GitHub repository
export GH_REPO=owner/repo
./.github/scripts/debug/investigate-workflow.sh latest

# Enable verbose gh cli logging
export GH_DEBUG=api
./.github/scripts/debug/investigate-workflow.sh latest --verbose

# Custom output directory
./.github/scripts/debug/export-workflow-logs.sh latest ~/my-logs
```

---

## Troubleshooting the Investigation Tools

### gh CLI Not Found

```bash
# Install gh cli
# macOS
brew install gh

# Debian/Ubuntu
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo apt-key add -
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Verify installation
gh version
```

### gh CLI Not Authenticated

```bash
# Login
gh auth login

# Select GitHub.com
# Select HTTPS
# Authenticate with browser
```

### Scripts Not Executable

```bash
# Make investigation scripts executable
chmod +x ./.github/scripts/debug/investigate-workflow.sh
chmod +x ./.github/scripts/debug/export-workflow-logs.sh
```

### Missing jq (JSON Processor)

```bash
# Install jq
# macOS
brew install jq

# Debian/Ubuntu
sudo apt install jq

# Verify
jq --version
```

---

## Integration with CI/CD

### Running Investigation in GitHub Actions

You can add a workflow step to automatically run investigation on failure:

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

## References

- [GitHub CLI Documentation](https://cli.github.com/manual)
- [GitHub Actions API Reference](https://docs.github.com/en/rest/actions)
- [jq Manual](https://stedolan.github.io/jq/)
- [Crankshaft CI/CD Documentation](../ci-cd/)

