# Developer Handbook

**Document Version**: 1.0  
**Last Updated**: 2025-01-01  
**Audience**: Developers, Contributors, Software Engineers

## Overview

This handbook documents how developers interact with the Crankshaft CI/CD system. It covers daily workflows, best practices, and how to work effectively with the CI/CD pipelines.

---

## Quick Start: Your First PR

### Step 1: Set Up Development Environment

```bash
# Clone repository
git clone https://github.com/opencardev/crankshaft.git
cd crankshaft

# Verify dependencies
./scripts/install_dev_tools.sh

# Verify build setup
./scripts/build.sh --build-type Debug
```

### Step 2: Create Feature Branch

```bash
# Always create from main
git checkout main
git pull origin main

# Create feature branch with descriptive name
git checkout -b feature/my-feature-name

# Or for bug fixes
git checkout -b fix/issue-description
```

### Step 3: Make Changes & Test Locally

```bash
# Format code
./scripts/format_cpp.sh fix

# Run local quality checks
./scripts/format_cpp.sh check
./scripts/lint_cpp.sh clang-tidy
./scripts/lint_cpp.sh cppcheck

# Run unit tests
./build/test_crankshaft

# Build project
./scripts/build.sh --build-type Debug
```

### Step 4: Commit & Push

```bash
# Commit with clear message
git add .
git commit -m "Feature: Add feature X - closes #123"

# Push to create PR
git push origin feature/my-feature-name
```

### Step 5: Watch Quality Feedback

```bash
# GitHub UI shows quality check progress
# Wait ~5 minutes for quality workflow
# Review comments for any violations
# Fix and push if needed
```

### Step 6: Code Review & Merge

```bash
# Request review from maintainers
# Address review comments
# Once approved:
git push origin feature/my-feature-name

# Maintainer merges PR
# Automatically triggers build and APT publish
```

---

## Development Workflows

### Scenario 1: Quick Code Fix

**Estimated time**: 30 minutes

```bash
# 1. Identify issue
# 2. Create fix branch
git checkout -b fix/crash-in-ui

# 3. Make changes
# Edit files...

# 4. Format & lint locally
./scripts/format_cpp.sh fix
./scripts/lint_cpp.sh clang-tidy

# 5. Test locally
./scripts/test.sh

# 6. Commit
git add .
git commit -m "Fix: Prevent crash in UI initialization - #456"

# 7. Push
git push origin fix/crash-in-ui

# 8. Create PR on GitHub
# 9. Wait for quality feedback (~5 min)
# 10. Merge when approved
```

### Scenario 2: New Feature Development

**Estimated time**: 2-3 days

```bash
# 1. Create planning issue
# GitHub → Issues → New Issue
# Describe feature with acceptance criteria

# 2. Create feature branch
git checkout -b feature/notification-system

# 3. Development cycle (repeat):
#    a. Make small change
#    b. Test locally
#    c. Commit with clear message
#    d. Push periodically

# Example:
# - Day 1: Create core notification service
# - Day 2: Add notification types and queueing
# - Day 3: Add persistence and recovery

# Push commits as you go:
git add .
git commit -m "Feat: Add notification queue service"
git push origin feature/notification-system

# 4. Once done, push final batch
# 5. Create PR with reference to planning issue
# 6. Link commits to issue (#123)

# 7. Code review process
# 8. Address feedback
# 9. Maintainer approves and merges
```

### Scenario 3: Architecture Change

**Estimated time**: 1-2 weeks

```bash
# For large changes, discuss first
# GitHub → Issues → Discussion
# Or Slack/email with maintainers

# 1. Create detailed design document
docs/architecture-changes/my-change.md

# 2. Create RFC (Request for Comments) branch
git checkout -b rfc/my-change

# 3. Implement minimal proof-of-concept
# 4. Push RFC branch
# 5. Open RFC PR for early feedback

# 6. Iterate based on feedback
# 7. When consensus reached:
#    - Update RFC with decisions
#    - Commit to design documentation
#    - Create implementation PR

# 8. Implementation PR links to RFC
# 9. Faster review since design approved
```

