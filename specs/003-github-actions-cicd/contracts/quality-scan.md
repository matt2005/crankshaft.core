# Workflow Contract: Quality Scan

**Purpose**: Reusable GitHub Actions workflow for comprehensive C++ code quality checks.

**Specification Version**: 1.0.0  
**Feature**: 003-github-actions-cicd  
**Task**: T009  
**Status**: Production (Phase 2)

---

## Workflow Identification

- **Workflow Name**: `Quality Scan (Reusable)`
- **Workflow File**: `.github/workflows/quality-scan.yml`
- **Workflow Type**: Reusable (called via `workflow_call`)
- **Primary Purpose**: Detect code quality issues before code reaches main branch

---

## Inputs

### `runner` (Optional)

- **Type**: String
- **Default**: `ubuntu-latest`
- **Description**: GitHub Actions runner label to execute on
- **Valid Values**: Any valid GitHub-hosted or self-hosted runner label
- **Usage**: Allows callers to override default runner (e.g., for custom configurations)

### `build-type` (Optional)

- **Type**: String
- **Default**: `Debug`
- **Valid Values**: `Debug`, `Release`
- **Description**: CMake build configuration for compilation
- **Usage**: Passes to `scripts/build.sh --build-type` parameter

### `json-output` (Optional)

- **Type**: Boolean
- **Default**: `false`
- **Description**: Format quality check results as JSON (machine-readable)
- **Usage**: When `true`, passes `--json` flag to all quality scripts

---

## Outputs

### `quality-report`

- **Type**: String (JSON)
- **Format**: JSON object with timestamp, check results, and outcome status
- **When Available**: Only when `json-output` input is `true`
- **Purpose**: Machine-readable quality report for downstream actions or status checks

**Example Output**:
```json
{
  "timestamp": "2025-01-03T12:34:56Z",
  "checks": {
    "format": "success",
    "tidy": "success",
    "cppcheck": "success",
    "license": "success"
  }
}
```

---

## Quality Checks Performed

### 1. Code Formatting Check

- **Tool**: `clang-format`
- **Script**: `.github/scripts/quality/check-format.sh`
- **What it checks**:
  - Consistent indentation (2 spaces for C++)
  - Line length and spacing compliance
  - Bracket and brace alignment
  - Operator spacing
- **Requirement**: All files must match `.clang-format` style rules
- **Failure Impact**: Blocks merge (CR-003 compliance)

### 2. Static Analysis (clang-tidy)

- **Tool**: `clang-tidy`
- **Script**: `.github/scripts/quality/check-tidy.sh`
- **What it checks**:
  - Code modernisation opportunities
  - Performance issues
  - Potential bugs and undefined behaviour
  - C++ standard compliance
- **Requirement**: No critical issues (warnings allowed)
- **Failure Impact**: Reported but doesn't block merge (informational)

### 3. Code Analysis (cppcheck)

- **Tool**: `cppcheck`
- **Script**: `.github/scripts/quality/check-cppcheck.sh`
- **What it checks**:
  - Memory errors
  - Logic errors
  - Dead code detection
  - Resource management issues
- **Requirement**: No critical errors
- **Failure Impact**: Reported but doesn't block merge (informational)

### 4. License Header Verification

- **Script**: `scripts/check_license_headers.sh` (extended)
- **What it checks**:
  - GPL3 license header presence in all source files
  - Correct copyright attribution
- **Requirement**: All .cpp, .hpp, .h, .cc files must have headers
- **Failure Impact**: Blocks merge (legal compliance, CR-001)

---

## Execution Flow

```
1. Checkout code
   ↓
2. Install quality tools (clang-format, clang-tidy, cppcheck)
   ↓
3. Build project (Debug or Release, configurable)
   ↓
4. Run 4 quality checks in sequence:
   ├─ Formatting (clang-format)
   ├─ Static analysis (clang-tidy)
   ├─ Code analysis (cppcheck)
   └─ License headers verification
   ↓
5. Generate summary in GitHub Step Summary
   ↓
6. Fail if any blocking check failed (format or license)
```

**Execution Time**: ~3-5 minutes (depends on codebase size and runner performance)

---

## Integration Points

### Used By

1. **ci.yml** (Feature branch workflow)
   - Called for pull requests to verify quality before review
   - Blocks merge if formatting or license checks fail

2. **cd.yml** (Continuous deployment workflow)
   - Called for main branch commits as sanity check
   - Informational only (doesn't block merge)

### Reusability

This workflow is **reusable** - it can be called from other workflows:

```yaml
jobs:
  quality:
    uses: opencardev/crankshaft.core/.github/workflows/quality-scan.yml@main
    with:
      runner: ubuntu-latest
      build-type: Debug
      json-output: false
```

---

## Output Formats

### Console Output (Default)

When `json-output: false`:

```
ℹ Checking code formatting with clang-format...
✓ clang-format ready (version: clang-format version 12.0.0)
✓ All files properly formatted
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Formatting Check Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total files:      42
Formatted:        0
Errors:           0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### JSON Output

When `json-output: true`:

Each script outputs JSON, which is compiled into workflow output via `steps.compile.outputs.report`.

---

## Success Criteria

### Workflow Passes When

- ✅ Formatting check reports no changes needed
- ✅ License header check finds all headers present
- ⚠️ Clang-tidy warnings (non-blocking)
- ⚠️ Cppcheck findings (non-blocking)

### Workflow Fails When

- ❌ Formatting check finds files needing changes
- ❌ License header check finds missing headers
- ❌ Build fails (missing dependencies, compilation errors)

---

## Troubleshooting

### `clang-format not found`

**Cause**: Quality tools not installed on runner
**Solution**: Install step automatically handles this, but if manual:
```bash
sudo apt-get install clang-format clang-tools cppcheck
```

### `compile_commands.json not found`

**Cause**: Project not built before running tidy check
**Solution**: Automatic in workflow, but if manual:
```bash
./scripts/build.sh --build-type Debug
```

### Workflow succeeds but code doesn't pass local checks

**Cause**: Different tool versions between runner and local machine
**Solution**: Update local tools:
```bash
apt-get install --upgrade clang-format clang-tidy cppcheck
```

---

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Install tools | 30s | Cached on runner |
| Build project | 2m | Cached incremental builds |
| Format check | 15s | Quick scan only |
| Clang-tidy | 2m 30s | Requires compile_commands.json |
| Cppcheck | 1m | Incremental analysis |
| License check | 5s | File scanning only |
| **Total** | **~6-7m** | First run; faster on subsequent runs |

---

## Dependencies

### External

- Ubuntu runner with build tools installed
- CMake >= 3.25
- GCC 12+ or Clang 14+
- Git repository access

### Internal

- `.clang-format` configuration file (project root)
- `scripts/build.sh` (build orchestration)
- `.github/scripts/quality/check-*.sh` (quality checking scripts)
- `CMakeLists.txt` (build configuration)

---

## Related Documentation

- [Developer Handbook](../../docs/ci-cd/developer-handbook.md) - How developers interact with quality feedback
- [Quality Checks Guide](../../docs/ci-cd/quality-checks.md) - Detailed guide to each check
- [Build Flags Verification](../../.github/BUILD_FLAGS_VERIFICATION.md) - build.sh compatibility
- [Project Constitution](../../specs/003-github-actions-cicd/constitution.md) - Governance and principles

---

## Change Log

**Version 1.0.0** (2025-01-03)
- ✅ Initial specification from Feature 003 Phase 2
- ✅ Four quality checks defined and integrated
- ✅ Reusable workflow contract specified
- ✅ Supports both human and machine-readable output
