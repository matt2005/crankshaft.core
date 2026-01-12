#!/bin/bash
# Project: Crankshaft
# This file is part of Crankshaft project.
# Copyright (C) 2025 OpenCarDev Team
#
#  Crankshaft is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Crankshaft is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Crankshaft. If not, see <http://www.gnu.org/licenses/>.

#
# Quality Check: Static Analysis (clang-tidy)
# Purpose: Detect code issues, modernisations, and potential bugs
#
# Usage:
#   ./check-tidy.sh                      # Check and report issues
#   ./check-tidy.sh --fix                # Fix issues in-place (where possible)
#   ./check-tidy.sh --json               # Output results as JSON
#   ./check-tidy.sh --dry-run            # Show fixes that would be applied, don't modify files
#   ./check-tidy.sh --help               # Show this help message
#
# Environment:
#   CI_MODE         Set to 'true' for CI/CD (machine-readable output)
#   CLANG_TIDY      Path to clang-tidy binary (default: clang-tidy)
#   COMPILE_DB      Path to compile_commands.json (default: build/)
#

set -euo pipefail

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CLANG_TIDY="${CLANG_TIDY:-clang-tidy}"
COMPILE_DB="${COMPILE_DB:-${REPO_ROOT}/build/compile_commands.json}"
CI_MODE="${CI_MODE:-false}"
FIX_MODE="${FIX_MODE:-false}"
DRY_RUN="${DRY_RUN:-false}"
JSON_MODE="${JSON_MODE:-false}"

# Track results
TOTAL_FILES=0
FILES_WITH_ISSUES=0
FAILED_FILES=0
TOTAL_ISSUES=0
declare -A ISSUE_CATEGORIES

# Functions

show_help() {
    cat << 'EOF'
Usage: check-tidy.sh [OPTION]

Static analysis check using clang-tidy.

Options:
    --fix               Fix auto-fixable issues in-place
    --dry-run           Show fixes that would be applied (do not modify files)
    --json              Output results as JSON for machine parsing
    --help              Show this help message

Environment Variables:
  CI_MODE             Set to 'true' for CI/CD (non-interactive, machine-readable)
  CLANG_TIDY          Path to clang-tidy binary (default: clang-tidy)
  COMPILE_DB          Path to compile_commands.json (default: build/)

Exit Codes:
  0                   No issues found
  1                   Issues found (non-blocking)
  2                   Error occurred or build not configured

Prerequisites:
  - Must run after: ./scripts/build.sh (to generate compile_commands.json)
  - clang-tidy must be installed

Examples:
  # Check for issues (requires build first)
  ./scripts/build.sh --build-type Debug
  ./.github/scripts/quality/check-tidy.sh
  
  # Fix auto-fixable issues
  ./.github/scripts/quality/check-tidy.sh --fix
  
  # CI mode with JSON output
  CI_MODE=true ./.github/scripts/quality/check-tidy.sh --json
EOF
}

log_info() {
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "[INFO] $*"
    else
        echo -e "${BLUE}ℹ${NC} $*"
    fi
}

log_success() {
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "[PASS] $*"
    else
        echo -e "${GREEN}✓${NC} $*"
    fi
}

log_warning() {
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "[WARN] $*"
    else
        echo -e "${YELLOW}⚠${NC} $*"
    fi
}

log_error() {
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "[ERROR] $*"
    else
        echo -e "${RED}✗${NC} $*"
    fi
}

check_prerequisites() {
    # Check if clang-tidy is installed
    if ! command -v "${CLANG_TIDY}" &> /dev/null; then
        log_error "clang-tidy not found. Install with: apt-get install clang-tools"
        return 2
    fi

    # Check if compile_commands.json exists
    if [[ ! -f "${COMPILE_DB}" ]]; then
        log_error "compile_commands.json not found at: ${COMPILE_DB}"
        log_info "Build the project first: ./scripts/build.sh --build-type Debug"
        return 2
    fi

    log_success "clang-tidy ready (version: $(${CLANG_TIDY} --version | head -n1))"
    return 0
}