---

## Common Tasks

### Task: Create Pull Request

```bash
# 1. Push branch
git push origin feature/my-feature

# 2. Go to GitHub repository
# https://github.com/opencardev/crankshaft

# 3. Click "Compare & pull request"
# 4. Fill in PR title and description
# 5. Link related issues: "Fixes #123"
# 6. Click "Create pull request"

# Template for PR description:
"""
## Description
Brief description of what this PR does

## Motivation and Context
Why is this change needed?

## Testing
How has this been tested?
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guide
- [ ] Self-review completed
- [ ] Comments added for complex sections
- [ ] Documentation updated
"""
```

### Task: Fix Quality Violations

```bash
# 1. Read quality report in PR comment
# 2. Find violation details
# 3. Fix locally

# Example violations:

# VIOLATION: Use nullptr instead of NULL
# FIX:
sed -i 's/NULL/nullptr/g' src/my-file.cpp

# VIOLATION: Unused parameter
# FIX:
void myFunc([[maybe_unused]] int unused) { }

# VIOLATION: Copy instead of reference
# FIX:
// Wrong
void process(MyObject obj)

// Right
void process(const MyObject& obj)

# 4. Verify fix
./scripts/format_cpp.sh check

# 5. Commit and push
git add .
git commit -m "Fix: Address quality violations"
git push origin feature/my-feature
```

### Task: Run Tests Before Pushing

```bash
# Build
./scripts/build.sh --build-type Debug

# Run all tests
ctest --test-dir build --output-on-failure

# Or run specific test
./build/bin/test_module_name

# Run with verbose output
ctest --test-dir build --verbose

# Check coverage
# (if enabled in build)
./build/test_coverage.html
```

### Task: Debug Build Failure

```bash
# 1. Check what's in build directory
ls -la build/

# 2. Clean and rebuild
rm -rf build
./scripts/build.sh --build-type Debug

# 3. Check error messages
# Look for first error, not last
# Usually first error causes subsequent ones

# 4. Fix source issue
# Edit problematic file

# 5. Rebuild
./scripts/build.sh --build-type Debug

# 6. If still failing
# Check compiler output more carefully
# Search for "error:" keyword
```

### Task: Test on All Architectures

```bash
# Default: feature branches build amd64 only
# To test on all architectures:

# 1. Go to GitHub Actions
# https://github.com/opencardev/crankshaft/actions

# 2. Click "Platform Builds"
# 3. Click "Run workflow"
# 4. Select branch (your feature branch)
# 5. In "Architectures", select: amd64, arm64, armhf
# 6. Click "Run workflow"

# 7. Wait ~25 minutes for all builds
# 8. Download artifacts to test locally

# Or via GitHub CLI
gh workflow run build.yml \
  -f branch=feature/my-feature \
  -f architectures='amd64,arm64,armhf'
```

### Task: Prepare for Release

```bash
# Before creating release, verify:

# 1. All tests pass
ctest --test-dir build --output-on-failure

# 2. Code follows style guide
./scripts/format_cpp.sh check
./scripts/lint_cpp.sh clang-tidy

# 3. Version is updated
# Edit: include/crankshaft/version.h
# Update: CMakeLists.txt
# Update: docs/CHANGELOG.md

# 4. Commit version bump
git add .
git commit -m "Chore: Bump version to v1.2.3"
git push origin main

# 5. Wait for build to complete (~25 min)
# 6. Create annotated tag
git tag -a v1.2.3 -m "Release v1.2.3: Description of changes"

# 7. Push tag (triggers release workflow)
git push origin v1.2.3

# 8. Release created automatically
# Verify on: https://github.com/opencardev/crankshaft/releases
```

---

## Commit Message Standards

### Format

