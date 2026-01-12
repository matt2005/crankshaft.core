#!/bin/bash

# Batch convert all remaining function definitions in .cpp files to trailing return types

convert_file() {
    local file=$1
    local tempfile="${file}.tmp"
    
    # Create backup
    cp "$file" "$tempfile"
    
    # Convert bool ClassName::method(...) to auto ClassName::method(...) -> bool
    sed -i 's/^\([ ]*\)bool \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> bool {/g' "$file"
    sed -i 's/^\([ ]*\)bool \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> bool {/g' "$file"
    
    # Convert void ClassName::method(...) to auto ClassName::method(...) -> void
    sed -i 's/^\([ ]*\)void \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> void {/g' "$file"
    sed -i 's/^\([ ]*\)void \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> void {/g' "$file"
    
    # Convert int ClassName::method(...) to auto ClassName::method(...) -> int
    sed -i 's/^\([ ]*\)int \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> int {/g' "$file"
    sed -i 's/^\([ ]*\)int \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> int {/g' "$file"
    
    # Convert QString ClassName::method(...) to auto ClassName::method(...) -> QString
    sed -i 's/^\([ ]*\)QString \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> QString {/g' "$file"
    sed -i 's/^\([ ]*\)QString \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> QString {/g' "$file"
    
    # Convert QVariant ClassName::method(...) to auto ClassName::method(...) -> QVariant
    sed -i 's/^\([ ]*\)QVariant \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> QVariant {/g' "$file"
    sed -i 's/^\([ ]*\)QVariant \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> QVariant {/g' "$file"
    
    # Convert QPointF ClassName::method(...) to auto ClassName::method(...) -> QPointF
    sed -i 's/^\([ ]*\)QPointF \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> QPointF {/g' "$file"
    sed -i 's/^\([ ]*\)QPointF \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) const {/\1auto \2::\3(\4) const -> QPointF {/g' "$file"
    
    # Convert EnumType ClassName::method(...) to auto ClassName::method(...) -> EnumType
    # For nested enums like BackendType, AudioVolumeController::BackendType
    sed -i 's/^\([ ]*\)[A-Za-z_][A-Za-z0-9_]*::\([A-Z][a-zA-Z0-9_]*\) \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \3::\4(\5) -> \2 {/g' "$file"
    
    # Convert QList<Type> ClassName::method(...) to auto ClassName::method(...) -> QList<Type>
    sed -i 's/^\([ ]*\)QList<[^>]*> \([A-Z][a-zA-Z0-9_]*\)::\([a-zA-Z_][a-zA-Z0-9_]*\)(\(.*\)) {/\1auto \2::\3(\4) -> QList {/g' "$file"
    
    # Check if changes were made
    if ! diff -q "$file" "$tempfile" > /dev/null 2>&1; then
        echo "✓ $file"
        rm "$tempfile"
        return 0
    else
        mv "$tempfile" "$file"
        echo "  $file (no changes)"
        return 1
    fi
}

# Process all .cpp files
cd ui-slim/src || exit 1

converted=0
for cpp_file in *.cpp; do
    if convert_file "$cpp_file"; then
        ((converted++))
    fi
done

echo ""
echo "Converted $converted files"
