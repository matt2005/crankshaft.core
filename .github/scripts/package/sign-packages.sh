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

# Sign files (typically Release file) using GPG
# Usage: sign-packages.sh --key <key_id> --gpg-home <home> <file_to_sign>

usage() {
    cat << EOF
Usage: $0 --key <key_id> --gpg-home <gpg_home> <file_to_sign>

Signs a file using GPG.

Required arguments:
  --key KEY_ID           GPG key ID to use for signing
  --gpg-home GPG_HOME    GPG home directory containing keys
  file_to_sign           Path to file to sign

Optional arguments:
  --detach-sign          Create detached signature (default: clear-signed)
  --json                 Output signing result as JSON

Exit codes:
  0   Signing successful
  1   Signing failed
  2   Usage error
EOF
    exit 2
}

if [[ $# -lt 3 ]]; then
    usage
fi

KEY_ID=""
GPG_HOME=""
FILE_TO_SIGN=""
DETACH_SIGN=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --key)
            if [[ $# -lt 2 ]]; then
                echo "Error: --key requires a value"
                usage
            fi
            KEY_ID="$2"
            shift 2
            ;;
        --gpg-home)
            if [[ $# -lt 2 ]]; then
                echo "Error: --gpg-home requires a value"
                usage
            fi
            GPG_HOME="$2"
            shift 2
            ;;
        --detach-sign)
            DETACH_SIGN=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            if [[ "$1" != -* ]]; then
                FILE_TO_SIGN="$1"
                shift
            else
                echo "Error: Unknown option '$1'"
                usage
            fi
            ;;
    esac
done

# Validate inputs
if [[ -z "$KEY_ID" || -z "$GPG_HOME" || -z "$FILE_TO_SIGN" ]]; then
    echo "Error: Missing required arguments"
    usage
fi

if [[ ! -f "$FILE_TO_SIGN" ]]; then
    echo "Error: File not found: $FILE_TO_SIGN"
    exit 2
fi

if [[ ! -d "$GPG_HOME" ]]; then
    echo "Error: GPG home directory not found: $GPG_HOME"
    exit 2
fi

# Verify key is available
if ! GNUPGHOME="$GPG_HOME" gpg --list-keys "$KEY_ID" &> /dev/null; then
    echo "Error: GPG key not found: $KEY_ID"
    exit 2
fi

# Sign the file
SIGN_OUTPUT=$(mktemp)
trap "rm -f $SIGN_OUTPUT" EXIT

if [[ "$DETACH_SIGN" == true ]]; then
    # Create detached signature
    SIGN_FILE="${FILE_TO_SIGN}.asc"
    if GNUPGHOME="$GPG_HOME" gpg --default-key "$KEY_ID" --detach-sign --armor "$FILE_TO_SIGN" 2>"$SIGN_OUTPUT"; then
        SIGN_SUCCESS=true
    else
        SIGN_SUCCESS=false
    fi
else
    # Create clear-signed file (for Release file in APT)
    SIGN_FILE="${FILE_TO_SIGN}.gpg"
    TEMP_SIGN=$(mktemp)
    if GNUPGHOME="$GPG_HOME" gpg --default-key "$KEY_ID" --armor --clearsign "$FILE_TO_SIGN" > "$TEMP_SIGN" 2>"$SIGN_OUTPUT"; then
        mv "$TEMP_SIGN" "$SIGN_FILE"
        SIGN_SUCCESS=true
    else
        rm -f "$TEMP_SIGN"
        SIGN_SUCCESS=false
    fi
fi

# Get signature info
if [[ "$SIGN_SUCCESS" == true ]]; then
    SIGN_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    SIGN_SIZE=$(stat -c%s "$SIGN_FILE")
    ORIGINAL_SIZE=$(stat -c%s "$FILE_TO_SIGN")
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        cat << EOF
{
  "signing_time": "$SIGN_TIMESTAMP",
  "key_id": "$KEY_ID",
  "file": "$(basename $FILE_TO_SIGN)",
  "signature_file": "$(basename $SIGN_FILE)",
  "original_size": $ORIGINAL_SIZE,
  "signature_size": $SIGN_SIZE,
  "signed": true,
  "detach_sign": $DETACH_SIGN
}
EOF
    else
        echo "GPG Signing Summary"
        echo "==================="
        echo "Time: $SIGN_TIMESTAMP"
        echo "Key: $KEY_ID"
        echo "Original file: $FILE_TO_SIGN"
        echo "Signature file: $SIGN_FILE"
        echo "Signature type: $([ "$DETACH_SIGN" = true ] && echo 'detached' || echo 'clear-signed')"
    fi
else
    ERROR_MSG=$(cat "$SIGN_OUTPUT" || echo "Unknown error")
    if [[ "$JSON_OUTPUT" == true ]]; then
        cat << EOF
{
  "signing_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "signed": false,
  "error": "$ERROR_MSG"
}
EOF
    else
        echo "GPG Signing Failed"
        echo "=================="
        echo "Error: $ERROR_MSG"
    fi
    exit 1
fi

exit 0