```
Type: Scope - Description (closes #123)

Optional body explaining why, not what.
Keep to 72 characters per line.

Co-authored-by: Name <email@example.com>
```

### Type

- **Feat**: New feature
- **Fix**: Bug fix
- **Docs**: Documentation changes
- **Style**: Code formatting, no logic change
- **Refactor**: Code reorganisation, no logic change
- **Test**: Adding or updating tests
- **Chore**: Dependency updates, tooling, maintenance
- **Perf**: Performance improvement

### Examples

```bash
# Good
git commit -m "Feat: Add notification queue system

Implement asynchronous notification processing with:
- Queue-based message handling
- Persistence for recovery
- Retry logic for failed sends

Improves responsiveness during bulk notifications.
Closes #123"

# Good
git commit -m "Fix: Memory leak in event listener cleanup"

# Good
git commit -m "Docs: Add notification system architecture guide"

# Bad (too vague)
git commit -m "Update code"

# Bad (too long in one line)
git commit -m "Feat: Add notification queue system with async processing and persistence"
```

---

## Code Review Checklist

Before requesting review, verify:

- [ ] Code builds without errors
- [ ] All tests pass
- [ ] Code formatted correctly
- [ ] Linter checks pass
- [ ] No debug logging left
- [ ] Comments explain "why", not "what"
- [ ] Variable names are descriptive
- [ ] No unnecessary complexity
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] PR description explains context

---

## Working With Different Branches

### Main Branch (`main`)

- **Purpose**: Production-ready code
- **Build type**: All architectures
- **APT publish**: Automatic
- **Merge strategy**: PR with review required
- **Release**: Can tag from here

```bash
# Never push directly to main
# Always use PR workflow
```

### Feature Branches (`feature/*`)

- **Purpose**: Development branches
- **Build type**: amd64 only (fast feedback)
- **APT publish**: No
- **Merge strategy**: PR → squash merge
- **Release**: Not released from here

```bash
# Create feature branch
git checkout -b feature/descriptive-name

# Work on feature
# Multiple commits OK here

# When done, push and create PR
git push origin feature/descriptive-name
```

### Release Branches (`release/*`)

- **Purpose**: Stabilization before release
- **Build type**: All architectures
- **APT publish**: To nightly channel
- **Merge strategy**: PR → merge commit

```bash
# Only maintainers create release branches
# From main when ready to stabilize

git checkout -b release/v1.2.x

# Hot fixes go here
# When stable, merge back to main and tag
```

---

## Debugging Tips

### Problem: Build succeeds locally but fails on CI

**Cause**: Different compiler version, missing dependency, or platform-specific issue

**Solution**:
```bash
# 1. Check CI build log
#    Actions → [Run] → [Job]

# 2. Replicate build environment locally
#    Docker container with same dependencies

# 3. Or trigger build on feature branch
#    Actions → Platform Builds → Run workflow
#    Select your branch, same architecture as CI
```

### Problem: Tests pass locally but fail on CI

**Cause**: Race condition, timing issue, or environmental difference

**Solution**:
```bash
# 1. Run tests multiple times
for i in {1..5}; do
  ./build/test_module
  if [ $? -ne 0 ]; then
    echo "Failed on iteration $i"
    break
  fi
done

# 2. Run with verbose output
ctest --test-dir build --verbose

# 3. Check for race conditions
# Use thread sanitizer if enabled
```

### Problem: Quality checks fail for code that looks fine

**Cause**: Style formatting or static analysis tool configuration

**Solution**:
```bash
# 1. Read quality report carefully
#    Check line numbers and error messages

# 2. Run formatter
./scripts/format_cpp.sh fix

# 3. Run static analysis
./scripts/lint_cpp.sh clang-tidy

# 4. Check tool configuration
cat .clang-tidy
cat .clang-format

# 5. Some violations are warnings only
#    Not blocking, but good to fix anyway
```

---

## Performance Optimization

### Speeding Up Local Builds

