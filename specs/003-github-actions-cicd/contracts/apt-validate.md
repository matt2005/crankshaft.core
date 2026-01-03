# Workflow Contract: APT Package Validation

**Purpose**: Reusable GitHub Actions workflow for validating DEB packages before publishing to APT repository.

**Specification Version**: 1.0.0  
**Feature**: 003-github-actions-cicd  
**Task**: T031  
**Status**: Production (Phase 5)

---

## Workflow Identification

- **Workflow Name**: `APT Validation (Reusable)`
- **Workflow File**: `.github/workflows/apt-validate.yml`
- **Workflow Type**: Reusable (called via `workflow_call`)
- **Primary Purpose**: Ensure DEB packages are valid before publishing

---

## Inputs

### `artifacts-path` (Required)

- **Type**: String
- **Description**: Path or artifact name containing DEB packages to validate
- **Valid Values**: Local filesystem path or GitHub Actions artifact name
- **Usage**: Source of DEB files for validation

### `json-output` (Optional)

- **Type**: Boolean
- **Default**: `false`
- **Description**: Format validation results as JSON (machine-readable)
- **Usage**: When `true`, produces machine-readable output for downstream workflows

---

## Outputs

### `validation-report`

- **Type**: String (JSON)
- **Format**: JSON object with validation details
- **When Available**: Always available
- **Purpose**: Machine-readable validation results for downstream actions

**Example Output**:
```json
{
  "validation_time": "2025-01-03T12:34:56Z",
  "total_packages": 3,
  "valid_packages": 3,
  "invalid_packages": 0,
  "total_warnings": 0,
  "results": [
    {
      "file": "crankshaft-core_1.0.0_amd64.deb",
      "valid": true,
      "errors": 0,
      "warnings": 0
    },
    {
      "file": "crankshaft-core_1.0.0_arm64.deb",
      "valid": true,
      "errors": 0,
      "warnings": 0
    }
  ]
}
```

---

## Validation Checks Performed

### 1. DEB Format Validation

- **Tool**: `ar` (DEB archive utility)
- **What it checks**:
  - Valid DEB archive structure
  - Required metadata files present
  - Archive integrity
- **Requirement**: All DEBs must have valid format
- **Failure Impact**: Blocks APT publishing

### 2. Package Quality (Lintian)

- **Tool**: `lintian`
- **What it checks**:
  - Policy compliance
  - Package metadata correctness
  - Common errors and warnings
- **Requirement**: No critical errors (warnings allowed)
- **Failure Impact**: Blocks APT publishing if errors detected
- **Note**: Skipped gracefully if lintian not available

### 3. File Integrity

- **What it checks**:
  - File readability
  - Non-zero file size
  - Correct DEB magic number
- **Requirement**: All packages must be readable and complete
- **Failure Impact**: Blocks APT publishing

---

## Failure Modes and Recovery

### Validation Failure

**When**: Any DEB fails validation checks  
**Response**: 
1. Workflow exits with non-zero status
2. Validation report output available for inspection
3. APT publish workflow should not be triggered
4. Developer notified to fix DEB package issues

**Recovery**:
1. Fix DEB package errors
2. Rebuild packages
3. Resubmit for validation

---

## Success Criteria

- All DEB packages successfully validate
- No critical lintian errors (if available)
- All packages readable and complete
- Validation completes within 5 minutes

---

## Integration Points

### Upstream Dependencies

- **Build Workflow**: Must provide DEB packages as artifacts
- **Artifact Format**: Individual `.deb` files in named artifact

### Downstream Dependencies

- **APT Publish Workflow**: Triggered only if validation succeeds
- **Artifact Passing**: Validation report passed to apt-publish.yml

---

## Implementation Notes

### Architecture Support

- Validates DEBs for multiple architectures (amd64, arm64, armhf)
- Can validate mixed-architecture sets in single workflow run

### Performance Targets

- Per-package validation: < 10 seconds
- Total validation (3 packages): < 2 minutes

### Output Format

- **Human-Readable**: Clear success/failure messages
- **Machine-Readable**: JSON format for automation

---

## Example Usage

### Called from APT Publish Workflow

```yaml
- name: Validate Packages
  uses: ./.github/workflows/apt-validate.yml
  with:
    artifacts-path: ./build-artifacts
    json-output: true

- name: Check Validation Results
  run: |
    if ! jq -e '.valid_packages == .total_packages' validation-report.json > /dev/null; then
      echo "Validation failed"
      exit 1
    fi
```

---

## Future Enhancements

- Container image validation
- Dependency resolution checking
- Signature verification for pre-signed DEBs
- Integration with Debian/Ubuntu QA tools

