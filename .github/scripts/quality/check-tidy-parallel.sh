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

# Determine number of parallel jobs
JOBS=${CLANG_TIDY_JOBS:-$(nproc)}

# Define source directories to check
SOURCE_DIRS=(
    "core/src"
    "core/include"
)

# Skip directories
SKIP_PATTERNS=(
    "*/build/*"
    "*/_deps/*"
    "*/third_party/*"
    "*/external/*"
    "*/ui/*"
    "*/ui-slim/*"
)

# Create skip pattern for find command
SKIP_FIND=""
for pattern in "${SKIP_PATTERNS[@]}"; do
    SKIP_FIND="${SKIP_FIND} -not -path '${pattern}'"
done

echo "🔍 Running clang-tidy in parallel (${JOBS} jobs)..."

# Find all C++ source files
CPPFILES=$(find core/src core/include \
    -not -path "*/build/*" \
    -not -path "*/_deps/*" \
    -not -path "*/third_party/*" \
    -not -path "*/external/*" \
    -not -path "*/ui/*" \
    -not -path "*/ui-slim/*" \
    \( -name "*.cpp" -o -name "*.cc" -o -name "*.hpp" -o -name "*.h" \) \
    2>/dev/null | grep -v "^$" || true)

if [ -z "$CPPFILES" ]; then
    echo "❌ No C++ files found in core directories"
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$CPPFILES" | wc -l)
echo "📄 Found ${FILE_COUNT} C++ files to check"

# Create temporary directory for results
RESULTS_DIR=$(mktemp -d)
FAILED_FILE="${RESULTS_DIR}/failed_files"
touch "$FAILED_FILE"

# Function to run clang-tidy on a single file
run_tidy_on_file() {
    local file="$1"
    local output_file="$2"
    
    if clang-tidy -p build "$file" > "$output_file" 2>&1; then
        return 0
    else
        echo "$file" >> "$FAILED_FILE"
        return 1
    fi
}

export -f run_tidy_on_file

# Run clang-tidy in parallel using GNU parallel or xargs
echo "$CPPFILES" | \
    xargs -I {} -P "$JOBS" bash -c 'run_tidy_on_file "$@"' _ {} "${RESULTS_DIR}/{}"

# Check if any files failed
if [ -s "$FAILED_FILE" ]; then
    echo ""
    echo "❌ clang-tidy found issues in the following files:"
    cat "$FAILED_FILE"
    echo ""
    echo "Use './scripts/format_cpp.sh fix' to auto-fix issues"
    
    # Cleanup
    rm -rf "$RESULTS_DIR"
    exit 1
fi

echo "✅ All clang-tidy checks passed!"

# Cleanup
rm -rf "$RESULTS_DIR"
exit 0
