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

# Generate SBOM (Software Bill of Materials) in SPDX format
# Usage: generate-sbom.sh [--version VERSION] [--output FILE]

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generates SBOM (Software Bill of Materials) in SPDX format.

Optional arguments:
  --version VERSION      Software version (default: from git tag)
  --output FILE          Write to file instead of stdout
  --json                 Output as JSON (default: SPDX tag-value format)

Examples:
  $0 --version 1.0.0
  $0 --output SBOM.spdx
  $0 --json > sbom.json

Exit codes:
  0   SBOM generated
  1   Generation failed
  2   Usage error
EOF
    exit 2
}

VERSION=""
OUTPUT_FILE=""
JSON_OUTPUT=false

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
        --output)
            if [[ $# -lt 2 ]]; then
                echo "Error: --output requires a value"
                usage
            fi
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
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
    VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "1.0.0")
fi

# Get current timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Generate SBOM
generate_sbom_spdx() {
    cat << EOF
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: Crankshaft SBOM
DocumentNamespace: https://github.com/opencardev/crankshaft/sbom/$VERSION
Creator: Tool: generate-sbom.sh-1.0
Created: $TIMESTAMP

PackageName: Crankshaft
SPDXID: SPDXRef-Package
PackageVersion: $VERSION
PackageDownloadLocation: https://github.com/opencardev/crankshaft
FilesAnalyzed: false
PackageVerificationCode: $(echo -n "$VERSION" | sha256sum | cut -d' ' -f1) ()
PackageLicenseConcluded: GPL-3.0-or-later
PackageLicenseDeclared: GPL-3.0-or-later
PackageCopyrightText: Copyright (C) 2025 OpenCarDev Team
ExternalRef: SECURITY-CPE23 cpe23Type cpe:2.3:a:opencardev:crankshaft:$VERSION:*:*:*:*:*:*:*
PackageComment: Automotive infotainment system with extensible framework

# External dependencies
PackageName: Qt6
SPDXID: SPDXRef-Qt6
PackageVersion: 6.x
PackageDownloadLocation: https://www.qt.io
FilesAnalyzed: false
PackageLicenseConcluded: LGPL-3.0-only
PackageCopyrightText: The Qt Company Ltd
ExternalRef: PACKAGE-MANAGER PackageManagerReference: qt6

PackageName: AASDK
SPDXID: SPDXRef-AASDK
PackageVersion: latest
PackageDownloadLocation: https://github.com/opencardev/aasdk
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageCopyrightText: OpenCarDev Team
ExternalRef: PACKAGE-MANAGER PackageManagerReference: aasdk

PackageName: Protocol Buffers
SPDXID: SPDXRef-ProtoBuf
PackageVersion: 3.x
PackageDownloadLocation: https://github.com/protocolbuffers/protobuf
FilesAnalyzed: false
PackageLicenseConcluded: BSD-3-Clause
PackageCopyrightText: Google Inc.
ExternalRef: PACKAGE-MANAGER PackageManagerReference: protobuf

PackageName: Boost
SPDXID: SPDXRef-Boost
PackageVersion: 1.83
PackageDownloadLocation: https://www.boost.org
FilesAnalyzed: false
PackageLicenseConcluded: BSL-1.0
PackageCopyrightText: Boost Software Foundation
ExternalRef: PACKAGE-MANAGER PackageManagerReference: libboost

PackageName: OpenSSL
SPDXID: SPDXRef-OpenSSL
PackageVersion: 3.x
PackageDownloadLocation: https://www.openssl.org
FilesAnalyzed: false
PackageLicenseConcluded: Apache-2.0
PackageCopyrightText: OpenSSL Software Foundation
ExternalRef: PACKAGE-MANAGER PackageManagerReference: libssl

PackageName: GStreamer
SPDXID: SPDXRef-GStreamer
PackageVersion: 1.0
PackageDownloadLocation: https://gstreamer.freedesktop.org
FilesAnalyzed: false
PackageLicenseConcluded: LGPL-2.0-or-later
PackageCopyrightText: GStreamer developers
ExternalRef: PACKAGE-MANAGER PackageManagerReference: gstreamer1.0

# Relationships
Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Package
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-Qt6
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-AASDK
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-ProtoBuf
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-Boost
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-OpenSSL
Relationship: SPDXRef-Package DEPENDS_ON SPDXRef-GStreamer

# Vulnerability tracking
VulnerabilityReferenceCategory SECURITY
VulnerabilityReferenceLid: https://nvd.nist.gov/vuln/search
EOF
}

generate_sbom_json() {
    cat << EOF
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "Crankshaft SBOM",
  "documentNamespace": "https://github.com/opencardev/crankshaft/sbom/$VERSION",
  "creationInfo": {
    "created": "$TIMESTAMP",
    "creators": [
      "Tool: generate-sbom.sh-1.0"
    ]
  },
  "packages": [
    {
      "SPDXID": "SPDXRef-Package",
      "name": "Crankshaft",
      "version": "$VERSION",
      "downloadLocation": "https://github.com/opencardev/crankshaft",
      "filesAnalyzed": false,
      "licenseConcluded": "GPL-3.0-or-later",
      "licenseDeclared": "GPL-3.0-or-later",
      "copyrightText": "Copyright (C) 2025 OpenCarDev Team",
      "description": "Automotive infotainment system with extensible framework"
    },
    {
      "SPDXID": "SPDXRef-Qt6",
      "name": "Qt6",
      "version": "6.x",
      "downloadLocation": "https://www.qt.io",
      "filesAnalyzed": false,
      "licenseConcluded": "LGPL-3.0-only",
      "copyrightText": "The Qt Company Ltd"
    },
    {
      "SPDXID": "SPDXRef-AASDK",
      "name": "AASDK",
      "version": "latest",
      "downloadLocation": "https://github.com/opencardev/aasdk",
      "filesAnalyzed": false,
      "licenseConcluded": "MIT",
      "copyrightText": "OpenCarDev Team"
    },
    {
      "SPDXID": "SPDXRef-ProtoBuf",
      "name": "Protocol Buffers",
      "version": "3.x",
      "downloadLocation": "https://github.com/protocolbuffers/protobuf",
      "filesAnalyzed": false,
      "licenseConcluded": "BSD-3-Clause",
      "copyrightText": "Google Inc."
    },
    {
      "SPDXID": "SPDXRef-Boost",
      "name": "Boost",
      "version": "1.83",
      "downloadLocation": "https://www.boost.org",
      "filesAnalyzed": false,
      "licenseConcluded": "BSL-1.0",
      "copyrightText": "Boost Software Foundation"
    },
    {
      "SPDXID": "SPDXRef-OpenSSL",
      "name": "OpenSSL",
      "version": "3.x",
      "downloadLocation": "https://www.openssl.org",
      "filesAnalyzed": false,
      "licenseConcluded": "Apache-2.0",
      "copyrightText": "OpenSSL Software Foundation"
    },
    {
      "SPDXID": "SPDXRef-GStreamer",
      "name": "GStreamer",
      "version": "1.0",
      "downloadLocation": "https://gstreamer.freedesktop.org",
      "filesAnalyzed": false,
      "licenseConcluded": "LGPL-2.0-or-later",
      "copyrightText": "GStreamer developers"
    }
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-Qt6"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-AASDK"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-ProtoBuf"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-Boost"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-OpenSSL"
    },
    {
      "spdxElementId": "SPDXRef-Package",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-GStreamer"
    }
  ]
}
EOF
}

# Generate output
if [[ "$JSON_OUTPUT" == true ]]; then
    OUTPUT=$(generate_sbom_json)
else
    OUTPUT=$(generate_sbom_spdx)
fi

# Write to file or stdout
if [[ -n "$OUTPUT_FILE" ]]; then
    echo "$OUTPUT" > "$OUTPUT_FILE"
    echo "SBOM written to: $OUTPUT_FILE" >&2
else
    echo "$OUTPUT"
fi

exit 0
