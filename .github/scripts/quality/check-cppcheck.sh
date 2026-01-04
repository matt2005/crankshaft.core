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
# Quality Check: Static Analysis (cppcheck)
# Purpose: Detect bugs and potential issues in C++ code
#
# Usage:
#   ./check-cppcheck.sh                  # Check and report issues
#   ./check-cppcheck.sh --json           # Output results as JSON
#   ./check-cppcheck.sh --help           # Show this help message
#
# Environment:
#   CI_MODE         Set to 'true' for CI/CD (machine-readable output)
#   CPPCHECK        Path to cppcheck binary (default: cppcheck)
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
CPPCHECK="${CPPCHECK:-cppcheck}"
CI_MODE="${CI_MODE:-false}"
JSON_MODE="${JSON_MODE:-false}"

# Track results
ERRORS_COUNT=0
WARNINGS_COUNT=0
STYLE_COUNT=0
PERFORMANCE_COUNT=0
PORTABILITY_COUNT=0

# Functions

show_help() {
    cat << 'EOF'
Usage: check-cppcheck.sh [OPTION]

Static analysis check using cppcheck.

Options:
  --json              Output results as JSON for machine parsing
  --help              Show this help message

Environment Variables:
  CI_MODE             Set to 'true' for CI/CD (non-interactive, machine-readable)
  CPPCHECK            Path to cppcheck binary (default: cppcheck)

Exit Codes:
  0                   No issues found
  1                   Issues found (non-blocking)
  2                   Error occurred (missing tool, etc)

Examples:
  # Check for issues
  ./.github/scripts/quality/check-cppcheck.sh
  
  # CI mode with JSON output
  CI_MODE=true ./.github/scripts/quality/check-cppcheck.sh --json
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
    # Check if cppcheck is installed
    if ! command -v "${CPPCHECK}" &> /dev/null; then
        log_error "cppcheck not found. Install with: apt-get install cppcheck"
        return 2
    fi

    log_success "cppcheck ready (version: $(${CPPCHECK} --version))"
    return 0
}

count_issue_type() {
    local severity="$1"
    local output="$2"
    
    # Count lines matching the severity pattern
    echo "${output}" | grep -c "\[${severity}\]" || echo "0"
}

output_json() {
    local status="pass"
    local total_issues=$((ERRORS_COUNT + WARNINGS_COUNT + STYLE_COUNT + PERFORMANCE_COUNT + PORTABILITY_COUNT))
    [[ ${total_issues} -gt 0 ]] && status="fail"

    cat << EOF
{
  "tool": "cppcheck",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "${status}",
  "summary": {
    "errors": ${ERRORS_COUNT},
    "warnings": ${WARNINGS_COUNT},
    "style": ${STYLE_COUNT},
    "performance": ${PERFORMANCE_COUNT},
    "portability": ${PORTABILITY_COUNT},
    "total": ${total_issues}
  }
}
EOF
}

output_summary() {
    local total_issues=$((ERRORS_COUNT + WARNINGS_COUNT + STYLE_COUNT + PERFORMANCE_COUNT + PORTABILITY_COUNT))
    
    echo ""
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "=========================================="
        echo "Code Analysis Summary (cppcheck)"
        echo "=========================================="
        echo "Errors:           ${ERRORS_COUNT}"
        echo "Warnings:         ${WARNINGS_COUNT}"
        echo "Style:            ${STYLE_COUNT}"
        echo "Performance:      ${PERFORMANCE_COUNT}"
        echo "Portability:      ${PORTABILITY_COUNT}"
        echo "Total:            ${total_issues}"
        echo "=========================================="
    else
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  Code Analysis Summary (cppcheck)${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf "Errors:           %d\n" "${ERRORS_COUNT}"
        printf "Warnings:         %d\n" "${WARNINGS_COUNT}"
        printf "Style:            %d\n" "${STYLE_COUNT}"
        printf "Performance:      %d\n" "${PERFORMANCE_COUNT}"
        printf "Portability:      %d\n" "${PORTABILITY_COUNT}"
        printf "Total:            %d\n" "${total_issues}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi

    if [[ ${total_issues} -eq 0 ]]; then
        log_success "No issues found"
        return 0
    else
        log_warning "Found ${total_issues} issue(s)"
        return 1
    fi
}

# Main execution

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
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

    log_info "Running static analysis with cppcheck..."

    if ! check_prerequisites; then
        return 2
    fi

    # Run cppcheck on core and ui directories
    local output
    output=$("${CPPCHECK}" \
        --enable=all \
        --quiet \
        --suppress=missingIncludeSystem \
        --suppress=unusedFunction \
        --suppress=unmatchedSuppression \
        "${REPO_ROOT}/core" \
        "${REPO_ROOT}/ui" \
        2>&1) || true

    # Count issues by type
    ERRORS_COUNT=$(count_issue_type "error" "${output}")
    WARNINGS_COUNT=$(count_issue_type "warning" "${output}")
    STYLE_COUNT=$(count_issue_type "style" "${output}")
    PERFORMANCE_COUNT=$(count_issue_type "performance" "${output}")
    PORTABILITY_COUNT=$(count_issue_type "portability" "${output}")

    # Show output in non-CI mode
    if [[ "${CI_MODE}" == "false" ]] && [[ -n "${output}" ]]; then
        echo "${output}"
    fi

    # Output results
    if [[ "${JSON_MODE}" == "true" ]]; then
        output_json
    else
        output_summary
    fi
}

main "$@"
exit $?
