#!/usr/bin/env python3
"""Batch convert ui-slim C++ files to use trailing return types."""

import re
import subprocess
from pathlib import Path

def convert_file(filepath):
    """Convert a .cpp file to use trailing return type syntax."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Pattern to match traditional return type at function definition
    # Matches: ReturnType ClassName::methodName(...) -> auto ClassName::methodName(...) -> ReturnType
    # More specific: match at start of line (indented or not)
    pattern = r'(^\s*)([a-zA-Z_:][a-zA-Z0-9_:* &]*?)\s+([A-Z][a-zA-Z0-9_]*)::([a-zA-Z_][a-zA-Z0-9_]*)\s*(\(.*?\))\s*(const)?\s*(\{|\n)'
    
    def replace_func(match):
        indent = match.group(1)
        return_type = match.group(2).strip()
        class_name = match.group(3)
        method_name = match.group(4)
        params = match.group(5)
        is_const = match.group(6)
        brace_or_newline = match.group(7)
        
        # Skip if already has trailing return type
        if '-> ' in return_type or return_type.startswith('auto'):
            return match.group(0)
        
        # Build the new signature
        if is_const:
            new_sig = f"{indent}auto {class_name}::{method_name}{params} {is_const} -> {return_type} {brace_or_newline}"
        else:
            new_sig = f"{indent}auto {class_name}::{method_name}{params} -> {return_type} {brace_or_newline}"
        
        return new_sig.replace('  ->', ' ->').replace('   ->', ' ->')  # Clean spacing
    
    content = re.sub(pattern, replace_func, content, flags=re.MULTILINE)
    
    # If content changed, write it back
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    cpp_files = sorted(Path('ui-slim/src').glob('*.cpp'))
    
    converted = 0
    for filepath in cpp_files:
        if convert_file(filepath):
            print(f"✓ {filepath.name}")
            converted += 1
        else:
            print(f"  {filepath.name} (no changes)")
    
    print(f"\nConverted {converted} files")

if __name__ == '__main__':
    main()
