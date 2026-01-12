# Contributing to Crankshaft Slim UI

Thank you for your interest in contributing to the Crankshaft Slim AndroidAuto UI! This document provides guidelines for contributing code, documentation, and other improvements.

## Coding Standards

### C++ Code

- Follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- Use C++17 features where appropriate
- Use meaningful variable and function names
- Include comments for complex logic
- Run `clang-format` before committing: `./scripts/format_cpp.sh fix`
- Run `clang-tidy` for static analysis
- Run `cppcheck` for additional checks

### QML Code

- Follow Qt QML style conventions
- Use declarative patterns for UI components
- Keep business logic in C++ facades
- Use meaningful property and signal names
- Document complex behaviors with comments

### Commit Messages

- Use clear and descriptive commit messages
- Format: `Type: [task-id] - Brief description`
- Example: `Feat: T021 - Implement AndroidAutoFacade core bridge`
- Types: `Feat`, `Fix`, `Docs`, `Refactor`, `Test`, `Chore`
- Include issue/task numbers when applicable
- Limit first line to 72 characters
- Wrap body at 80 characters

### Branch Naming

- Feature branches: `feature/001-slim-aa-ui/brief-description`
- Bugfix branches: `bugfix/001-slim-aa-ui/issue-description`
- Example: `feature/001-slim-aa-ui/android-auto-facade`

## Testing

- Write unit tests for all critical functions
- Run full test suite before submitting PR: `cmake --build build --target test`
- Achieve >80% code coverage for new code
- Test on physical Raspberry Pi 4 when possible
- Test both EGLFS and VNC backends

## Pull Request Checklist

- [ ] Code follows style guidelines (clang-format, clang-tidy)
- [ ] Tests pass locally (`ctest --test-dir build`)
- [ ] New tests added for new functionality
- [ ] Documentation updated (README, CONTRIBUTING, docs/)
- [ ] License headers present in all new files
- [ ] Commit messages follow format guidelines
- [ ] No merge conflicts with main branch
- [ ] Feature tested on Raspberry Pi 4 (if applicable)

## Development Environment

### Prerequisites

- CMake 3.16+
- Qt 6.x
- C++17 capable compiler (g++, clang)
- Crankshaft core library

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/opencardev/crankshaft-mvp.git
cd crankshaft-mvp

# Configure CMake (enable slim UI)
cmake -S . -B build -DENABLE_SLIM_UI=ON

# Build
cmake --build build -j$(nproc)

# Run tests
ctest --test-dir build --output-on-failure

# Run application (VNC backend for testing)
QT_DEBUG_PLUGINS=0 ./build/ui-slim/crankshaft-slim-ui -platform vnc:port=5900
```

### Code Quality Tools

```bash
# Format code
./scripts/format_cpp.sh fix

# Check formatting
./scripts/format_cpp.sh check

# Run clang-tidy
./scripts/lint_cpp.sh clang-tidy

# Run cppcheck
./scripts/lint_cpp.sh cppcheck
```

## Architecture Overview

The slim UI uses a **facade pattern** to bridge QML frontend with Crankshaft core services:

- **QML Layer**: User interface (main.qml, views, components)
- **C++ Facades**: Thin wrappers providing QML-accessible interfaces
  - AndroidAutoFacade: Bridge to AndroidAutoService
  - PreferencesFacade: Bridge to PreferencesService
- **Core Services**: Existing Crankshaft infrastructure
  - AndroidAutoService: AASDK integration, connection management
  - PreferencesService: SQLite-backed settings persistence
  - EventBus: Pub/sub event system
  - AudioRouter: Audio backend management (ALSA/PulseAudio)
  - Logger: Structured logging

## Feature Development Phases

1. **Phase 1**: Setup & directory structure
2. **Phase 2**: Foundational infrastructure (ServiceProvider, i18n)
3. **Phase 3**: AndroidAuto connection features
4. **Phase 4**: Settings UI and persistence
5. **Phase 5**: Integration, polish, quality gates
6. **Phase 6**: Hardware validation and release

Refer to [tasks.md](../specs/001-slim-aa-ui/tasks.md) for detailed task breakdown.

## Reporting Issues

Use GitHub Issues with clear titles and descriptions:

```
Title: Brief issue description
Body:
- What happened
- What you expected to happen
- Steps to reproduce
- Environment (Pi version, Trixie, Qt version, etc.)
```

## Questions or Need Help?

- Check existing documentation: [specs/001-slim-aa-ui/](../specs/001-slim-aa-ui/)
- Review task breakdowns: [tasks.md](../specs/001-slim-aa-ui/tasks.md)
- Check implementation plan: [plan.md](../specs/001-slim-aa-ui/plan.md)
- Open a GitHub Discussion

## License

All contributions must include appropriate license headers. See [File Headers](../.github/copilot-instructions.md#file-headers) in the project guidelines.

---

Thank you for contributing! 🚀
