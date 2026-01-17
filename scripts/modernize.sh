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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODERNIZER="${SCRIPT_DIR}/modernize_cpp.py"

# Colour codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

# Default values
COMPONENT="all"
DRY_RUN=false
VERBOSE=false
ANALYZE_ONLY=false

# Help text
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Modernise C++ code in Crankshaft to use C++17/20 features.

OPTIONS:
    -c, --component COMPONENT   Component to modernise: all, core, ui, ui-slim (default: all)
    -n, --dry-run              Show changes without applying them
    -v, --verbose              Print verbose output
    -a, --analyze              Analyse only, show what would be changed
    -h, --help                 Show this help message

EXAMPLES:
    # Analyse core component without changes
    $0 -c core -a

    # Modernise UI component (apply changes)
    $0 -c ui

    # Dry run to see changes
    $0 -n

    # Verbose output for all components
    $0 -v
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--component)
            COMPONENT="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -a|--analyze)
            ANALYZE_ONLY=true
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Check if modernizer exists
if [[ ! -f "$MODERNIZER" ]]; then
    echo -e "${RED}Error: Modernizer script not found: $MODERNIZER${NC}"
    exit 1
fi

# Build command
CMD="python3 $MODERNIZER"
[[ "$DRY_RUN" == true ]] && CMD+=" --dry-run"
[[ "$VERBOSE" == true ]] && CMD+=" --verbose"

# Determine target directory
case "$COMPONENT" in
    all)
        TARGETS=("core" "ui" "ui-slim")
        ;;
    core)
        TARGETS=("core")
        ;;
    ui)
        TARGETS=("ui")
        ;;
    ui-slim)
        TARGETS=("ui-slim")
        ;;
    *)
        echo -e "${RED}Error: Unknown component '$COMPONENT'${NC}"
        echo "Valid options: all, core, ui, ui-slim"
        exit 1
        ;;
esac

# Print header
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}C++ Code Moderniser${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

if [[ "$ANALYZE_ONLY" == true ]]; then
    echo -e "${YELLOW}Mode: ANALYSE ONLY (no changes will be applied)${NC}"
elif [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Mode: DRY RUN (showing changes only)${NC}"
else
    echo -e "${GREEN}Mode: APPLY CHANGES${NC}"
fi

[[ "$VERBOSE" == true ]] && echo -e "Verbose: ${GREEN}enabled${NC}"
echo -e "Target: ${GREEN}${TARGETS[*]}${NC}"
echo

# Process each target
for target in "${TARGETS[@]}"; do
    target_dir="$PROJECT_ROOT/$target"
    
    if [[ ! -d "$target_dir" ]]; then
        echo -e "${YELLOW}⊘ Skipping $target (directory not found)${NC}"
        continue
    fi
    
    echo -e "${BLUE}→ Processing: $target${NC}"
    echo -e "  Directory: $target_dir"
    
    # Run modernizer
    eval "$CMD $target_dir"
    
    echo
done

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
if [[ "$ANALYZE_ONLY" == true ]]; then
    echo -e "${YELLOW}Analysis complete. No changes were applied.${NC}"
elif [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run complete. To apply changes, run without --dry-run.${NC}"
else
    echo -e "${GREEN}Modernisation complete!${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
