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

"""Modernize C++ code to use modern features and conventions."""

import re
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Match
import json
import argparse


class CppModernizer:
    """Modernise C++ code to use C++17/20 features."""

    def __init__(self, dry_run: bool = False, verbose: bool = False):
        """Initialise the moderniser."""
        self.dry_run = dry_run
        self.verbose = verbose
        self.stats = {
            'trailing_return': 0,
            'nodiscard': 0,
            'override': 0,
            'deleted_constructors': 0,
            'files_processed': 0,
            'files_modified': 0,
        }

    def modernise(self, file_path: str) -> Tuple[str, bool]:
        """Modernise a single C++ file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            original_content = content

            # Apply modernisations in sequence
            content = self._add_trailing_return_types(content, file_path)
            content = self._add_nodiscard(content, file_path)
            content = self._add_override(content, file_path)
            content = self._delete_empty_constructors(content, file_path)

            self.stats['files_processed'] += 1

            if content != original_content:
                self.stats['files_modified'] += 1
                if not self.dry_run:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                if self.verbose:
                    print(f'Modernised: {file_path}')
                return file_path, True
            return file_path, False

        except Exception as e:
            print(f'Error processing {file_path}: {e}', file=sys.stderr)
            return file_path, False

    def _add_trailing_return_types(self, content: str, file_path: str) -> str:
        """Convert traditional return types to trailing return type syntax.
        
        Skip pure virtual declarations (those ending with = 0;).
        """
        # Skip if already converted (contains " -> ")
        if ' -> ' in content:
            return content

        # Pattern to match function declarations (but NOT pure virtual)
        # Traditional: type name(args) const;
        # Convert to: auto name(args) const -> type;
        
        # This regex matches but EXPLICITLY avoids "= 0"
        pattern = r'\b(bool|int|float|double|QString|QVariant|QSize|QPoint|void)\s+(\w+)\s*\(\s*([^)]*)\s*\)\s*(const)?\s*;'
        
        matches = list(re.finditer(pattern, content))
        for match in reversed(matches):  # Reverse to maintain positions
            match_text = match.group(0)
            
            # CRITICAL: Skip pure virtual declarations
            if ' = 0;' in match_text or '= 0;' in match_text or '=0;' in match_text:
                continue
            
            new_text = self._convert_to_trailing_return(match)
            if new_text != match_text:
                content = content[:match.start()] + new_text + content[match.end():]
                self.stats['trailing_return'] += 1

        return content

    def _convert_to_trailing_return(self, match: Match) -> str:
        """Convert a function signature to trailing return syntax.
        
        Example:
            bool isValid(int x) const;
        becomes:
            auto isValid(int x) const -> bool;
        """
        return_type = match.group(1)
        func_name = match.group(2)
        params = match.group(3)
        const = match.group(4) or ''

        # Skip void returns (no benefit to convert)
        if return_type == 'void':
            return match.group(0)

        # Build trailing return syntax
        const_str = f' {const}' if const else ''
        return f'auto {func_name}({params}){const_str} -> {return_type};'

    def _add_nodiscard(self, content: str, file_path: str) -> str:
        """Add [[nodiscard]] attribute to getter methods."""
        # Pattern: bool|QString|QVariant|etc get*() const;
        # Add [[nodiscard]] before return type
        
        pattern = r'\n\s+(bool|QString|QVariant|QSize|QPoint|int|float|double)(\s+(?:get|is|has)\w+\s*\([^)]*\)\s*const\s*;)'
        replacement = r'\n    [[nodiscard]] \1\2'
        
        original = content
        content = re.sub(pattern, replacement, content)
        
        if content != original:
            self.stats['nodiscard'] += (len(re.findall(pattern, original)) - 
                                       len(re.findall(pattern, content)))

        return content

    def _add_override(self, content: str, file_path: str) -> str:
        """Add override keyword to virtual function implementations."""
        # Pattern: virtual returntype funcname(...);
        # Note: Typically used in header files for interface definitions
        # Skip if it's a pure virtual (= 0)
        
        pattern = r'\n\s+virtual\s+(\w+)\s+(\w+)\s*\([^)]*\)\s*(const)?\s*;'
        
        def add_override(match):
            if '= 0' in match.group(0):
                # Pure virtual, don't add override
                return match.group(0)
            
            virtual_kw = 'virtual'
            return_type = match.group(1)
            func_name = match.group(2)
            const = match.group(3) or ''
            
            const_str = f' {const}' if const else ''
            return f'\n    virtual {return_type} {func_name} {const_str} override;'.strip()

        original = content
        content = re.sub(pattern, add_override, content)
        
        if content != original:
            self.stats['override'] += (len(re.findall(pattern, original)) - 
                                      len(re.findall(pattern, content)))

        return content

    def _delete_empty_constructors(self, content: str, file_path: str) -> str:
        """Replace empty constructors with = default."""
        # Pattern: ClassName() {}; or ClassName() { }
        # Replace with: ClassName() = default;
        
        pattern = r'(\w+)\s*\(\s*\)\s*\{\s*\}'
        
        def replace_empty_constructor(match):
            class_name = match.group(1)
            return f'{class_name}() = default;'

        original = content
        content = re.sub(pattern, replace_empty_constructor, content)
        
        if content != original:
            self.stats['deleted_constructors'] += (len(re.findall(pattern, original)) - 
                                                  len(re.findall(pattern, content)))

        return content

    def process_directory(self, directory: str) -> None:
        """Process all C++ files in a directory recursively."""
        cpp_extensions = {'.h', '.hpp', '.cpp', '.cc', '.cxx'}
        
        for root, dirs, files in os.walk(directory):
            # Skip certain directories
            skip_dirs = {'build', '.git', 'external', '_deps', 'node_modules'}
            dirs[:] = [d for d in dirs if d not in skip_dirs]
            
            for file in files:
                if Path(file).suffix in cpp_extensions:
                    file_path = os.path.join(root, file)
                    self.modernise(file_path)

    def print_stats(self) -> None:
        """Print modernisation statistics."""
        print('\n' + '='*60)
        print('Modernisation Summary')
        print('='*60)
        print(f"Files processed: {self.stats['files_processed']}")
        print(f"Files modified: {self.stats['files_modified']}")
        print(f"Trailing return types: {self.stats['trailing_return']}")
        print(f"[[nodiscard]] added: {self.stats['nodiscard']}")
        print(f"override added: {self.stats['override']}")
        print(f"= default constructors: {self.stats['deleted_constructors']}")
        print('='*60)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Modernise C++ code')
    parser.add_argument('directory', help='Directory to modernise')
    parser.add_argument('--dry-run', '-n', action='store_true',
                        help='Show what would be changed without making changes')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Print verbose output')

    args = parser.parse_args()

    moderniser = CppModernizer(dry_run=args.dry_run, verbose=args.verbose)
    moderniser.process_directory(args.directory)
    moderniser.print_stats()


if __name__ == '__main__':
    main()
