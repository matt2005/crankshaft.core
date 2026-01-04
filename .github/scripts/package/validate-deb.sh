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

set -e
set -u

# Validate DEB packages using lintian
# Usage: validate-deb.sh <deb_file_or_directory>

usage() {
    cat << EOF
Usage: $0 <deb_file_or_directory> [--json]

Validates DEB package using lintian checks.

Arguments:
  deb_file_or_directory   Path to .deb file or directory containing .deb files
  --json                  Output validation results as JSON

Exit codes:
  0   All packages valid
  1   Validation errors found
  2   Usage error
EOF
    exit 2
}

if [[ $# -lt 1 ]]; then
    usage
fi

DEB_PATH="$1"
JSON_OUTPUT=false

if [[ $# -gt 1 && "$2" == "--json" ]]; then
    JSON_OUTPUT=true
fi

# Collect DEB files
DEBS=()
if [[ -f "$DEB_PATH" && "$DEB_PATH" == *.deb ]]; then
    DEBS=("$DEB_PATH")
elif [[ -d "$DEB_PATH" ]]; then
    while IFS= read -r -d '' deb; do
        DEBS+=("$deb")
    done < <(find "$DEB_PATH" -maxdepth 1 -name "*.deb" -print0)
fi

if [[ ${#DEBS[@]} -eq 0 ]]; then
    echo "Error: No .deb files found in $DEB_PATH"
    exit 2
fi

# Validate each package
RESULTS=()
TOTAL_ERRORS=0
TOTAL_WARNINGS=0

for deb in "${DEBS[@]}"; do
    deb_name=$(basename "$deb")
    
    # Check file exists and is readable
    if [[ ! -r "$deb" ]]; then
        RESULTS+=("{\"file\":\"$deb_name\",\"valid\":false,\"reason\":\"File not readable\"}")
        ((TOTAL_ERRORS++))
        continue
    fi
    
    # Basic DEB structure validation
    if ! ar -t "$deb" > /dev/null 2>&1; then
        RESULTS+=("{\"file\":\"$deb_name\",\"valid\":false,\"reason\":\"Invalid DEB format\"}")
        ((TOTAL_ERRORS++))
        continue
    fi
    
    # Run lintian if available
    if command -v lintian &> /dev/null; then
        LINTIAN_OUTPUT=$(lintian "$deb" 2>&1 || true)
        LINTIAN_ERRORS=$(echo "$LINTIAN_OUTPUT" | grep -c "^E:" || true)
        LINTIAN_WARNINGS=$(echo "$LINTIAN_OUTPUT" | grep -c "^W:" || true)
        
        if [[ $LINTIAN_ERRORS -gt 0 ]]; then
            RESULTS+=("{\"file\":\"$deb_name\",\"valid\":false,\"errors\":$LINTIAN_ERRORS,\"warnings\":$LINTIAN_WARNINGS}")
            ((TOTAL_ERRORS++))
        else
            RESULTS+=("{\"file\":\"$deb_name\",\"valid\":true,\"errors\":0,\"warnings\":$LINTIAN_WARNINGS}")
        fi
        TOTAL_WARNINGS=$((TOTAL_WARNINGS + LINTIAN_WARNINGS))
    else
        # Minimal validation without lintian
        RESULTS+=("{\"file\":\"$deb_name\",\"valid\":true,\"notes\":\"lintian not available - basic validation only\"}")
    fi
done

# Output results
if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"validation_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"total_packages\": ${#DEBS[@]},"
    echo "  \"valid_packages\": $((${#DEBS[@]} - TOTAL_ERRORS)),"
    echo "  \"invalid_packages\": $TOTAL_ERRORS,"
    echo "  \"total_warnings\": $TOTAL_WARNINGS,"
    echo "  \"results\": ["
    for i in "${!RESULTS[@]}"; do
        echo -n "    ${RESULTS[$i]}"
        if [[ $i -lt $((${#RESULTS[@]} - 1)) ]]; then
            echo ","
        else
            echo ""
        fi
    done
    echo "  ]"
    echo "}"
else
    echo "DEB Validation Summary"
    echo "====================="
    echo "Total packages: ${#DEBS[@]}"
    echo "Valid: $((${#DEBS[@]} - TOTAL_ERRORS))"
    echo "Invalid: $TOTAL_ERRORS"
    echo "Warnings: $TOTAL_WARNINGS"
    echo ""
    
    for result in "${RESULTS[@]}"; do
        if echo "$result" | grep -q "\"valid\":true"; then
            echo "✓ $result"
        else
            echo "✗ $result"
        fi
    done
fi

# Exit with error if any validation failed
if [[ $TOTAL_ERRORS -gt 0 ]]; then
    exit 1
fi

exit 0
