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

# Convert all source files from CRLF to LF line endings

set -e

echo "=== Converting line endings to LF ==="

# Find all relevant source files
FILES=$(find . -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' -o -name '*.c' -o -name '*.cc' -o -name '*.sh' \) \
  ! -path '*/build/*' \
  ! -path '*/external/*' \
  ! -path '*/.git/*' \
  ! -path '*/node_modules/*')

CONVERTED=0
SKIPPED=0

for file in $FILES; do
  # Check if file has CRLF
  if file "$file" | grep -q CRLF; then
    echo "Converting: $file"
    # Use dos2unix if available, otherwise sed
    if command -v dos2unix >/dev/null 2>&1; then
      dos2unix "$file" 2>/dev/null || sed -i 's/\r$//' "$file"
    else
      sed -i 's/\r$//' "$file"
    fi
    CONVERTED=$((CONVERTED + 1))
  else
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo "=== Conversion complete ==="
echo "Converted: $CONVERTED files"
echo "Already LF: $SKIPPED files"
echo "Total: $((CONVERTED + SKIPPED)) files"
