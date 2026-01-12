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

# Code Coverage Report Generation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build-coverage"
COVERAGE_DIR="${PROJECT_ROOT}/coverage-report"

echo "=========================================="
echo "Generating Code Coverage Report"
echo "=========================================="
echo "Project: Crankshaft Slim UI"
echo "Build Dir: ${BUILD_DIR}"
echo "Output Dir: ${COVERAGE_DIR}"
echo "=========================================="
echo ""

# Check dependencies
echo "Checking dependencies..."
MISSING_DEPS=0

if ! command -v lcov >/dev/null 2>&1; then
    echo "Error: lcov not found. Install with: sudo apt install lcov"
    MISSING_DEPS=1
fi

if ! command -v genhtml >/dev/null 2>&1; then
    echo "Error: genhtml not found. Install with: sudo apt install lcov"
    MISSING_DEPS=1
fi

if ! command -v gcov >/dev/null 2>&1; then
    echo "Error: gcov not found. Install with: sudo apt install gcc"
    MISSING_DEPS=1
fi

if [ ${MISSING_DEPS} -eq 1 ]; then
    echo ""
    echo "Missing dependencies. Please install and try again."
    exit 1
fi

echo "All dependencies found."
echo ""

# Clean previous coverage build
if [ -d "${BUILD_DIR}" ]; then
    echo "Cleaning previous coverage build..."
    rm -rf "${BUILD_DIR}"
fi

# Create coverage build directory
echo "Creating coverage build directory..."
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Configure with coverage flags
echo ""
echo "Configuring CMake with coverage flags..."
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_CXX_FLAGS="--coverage -fprofile-arcs -ftest-coverage" \
      -DCMAKE_C_FLAGS="--coverage -fprofile-arcs -ftest-coverage" \
      -DCMAKE_EXE_LINKER_FLAGS="--coverage" \
      -DBUILD_SLIM_UI=ON \
      "${PROJECT_ROOT}"

# Build
echo ""
echo "Building project with coverage instrumentation..."
cmake --build . --parallel "$(nproc)"

# Initialize coverage data
echo ""
echo "Initializing coverage data..."
lcov --zerocounters --directory .
lcov --capture --initial --directory . --output-file coverage_base.info

# Run tests
echo ""
echo "Running tests..."
ctest --output-on-failure || echo "Warning: Some tests failed"

# Capture coverage data
echo ""
echo "Capturing coverage data..."
lcov --capture --directory . --output-file coverage_test.info

# Combine baseline and test coverage
echo "Combining baseline and test coverage..."
lcov --add-tracefile coverage_base.info \
     --add-tracefile coverage_test.info \
     --output-file coverage_total.info

# Filter out system headers and test files
echo "Filtering coverage data..."
lcov --remove coverage_total.info \
     '/usr/*' \
     '*/tests/*' \
     '*/external/*' \
     '*/build/*' \
     '*/moc_*' \
     '*_autogen/*' \
     --output-file coverage_filtered.info

# Generate HTML report
echo ""
echo "Generating HTML coverage report..."
rm -rf "${COVERAGE_DIR}"
mkdir -p "${COVERAGE_DIR}"
genhtml coverage_filtered.info \
        --output-directory "${COVERAGE_DIR}" \
        --title "Crankshaft Slim UI Code Coverage" \
        --legend \
        --show-details \
        --highlight \
        --dark-mode

# Generate summary
echo ""
echo "=========================================="
echo "Coverage Report Summary"
echo "=========================================="
lcov --list coverage_filtered.info

# Calculate overall coverage percentage
COVERAGE_PERCENT=$(lcov --summary coverage_filtered.info 2>&1 | grep "lines" | awk '{print $2}')
echo ""
echo "Overall Line Coverage: ${COVERAGE_PERCENT}"
echo ""

# Extract numeric percentage for comparison
COVERAGE_NUM=$(echo "${COVERAGE_PERCENT}" | sed 's/%//')
TARGET_COVERAGE=80

# Check if coverage meets target
if command -v bc >/dev/null 2>&1; then
    if [ "$(echo "${COVERAGE_NUM} >= ${TARGET_COVERAGE}" | bc)" -eq 1 ]; then
        echo "✅ Coverage target met! (${COVERAGE_PERCENT} >= ${TARGET_COVERAGE}%)"
    else
        echo "⚠️  Coverage below target: ${COVERAGE_PERCENT} < ${TARGET_COVERAGE}%"
        echo "Additional testing needed for:"
        echo "  - Error handling edge cases"
        echo "  - Audio failure recovery scenarios"
        echo "  - Connection state machine transitions"
        echo "  - Settings persistence edge cases"
    fi
fi

echo ""
echo "=========================================="
echo "Coverage Report Generated"
echo "=========================================="
echo "HTML Report: ${COVERAGE_DIR}/index.html"
echo "Coverage Data: ${BUILD_DIR}/coverage_filtered.info"
echo ""
echo "To view the report:"
echo "  Open: ${COVERAGE_DIR}/index.html"
echo "  Or:"
echo "  cd ${COVERAGE_DIR} && python3 -m http.server 8080"
echo "  Then open: http://localhost:8080"
echo "=========================================="

# Create coverage badge (JSON format for tools like shields.io)
cat > "${COVERAGE_DIR}/coverage.json" <<EOF
{
  "schemaVersion": 1,
  "label": "coverage",
  "message": "${COVERAGE_PERCENT}",
  "color": "$(if [ "$(echo "${COVERAGE_NUM} >= ${TARGET_COVERAGE}" | bc 2>/dev/null)" = "1" ]; then echo "brightgreen"; else echo "orange"; fi)"
}
EOF

echo ""
echo "Coverage badge JSON: ${COVERAGE_DIR}/coverage.json"
echo ""

exit 0
