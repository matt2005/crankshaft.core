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
# Quality Check: Code Formatting (clang-format)
# Purpose: Verify C++ code follows project formatting standards
#
# Usage:
#   ./check-format.sh                    # Check and report differences (exit 1 if changes needed)
#   ./check-format.sh --fix              # Fix formatting in-place
#   ./check-format.sh --json             # Output results as JSON
#   ./check-format.sh --dry-run          # Show files that would be changed, don't write fixes
#   ./check-format.sh --help             # Show this help message
#
# Environment:
#   CI_MODE         Set to 'true' for CI/CD (machine-readable output)
#   FORMAT_STYLE    Path to .clang-format file (default: project root)
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
CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"
FORMAT_STYLE="${FORMAT_STYLE:-${REPO_ROOT}/.clang-format}"
CI_MODE="${CI_MODE:-false}"
FIX_MODE="${FIX_MODE:-false}"
DRY_RUN="${DRY_RUN:-false}"
JSON_MODE="${JSON_MODE:-false}"

# Track results
TOTAL_FILES=0
FORMATTED_FILES=0
FAILED_FILES=0
ERRORS=()

# Functions

show_help() {
    cat << 'EOF'
Usage: check-format.sh [OPTION]

Code formatting check using clang-format.

Options:
    --fix               Fix formatting in-place (modifies files)
    --dry-run           Show files that would be changed (don't write files)
    --json              Output results as JSON for machine parsing
    --help              Show this help message

Environment Variables:
  CI_MODE             Set to 'true' for CI/CD (non-interactive, machine-readable)
  CLANG_FORMAT        Path to clang-format binary (default: clang-format)
  FORMAT_STYLE        Path to .clang-format config (default: project root)

Exit Codes:
  0                   All files properly formatted
  1                   Formatting changes needed
  2                   Error occurred (missing tool, config, etc)

Examples:
  # Check formatting
  ./check-format.sh
  
  # Fix formatting
  ./check-format.sh --fix
  
  # CI mode with JSON output
  CI_MODE=true ./check-format.sh --json
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
    # Check if clang-format is installed
    if ! command -v "${CLANG_FORMAT}" &> /dev/null; then
        log_error "clang-format not found. Install with: apt-get install clang-format"
        return 2
    fi

    # Check if .clang-format exists
    if [[ ! -f "${FORMAT_STYLE}" ]]; then
        log_error "Format config not found: ${FORMAT_STYLE}"
        return 2
    fi

    log_success "clang-format ready (version: $(${CLANG_FORMAT} --version))"
    return 0
}

find_cpp_files() {
    # Find all C++ source files in core/ and ui/ directories
    find "${REPO_ROOT}/core" "${REPO_ROOT}/ui" \
        -type f \
        \( -name "*.cpp" -o -name "*.hpp" -o -name "*.h" -o -name "*.cc" \) \
        -not -path "*/build/*" \
        -not -path "*/.build/*" \
        2>/dev/null || true
}

check_file() {
    local file="$1"
    local relative_path="${file#${REPO_ROOT}/}"

    ((TOTAL_FILES++))

    log_info "Formatting: ${relative_path}"

    # Get formatted version
    local formatted
    # Run clang-format and do not silence stderr so we can capture problems.
    # Use --style=file so clang-format searches for the repository .clang-format.
    if ! formatted=$("${CLANG_FORMAT}" --style=file "$file" 2>&1); then
        log_error "Failed to run clang-format on: ${relative_path}"
        ERRORS+=("${relative_path}: clang-format execution failed: ${formatted}")
        ((FAILED_FILES++))
        # Do not return non-zero here — record the error and continue checking other files.
        return 0
    fi

    # Compare with original
    local original
    original=$(cat "$file")

    if [[ "${original}" != "${formatted}" ]]; then
        if [[ "${FIX_MODE}" == "true" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "Would fix: ${relative_path}"
                ((FORMATTED_FILES++))
            else
                # Use printf to preserve content exactly (avoid echo interpretation issues).
                printf '%s' "$formatted" > "$file"
                log_success "Fixed: ${relative_path}"
                ((FORMATTED_FILES++))
            fi
        else
            log_warning "Needs formatting: ${relative_path}"
            ((FORMATTED_FILES++))
        fi
    fi
}

output_json() {
    local status="pass"
    [[ "${FORMATTED_FILES}" -gt 0 ]] && status="fail"
    [[ "${FAILED_FILES}" -gt 0 ]] && status="error"

    cat << EOF
{
  "tool": "clang-format",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "${status}",
  "summary": {
    "total_files": ${TOTAL_FILES},
    "formatted_files": ${FORMATTED_FILES},
    "failed_files": ${FAILED_FILES}
  },
  "details": {
EOF

    if [[ "${#ERRORS[@]}" -gt 0 ]]; then
        echo "    \"errors\": ["
        for i in "${!ERRORS[@]}"; do
            echo "      \"${ERRORS[$i]}\""
            [[ $((i + 1)) -lt ${#ERRORS[@]} ]] && echo ","
        done
        echo "    ]"
    else
        echo "    \"errors\": []"
    fi

    cat << 'EOF'
  }
}
EOF
}

output_summary() {
    echo ""
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "=========================================="
        echo "Formatting Check Summary"
        echo "=========================================="
        echo "Total files:      ${TOTAL_FILES}"
        echo "Formatted:        ${FORMATTED_FILES}"
        echo "Errors:           ${FAILED_FILES}"
        echo "=========================================="
    else
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  Formatting Check Summary${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf "Total files:      %d\n" "${TOTAL_FILES}"
        printf "Formatted:        %d\n" "${FORMATTED_FILES}"
        printf "Errors:           %d\n" "${FAILED_FILES}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi

    if [[ "${FORMATTED_FILES}" -eq 0 && "${FAILED_FILES}" -eq 0 ]]; then
        log_success "All files properly formatted"
        return 0
    elif [[ "${FAILED_FILES}" -gt 0 ]]; then
        log_error "Some files had errors"
        return 2
    else
        if [[ "${FIX_MODE}" == "true" ]]; then
            log_success "Fixed ${FORMATTED_FILES} files"
            return 0
        else
            log_warning "${FORMATTED_FILES} files need formatting"
            return 1
        fi
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

    log_info "Checking code formatting with clang-format..."

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
