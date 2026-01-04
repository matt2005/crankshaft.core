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

#!/usr/bin/env bash
set -euo pipefail

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Configuration
CI_MODE="${CI_MODE:-false}"
JSON_MODE="${JSON_MODE:-false}"
SEARCH_DIRS=(core ui extensions)
TMP_FILE="/tmp/missing_license.txt"

# Functions

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

log_error() {
    if [[ "${CI_MODE}" == "true" ]]; then
        echo "[ERROR] $*"
    else
        echo -e "${RED}✗${NC} $*"
    fi
}

output_json() {
    local status="pass"
    local missing_count=0
    local missing_files=()
    
    if [[ -s "$TMP_FILE" ]]; then
        status="fail"
        mapfile -t missing_files < "$TMP_FILE"
        missing_count=${#missing_files[@]}
    fi

    cat << EOF
{
  "tool": "license-headers",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "${status}",
  "summary": {
    "missing_headers": ${missing_count}
  },
  "details": {
    "missing_files": [
EOF

    if [[ ${missing_count} -gt 0 ]]; then
        for i in "${!missing_files[@]}"; do
            echo "      \"${missing_files[$i]}\""
            [[ $((i + 1)) -lt ${missing_count} ]] && echo ","
        done
    fi

    cat << 'EOF'
    ]
  }
}
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE="true"
            shift
            ;;
        --help)
            cat << 'HELP'
Usage: check_license_headers.sh [OPTION]

Verify that all source files contain the required GNU GPL license header.

Options:
  --json              Output results as JSON for machine parsing
  --help              Show this help message

Environment Variables:
  CI_MODE             Set to 'true' for CI/CD (non-interactive, machine-readable)

Exit Codes:
  0                   All files have proper license headers
  1                   Some files missing license headers

Examples:
  # Check license headers
  ./scripts/check_license_headers.sh
  
  # Output JSON format
  ./scripts/check_license_headers.sh --json
  
  # CI mode
  CI_MODE=true ./scripts/check_license_headers.sh --json
HELP
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution

log_info "Checking for required license headers..."

: > "$TMP_FILE"

find "${SEARCH_DIRS[@]}" -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' -o -name '*.cc' \) -print0 \
  | xargs -0 -I {} sh -c "grep -q 'GNU General Public License' '{}' || echo '{}' >> '$TMP_FILE'"

if [[ -s "$TMP_FILE" ]]; then
    if [[ "${JSON_MODE}" == "true" ]]; then
        output_json
    else
        log_error "Files missing license headers:"
        cat "$TMP_FILE" >&2
    fi
    exit 1
else
    if [[ "${JSON_MODE}" == "true" ]]; then
        output_json
    else
        log_success "All checked files contain the required license header."
    fi
    exit 0
fi
