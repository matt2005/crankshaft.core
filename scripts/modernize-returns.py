#!/usr/bin/env python3
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

"""
Modernizes C++ function declarations/definitions to use trailing return type syntax.
Converts: ReturnType methodName(...) -> auto methodName(...) -> ReturnType
"""

import re
import sys
from pathlib import Path

def modernize_function_declaration(match):
    """Convert traditional return type to trailing return type syntax."""
    # Extract matched groups
    indent = match.group(1)
    decorators = match.group(2)  # might be empty, or 'explicit', 'virtual', 'static', etc.
    return_type = match.group(3)
    method_name = match.group(4)
    params = match.group(5)
    const_or_override = match.group(6)  # might be empty, 'const', 'override', etc.
    semicolon_or_colon = match.group(7)  # ';' or ':'
    
    # Build new trailing return type syntax
    if decorators.strip():
        new_decl = f"{indent}{decorators} auto {method_name}{params} {const_or_override}-> {return_type}{semicolon_or_colon}"
    else:
        new_decl = f"{indent}auto {method_name}{params} {const_or_override}-> {return_type}{semicolon_or_colon}"
    
    return new_decl.replace('  ->', ' ->').replace('   ->', ' ->')  # Clean up spacing

def modernize_file(filepath):
    """Modernize a single C++ file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern to match function declarations/definitions with traditional return types
    # Handles: [indent] [virtual/static/etc] ReturnType methodName(params) [const/override/etc];
    # But skips patterns already using trailing return types (auto ... -> ...)
    # And skips Q_SIGNAL, Q_ENUM macros, etc.
    
    # This regex matches:
    # Group 1: leading whitespace/indentation
    # Group 2: optional decorators (explicit, virtual, static, etc.) + space
    # Group 3: return type (handles pointers, references, simple types, qualified types)
    # Group 4: method name
    # Group 5: parameters in parentheses
    # Group 6: optional const/override/noexcept and space
    # Group 7: semicolon or colon
    
    pattern = r'(\s*)((?:explicit|virtual|static|inline|Q_INVOKABLE|friend|constexpr|consteval)\s+)*([a-zA-Z_:][a-zA-Z0-9_:&*\s]*?)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(\([^)]*\))\s*(const|noexcept|override|const\s+noexcept|const\s+override|override\s+const|noexcept\s+const)?(\s*[;:])'
    
    # Replace pattern, but skip if it already has "auto ... ->" or is a special pattern
    def replace_if_needed(match):
        full_match = match.group(0)
        
        # Skip if already has trailing return type
        if '->' in full_match:
            return full_match
        
        # Skip signals, special macros
        if any(x in full_match for x in ['signal', 'Q_SIGNAL', 'void signals:', 'Q_ENUM', 'Q_PROPERTY']):
            return full_match
        
        return modernize_function_declaration(match)
    
    content = re.sub(pattern, replace_if_needed, content)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    # Find all .h and .cpp files in ui-slim/src
    ui_slim_dir = Path('ui-slim/src')
    if not ui_slim_dir.exists():
        print(f"Error: {ui_slim_dir} not found")
        sys.exit(1)
    
    files = sorted(ui_slim_dir.glob('**/*.h')) + sorted(ui_slim_dir.glob('**/*.cpp'))
    
    modified_count = 0
    for filepath in files:
        if modernize_file(filepath):
            print(f"✓ Modernized: {filepath}")
            modified_count += 1
        else:
            print(f"  No changes: {filepath}")
    
    print(f"\nModernized {modified_count} file(s)")

if __name__ == '__main__':
    main()
