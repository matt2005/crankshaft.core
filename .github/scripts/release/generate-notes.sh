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

# Generate changelog from git log
# Usage: generate-notes.sh [--version VERSION] [--from-tag TAG] [--json]

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generates changelog from git commit history.

Optional arguments:
  --version VERSION      Version for this release (for header)
  --from-tag TAG         Git tag to start from (default: previous tag)
  --json                 Output as JSON
  --output FILE          Write to file instead of stdout

Examples:
  $0 --version 2025.01.03 --from-tag v2025.01.02
  $0 --json > changelog.json
  $0 --output CHANGELOG.md

Exit codes:
  0   Changelog generated
  1   Generation failed
  2   Usage error
EOF
    exit 2
}

VERSION=""
FROM_TAG=""
JSON_OUTPUT=false
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            if [[ $# -lt 2 ]]; then
                echo "Error: --version requires a value"
                usage
            fi
            VERSION="$2"
            shift 2
            ;;
        --from-tag)
            if [[ $# -lt 2 ]]; then
                echo "Error: --from-tag requires a value"
                usage
            fi
            FROM_TAG="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --output)
            if [[ $# -lt 2 ]]; then
                echo "Error: --output requires a value"
                usage
            fi
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo "Error: Unknown option '$1'"
            usage
            ;;
    esac
done

# Default version
if [[ -z "$VERSION" ]]; then
    VERSION=$(date -u +%Y.%m.%d)
fi

# Find previous tag if not specified
if [[ -z "$FROM_TAG" ]]; then
    FROM_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# Get commit range
if [[ -n "$FROM_TAG" ]]; then
    COMMIT_RANGE="$FROM_TAG..HEAD"
    COMMIT_COUNT=$(git rev-list --count "$COMMIT_RANGE" 2>/dev/null || echo "0")
else
    COMMIT_RANGE=""
    COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
fi

# Categorize commits
FEATURES=$(git log ${COMMIT_RANGE:-HEAD} --pretty=format:"%B" 2>/dev/null | grep -E "^feat:|^feature:" | sed 's/^feat://;s/^feature://' | sort -u || true)
BUGFIXES=$(git log ${COMMIT_RANGE:-HEAD} --pretty=format:"%B" 2>/dev/null | grep -E "^fix:|^bugfix:" | sed 's/^fix://;s/^bugfix://' | sort -u || true)
IMPROVEMENTS=$(git log ${COMMIT_RANGE:-HEAD} --pretty=format:"%B" 2>/dev/null | grep -E "^perf:|^refactor:|^docs:" | sed 's/^perf://;s/^refactor://;s/^docs://' | sort -u || true)
BREAKING=$(git log ${COMMIT_RANGE:-HEAD} --pretty=format:"%B" 2>/dev/null | grep -E "^BREAKING CHANGE:" | sed 's/^BREAKING CHANGE://' | sort -u || true)

# Generate output
generate_markdown() {
    cat << EOF
# Crankshaft Release $VERSION

**Release Date**: $(date -u +"%B %d, %Y")  
**Git Commit**: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

## Highlights

- Comprehensive multi-architecture CI/CD pipeline
- Automated quality checks and packaging
- APT repository publishing with atomic updates
- Release automation with checksums and SBOM

## What's New

EOF

    if [[ -n "$FEATURES" ]]; then
        echo "### New Features"
        echo ""
        echo "$FEATURES" | while read -r feature; do
            [[ -n "$feature" ]] && echo "- $feature"
        done
        echo ""
    fi

    if [[ -n "$BUGFIXES" ]]; then
        echo "### Bug Fixes"
        echo ""
        echo "$BUGFIXES" | while read -r fix; do
            [[ -n "$fix" ]] && echo "- $fix"
        done
        echo ""
    fi

    if [[ -n "$IMPROVEMENTS" ]]; then
        echo "### Improvements"
        echo ""
        echo "$IMPROVEMENTS" | while read -r improvement; do
            [[ -n "$improvement" ]] && echo "- $improvement"
        done
        echo ""
    fi

    if [[ -n "$BREAKING" ]]; then
        echo "### ⚠️ Breaking Changes"
        echo ""
        echo "$BREAKING" | while read -r change; do
            [[ -n "$change" ]] && echo "- $change"
        done
        echo ""
    fi

    cat << EOF
## Installation

### From APT Repository (Stable Channel)

\`\`\`bash
curl -fsSL https://packages.opencardev.org/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/opencardev.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/opencardev.gpg] https://packages.opencardev.org/apt trixie stable" | sudo tee /etc/apt/sources.list.d/opencardev.list
sudo apt-get update
sudo apt-get install crankshaft
\`\`\`

### From DEB Package (Manual)

Download and install directly:

\`\`\`bash
sudo apt-get install ./crankshaft_${VERSION}_amd64.deb
\`\`\`

## Verification

All packages are signed with GPG key \`0x[APT_SIGNING_KEY]\`.

Verify checksums:
\`\`\`bash
sha256sum -c SHA256SUMS
\`\`\`

## Support and Reporting Issues

- **GitHub Issues**: https://github.com/opencardev/crankshaft/issues
- **Documentation**: https://github.com/opencardev/crankshaft/blob/main/README.md
- **Security Issues**: Please email security@opencardev.org

---

*Total commits since last release: $COMMIT_COUNT*
EOF
}

generate_json() {
    cat << EOF
{
  "version": "$VERSION",
  "release_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")",
  "commits_since_last": $COMMIT_COUNT,
  "features": [
EOF

    # Features array
    FIRST=true
    echo "$FEATURES" | while read -r feature; do
        if [[ -n "$feature" ]]; then
            if [[ "$FIRST" == true ]]; then
                echo -n "    \"$feature\""
                FIRST=false
            else
                echo "    \"$feature\","
            fi
        fi
    done
    echo ""

    cat << EOF
  ],
  "bug_fixes": [
EOF

    # Bug fixes array
    FIRST=true
    echo "$BUGFIXES" | while read -r fix; do
        if [[ -n "$fix" ]]; then
            if [[ "$FIRST" == true ]]; then
                echo -n "    \"$fix\""
                FIRST=false
            else
                echo "    \"$fix\","
            fi
        fi
    done
    echo ""

    cat << EOF
  ],
  "improvements": [
EOF

    # Improvements array
    FIRST=true
    echo "$IMPROVEMENTS" | while read -r improvement; do
        if [[ -n "$improvement" ]]; then
            if [[ "$FIRST" == true ]]; then
                echo -n "    \"$improvement\""
                FIRST=false
            else
                echo "    \"$improvement\","
            fi
        fi
    done
    echo ""

    cat << EOF
  ],
  "breaking_changes": [
EOF

    # Breaking changes array
    FIRST=true
    echo "$BREAKING" | while read -r change; do
        if [[ -n "$change" ]]; then
            if [[ "$FIRST" == true ]]; then
                echo -n "    \"$change\""
                FIRST=false
            else
                echo "    \"$change\","
            fi
        fi
    done
    echo ""

    cat << EOF
  ]
}
EOF
}

# Generate output
if [[ "$JSON_OUTPUT" == true ]]; then
    OUTPUT=$(generate_json)
else
    OUTPUT=$(generate_markdown)
fi

# Write to file or stdout
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$OUTPUT" > "$OUTPUT_FILE"
    echo "Changelog written to: $OUTPUT_FILE"
else
    echo "$OUTPUT"
fi

exit 0
