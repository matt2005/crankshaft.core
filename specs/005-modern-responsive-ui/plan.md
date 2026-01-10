# Implementation Plan: Modern Responsive UI (AndroidAuto + Settings)

**Branch**: `005-modern-responsive-ui` | **Date**: 2026-01-09 | **Spec**: specs/005-modern-responsive-ui/spec.md
**Input**: Feature specification from specs/005-modern-responsive-ui/spec.md

## Summary

Deliver a modern, responsive Qt6/QML UI that only surfaces AndroidAuto and Settings, adapts to single or dual displays, and lets the user pick the primary display for AA. Apply shared design tokens, light/dark theming, and en-GB-first i18n; persist theme/language/layout and one-time AA consent; reflow within 500 ms and keep AA launch ≤ 5 s.

## Technical Context

**Language/Version**: C++17 with Qt 6 (QML/Qt Quick Controls 6)  
**Primary Dependencies**: Qt Quick Controls 6, Qt Linguist (qsTr + .ts), CMake/Ninja toolchain  
**Storage**: Existing settings/config service (QSettings-backed) with JSON export for tests; no new databases  
**Testing**: ctest/QtTest harness for UI logic; QML tests for layout/i18n/theming; contract tests for settings/AA status APIs  
**Target Platform**: Raspberry Pi OS (Linux) with single or dual displays (eglfs, vnc); dev on WSL/desktop Linux  
**Project Type**: Embedded UI application (Qt/QML frontend with C++ backing services)  
**Performance Goals**: Home render ≤ 2 s; reflow/orientation change ≤ 500 ms; theme swap ≤ 500 ms; AA launch ≤ 5 s; 60 fps UI (30+ fps when projecting); touch latency < 50 ms; combined core+UI memory ≤ 1.5 GB  
**Constraints**: Max two displays; user-selectable primary display; tap targets ≥ 44×44 px; en‑GB default locale; avoid non-existent features; follow Design for Driving and project headers/licensing; sandbox extensions  
**Scale/Scope**: Limited feature surface (AndroidAuto, Settings, Home tiles); two-display max; translations for en-GB baseline with extensible locales

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Code Quality & Maintainability: Use shared QML singletons/tokens; no duplicated styling; reuse settings service; document public APIs.
- Test-First & Testing Standards: Add QML/QtTest coverage for layout breakpoints, theme swap, language change, AA consent gating, and settings persistence; include contract tests for settings/AA endpoints.
- UX Consistency & Accessibility: Shared tokens, 44×44 px tap targets, en-GB default, localisation via qsTr, light/dark toggle with consistent spacing/typography; follow Design for Driving.
- Performance & Resource Constraints: Honour budgets above; measure theme swap/reflow; avoid heavyweight assets; ensure AA launch path stays within 5 s; monitor memory against 1.5 GB budget.
- Observability, Versioning & Change Management: Emit structured logs around AA availability/consent and settings changes; document API versions for contracts; note any flags/toggles if used.

Status: PASS (no deviations required). Re-verify after design is materialised.

## Project Structure

### Documentation (this feature)

```text
specs/005-modern-responsive-ui/
├── plan.md          # This file
├── research.md      # Phase 0 output
├── data-model.md    # Phase 1 output
├── quickstart.md    # Phase 1 output
├── contracts/       # Phase 1 output (OpenAPI)
└── tasks.md         # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
core/                # C++ backend services, event bus, settings/config
ui/                  # Qt6/QML frontend, components, themes, translations
config/              # Runtime configuration and defaults
scripts/             # Build/test helpers (WSL-friendly)
tests/               # Unit/integration/ctest and QML tests
docs/                # Project docs and fix summaries
specs/               # Feature specs and plans
```

**Structure Decision**: Use existing core/ui separation; feature work resides in ui/ (QML, themes, layouts, translations) with any minimal core hooks for settings/AA status exposure. Tests live under tests/ with QML/ctest suites; contracts in specs/005-modern-responsive-ui/contracts.

## Complexity Tracking

No constitution violations or additional complexity requiring justification.
src/
