# CI Workflow Boolean Input Fix

## Issue Summary

**Date**: 2026-01-31  
**Severity**: High (Build blocking)  
**Component**: GitHub Actions CI Workflow  
**File**: `.github/workflows/ci.yml`

## Problem Description

The CI workflow on the `develop` branch was consistently failing with the following error:

```
evaluate reusable workflow inputs: .github/workflows/ci.yml (Line: 167, Col: 20): Unexpected value 'false'
```

### Root Cause

Line 167 of `ci.yml` contained the expression:
```yaml
build-aasdk: ${{ github.event.inputs.build-aasdk || false }}
```

This expression had the following behaviour:
- When triggered via `workflow_dispatch`: Returns string 'true' or 'false'
- When triggered via `push` or `pull_request`: `github.event.inputs.build-aasdk` is undefined, causing `|| false` to return the boolean value `false`

GitHub Actions does not accept a raw boolean value when passing parameters to reusable workflows that expect boolean inputs. The value must be properly evaluated in an expression context.

## Solution

Changed line 167 to:
```yaml
build-aasdk: ${{ github.event.inputs.build-aasdk == 'true' }}
```

This expression ensures:
- Always returns a boolean value (`true` or `false`)
- Returns `false` when `github.event.inputs.build-aasdk` is undefined or empty
- Returns `true` only when explicitly set to string 'true'
- Properly evaluates in all trigger contexts (push, PR, workflow_dispatch)

## Technical Details

### Expression Evaluation Differences

**Before (Broken)**:
- `undefined || false` → boolean `false` (GitHub Actions error)
- `'false' || false` → string `'false'` (would work but inconsistent)
- `'true' || false` → string `'true'` (would work but inconsistent)

**After (Fixed)**:
- `undefined == 'true'` → boolean `false` ✓
- `'false' == 'true'` → boolean `false` ✓
- `'true' == 'true'` → boolean `true` ✓

## Testing

1. ✓ YAML syntax validation passed
2. ✓ Code review completed with no issues
3. ✓ CodeQL security scan passed with 0 alerts
4. ✓ Minimal change with single line modification

## Impact

- **Before**: CI workflow failed on every push/PR to develop branch
- **After**: CI workflow can successfully evaluate inputs and proceed with builds
- **Risk**: Minimal - single line change with well-defined behaviour
- **Compatibility**: No breaking changes to existing workflow triggers

## Verification Steps

To verify the fix:
1. Trigger CI via push to develop branch (build-aasdk should default to false)
2. Trigger CI via workflow_dispatch with build-aasdk=false (should work)
3. Trigger CI via workflow_dispatch with build-aasdk=true (should work)

## Related Files

- `.github/workflows/ci.yml` (modified)
- `.github/workflows/build.yml` (references the boolean input)

## Security Summary

No security vulnerabilities were introduced or discovered during this fix. CodeQL analysis found 0 alerts.

## References

- GitHub Actions Workflow Syntax: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- Reusable Workflows: https://docs.github.com/en/actions/using-workflows/reusing-workflows
- Expression Syntax: https://docs.github.com/en/actions/learn-github-actions/expressions