```bash
# Use parallel build
./scripts/build.sh --build-type Debug -j8

# Or build specific component
./scripts/build.sh --component core --build-type Debug

# Clean build (last resort)
rm -rf build
./scripts/build.sh --build-type Debug
```

### Incremental Development

```bash
# For rapid iteration:

# 1. Build once
./scripts/build.sh --build-type Debug

# 2. Edit code
# vim src/myfile.cpp

# 3. Rebuild just changed files
cd build
make core  # Rebuild just core component

# 4. Run tests for that component
ctest -R core --test-dir build

# 5. Full build before committing
cd ..
./scripts/build.sh --build-type Debug
```

### Testing Specific Changes

```bash
# If you only changed UI code
./scripts/build.sh --component ui --build-type Debug

# If you only changed core
./scripts/build.sh --component core --build-type Debug

# Run tests for that component
ctest -R core --test-dir build -VV
```

---

## Communication with Maintainers

### Getting Help

- **Documentation**: Check `docs/ci-cd/` first
- **GitHub Issues**: Search for similar issues
- **GitHub Discussions**: Ask questions publicly
- **Code Review**: Use PR comments for context-specific questions
- **Email/Chat**: For urgent issues or sensitive topics

### Reporting Issues

```bash
# Include relevant information
gh issue create --repo opencardev/crankshaft \
  --title "Build fails on ARM64" \
  --body "
## Environment
- OS: Ubuntu 22.04 (WSL)
- Git SHA: $(git rev-parse HEAD)

## Steps to Reproduce
1. Clone repository
2. Checkout branch feature/my-feature
3. Run ./scripts/build.sh

## Error
[Paste full error message]

## Expected
Build should complete successfully

## Actual
Build fails with linker error
"
```

---

## Continuous Learning

### Resources

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **C++ Best Practices**: https://isocpp.github.io/CppCoreGuidelines
- **Project Architecture**: `docs/architecture/`
- **CI/CD Architecture**: `docs/ci-cd/architecture-decisions.md`

### Regular Tasks

```bash
# Weekly
git pull origin main  # Stay up to date
./scripts/build.sh    # Verify build still works

# Monthly
# Review merged PRs
# Learn from code review feedback
# Check for deprecation notices

# Quarterly
# Contribute to documentation
# Improve own code quality
# Mentor new contributors
```

---

## Common Mistakes to Avoid

1. **Pushing directly to main**
   - Always use PR workflow
   - Allows for review and quality checks

2. **Large commits with mixed changes**
   - Keep commits focused
   - One feature or fix per commit
   - Makes reviewing and reverting easier

3. **Ignoring quality warnings**
   - All violations will block merge
   - Fix them proactively
   - Better to fix locally than in CI

4. **Not testing locally before pushing**
   - Run tests and lint locally
   - Catch issues early
   - Saves CI resources

5. **Outdated feature branches**
   - Rebase on main regularly
   - Prevents merge conflicts
   - Ensures you see latest changes

   ```bash
   git fetch origin
   git rebase origin/main feature/my-feature
   ```

6. **Creating PR without description**
   - Provide context for reviewers
   - Link related issues
   - Explain "why" not just "what"

7. **Committing secrets or credentials**
   - Check `.gitignore` first
   - Never commit API keys, passwords
   - Use GitHub secrets for sensitive data

---

## Getting Started Checklist

- [ ] Clone repository
- [ ] Run `./scripts/install_dev_tools.sh`
- [ ] Build successfully: `./scripts/build.sh --build-type Debug`
- [ ] Run tests: `ctest --test-dir build --output-on-failure`
- [ ] Format code: `./scripts/format_cpp.sh fix`
- [ ] Create feature branch
- [ ] Make small change
- [ ] Commit and push
- [ ] Create pull request
- [ ] Review quality feedback
- [ ] Fix any issues
- [ ] Wait for approval
- [ ] Celebrate your first contribution! 🎉

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-01 | Initial version |