find_cpp_files() {
    # Find all C++ source files in core/, ui/, and ui-slim/ directories
    find "${REPO_ROOT}/core" "${REPO_ROOT}/ui" "${REPO_ROOT}/ui-slim" \
        -type f \
        \( -name "*.cpp" -o -name "*.cc" \) \
        -not -path "*/build/*" \
        -not -path "*/.build/*" \
        2>/dev/null || true
}

check_file() {
    local file="$1"
    local relative_path="${file#${REPO_ROOT}/}"

    ((TOTAL_FILES++))

    # Run clang-tidy
    local output
    local exit_code=0
    output=$("${CLANG_TIDY}" -p "${REPO_ROOT}/build" "$file" 2>&1) || exit_code=$?

    # Parse output for issues
    local issue_count=0
    if [[ -n "${output}" ]]; then
        # Count lines that look like issues (contain ': error:' or ': warning:')
        issue_count=$(echo "${output}" | grep -cE '(error|warning):' || true)
    fi

    if [[ ${issue_count} -gt 0 ]]; then
        ((FILES_WITH_ISSUES++))
        ((TOTAL_ISSUES += issue_count))

        if [[ "${CI_MODE}" == "false" ]]; then
            log_warning "Found ${issue_count} issue(s): ${relative_path}"
            echo "${output}" | head -n 10
            if [[ ${issue_count} -gt 10 ]]; then
                echo "... and $((issue_count - 10)) more issues"
            fi
        fi

        if [[ "${FIX_MODE}" == "true" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "Would fix ${issue_count} issue(s): ${relative_path}"
            else
                # Run clang-tidy fix and capture output; do not silence so we can show errors
                local fix_output
                local fix_exit=0
                fix_output=$("${CLANG_TIDY}" -p "${REPO_ROOT}/build" -fix "$file" 2>&1) || fix_exit=$?
                if [[ ${fix_exit} -eq 0 ]]; then
                    log_success "Fixed ${issue_count} issue(s): ${relative_path}"
                else
                    ((FAILED_FILES++))
                    log_error "Failed to fix: ${relative_path}: ${fix_output}"
                fi
            fi
        fi
    fi
}

output_json() {
    local status="pass"
    [[ "${FILES_WITH_ISSUES}" -gt 0 ]] && status="fail"
    [[ "${FAILED_FILES}" -gt 0 ]] && status="error"

    cat << EOF
{
  "tool": "clang-tidy",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "${status}",
  "summary": {
    "total_files": ${TOTAL_FILES},
    "files_with_issues": ${FILES_WITH_ISSUES},
    "total_issues": ${TOTAL_ISSUES},
    "failed_files": ${FAILED_FILES}
  }
}
EOF
}

output_summary() {
    echo ""
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "=========================================="
        echo "Static Analysis Summary"
        echo "=========================================="
        echo "Total files:      ${TOTAL_FILES}"
        echo "Issues found:     ${TOTAL_ISSUES}"
        echo "Files with issues: ${FILES_WITH_ISSUES}"
        echo "=========================================="
    else
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  Static Analysis Summary${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf "Total files:      %d\n" "${TOTAL_FILES}"
        printf "Issues found:     %d\n" "${TOTAL_ISSUES}"
        printf "Files with issues: %d\n" "${FILES_WITH_ISSUES}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi

    if [[ "${TOTAL_ISSUES}" -eq 0 ]]; then
        log_success "No issues found"
        return 0
    elif [[ "${FAILED_FILES}" -gt 0 ]]; then
        log_error "Failed to process some files"
        return 2
    else
        log_warning "Found ${TOTAL_ISSUES} issue(s)"
        return 1
    fi
}

# Main execution

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_MODE="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --json)
                JSON_MODE="true"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done
}

main() {
    parse_arguments "$@"

    log_info "Running static analysis with clang-tidy..."

    if ! check_prerequisites; then
        return 2
    fi

    # Find and check all C++ files
    while IFS= read -r file; do
        if ! check_file "$file"; then
            log_warning "check_file failed for ${file}, continuing"
        fi
    done < <(find_cpp_files)

    # Output results
    if [[ "${JSON_MODE}" == "true" ]]; then
        output_json
    else
        output_summary
    fi
}

main "$@"
exit $?
