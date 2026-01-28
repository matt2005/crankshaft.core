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

set -euo pipefail

# Quick quality scan for local development
# Runs fast, optimised quality checks with parallel execution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
JOBS=${1:-$(nproc)}

cd "$PROJECT_ROOT"

echo "🚀 Starting optimised quality scan (${JOBS} parallel jobs)..."
echo ""

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

failed_checks=0

# 1. Check formatting
echo -n "📋 Checking code formatting... "
if ./.github/scripts/quality/check-format.sh >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "   Run: ./scripts/format_cpp.sh fix"
    ((failed_checks++))
fi

# 2. Check static analysis (cppcheck)
echo -n "🔍 Checking code analysis (cppcheck)... "
if ./.github/scripts/quality/check-cppcheck.sh >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    ((failed_checks++))
fi

# 3. Check license headers
echo -n "📄 Checking license headers... "
if ./scripts/check_license_headers.sh >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "   Run: ./scripts/check_license_headers.sh"
    ((failed_checks++))
fi

# 4. Build (if needed)
if [ ! -d build ] || [ ! -f build/compile_commands.json ]; then
    echo "🏗️  Building project for static analysis..."
    mkdir -p build
    cd build
    cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_UI=OFF \
        -DENABLE_SLIM_UI=ON \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        ..
    ninja -j"$JOBS"
    cd ..
fi

# 5. clang-tidy (parallel)
echo -n "🔧 Checking C++ code with clang-tidy... "
TIDY_LOG=$(mktemp)
if ./.github/scripts/quality/check-tidy.sh 2>"$TIDY_LOG" >/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "   Issues found:"
    head -20 "$TIDY_LOG" | sed 's/^/   /'
    ((failed_checks++))
fi
rm -f "$TIDY_LOG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $failed_checks -eq 0 ]; then
    echo -e "${GREEN}✅ All quality checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ ${failed_checks} check(s) failed${NC}"
    echo ""
    echo "Fix issues and run again: ./scripts/quality-check.sh"
    exit 1
fi
