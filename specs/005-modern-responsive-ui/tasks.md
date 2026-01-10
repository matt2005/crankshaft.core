# Tasks: Modern Responsive UI (AndroidAuto + Settings)

**Input**: Design documents from specs/005-modern-responsive-ui/
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are required by the project constitution; include QML/ctest coverage where noted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure tooling and build wiring are ready for feature QML assets and linting.

- [X] T001 Update ui/CMakeLists.txt to include new QML components, layouts, and translation resources for the responsive UI feature.
- [X] T002 Update ui/.qmllint.ini to lint new QML components and screens introduced for this feature.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story work.

- [X] T003 [P] Add QML design tokens singleton (palette, spacing, typography) in ui/qml/components/Theme.qml and register it in ui/qml/components/qmldir.
- [X] T004 [P] Add shared breakpoint/layout helpers for 800×480, 1024×600, 1920×1080 in ui/qml/components/LayoutUtils.qml and export via ui/qml/components/qmldir.
- [X] T005 Extend localisation keys for AA availability/consent and settings labels in ui/qml/models/Strings.qml and update ui/i18n/ui_en_GB.ts (mark other locales for later sync).
- [X] T006 Persist layout_preference, primary_display_id, and aa_consent in ui/SettingsRegistry.cpp and ui/SettingsRegistry.h. Validate primary_display_id against detected displays on load; fallback to detected primary if mismatched or null.
- [X] T007 Expose new settings fields (theme, language, layout_preference, primary_display_id, aa_consent) with change signals in ui/qml/models/SettingsModel.qml.
- [X] T008 Add display enumeration and primary-selection exposure to QML (user override + detected fallback) in ui/main.cpp and create ui/qml/models/DisplayModel.qml. Emit disconnect events when displays change; trigger UI reflow within 1 s.
- [X] T009 Align AndroidAuto status model with contracts (state, consent_required, reason) in ui/qml/models/AndroidAutoStatus.qml. Implement state transitions: unavailable → blocked (no consent) → available → launching → active; emit signals on state changes.

**Checkpoint**: Foundation ready — user story implementation can begin in parallel.

---

## Phase 3: User Story 1 - Use AndroidAuto comfortably on any screen (Priority: P1) 🎯 MVP

**Goal**: AndroidAuto launches with responsive, modern UI across single/dual displays; user-selected primary display controls AA placement; consent gating is enforced.

**Independent Test**: Start app, launch AndroidAuto; verify adaptation on 1024×600, 800×480, 1920×1080 and dual-display with user-selected primary; consent prompts block until accepted while stationary; launch completes ≤ 5 s.

### Implementation for User Story 1

- [X] T010 [P] [US1] Route AA window to user-selected primary display and render status/quick controls on secondary in ui/qml/screens/Main.qml and ui/qml/screens/AndroidAutoScreen.qml.
- [X] T011 [P] [US1] Apply responsive layouts and 44×44 tap targets on AndroidAuto surface using LayoutUtils/Theme in ui/qml/screens/AndroidAutoScreen.qml.
- [X] T012 [US1] Implement consent interstitial and action wiring to /ui/androidauto/consent flow in ui/qml/screens/AndroidAutoScreen.qml.
- [X] T013 [US1] Render blocked/unavailable states with clear messaging and disable launch affordances in ui/qml/screens/AndroidAutoScreen.qml and ui/qml/components/Tile.qml.
- [X] T014 [US1] Wire AA status updates (available/unavailable/blocked/launching/active) to UI state and logs in ui/qml/models/AndroidAutoStatus.qml. Assert AA launch completes within 5 s (launching → active transition).

**Checkpoint**: User Story 1 independently testable (multi-display AA with consent + responsive layout).

---

## Phase 4: User Story 2 - Configure core settings quickly (Priority: P2)

**Goal**: Settings allows theme, language, layout preference, and primary display selection with immediate application and persistence.

**Independent Test**: Open Settings, change theme and language, choose layout preference and primary display; confirm immediate UI update and persistence across restart.

### Implementation for User Story 2

- [X] T015 [P] [US2] Implement settings UI for theme, language, layout_preference, and primary_display selection in ui/qml/screens/SettingsScreen.qml using SettingsModel bindings.
- [X] T016 [P] [US2] Persist setting changes and emit updates to QML (including reapplying theme/language immediately) in ui/qml/models/SettingsModel.qml and ui/SettingsRegistry.cpp.
- [X] T017 [US2] Update translations and labels for new settings options in ui/i18n/ui_en_GB.ts and ui/qml/models/Strings.qml.
- [X] T018 [US2] Ensure theme swap applies within 500 ms across root shell by updating palette propagation in ui/qml/screens/Main.qml and ui/qml/components/AppButton.qml (token usage).

**Checkpoint**: User Story 2 independently testable (settings apply instantly and persist).

---

## Phase 5: User Story 3 - Home shows only what exists (Priority: P3)

**Goal**: Home shows only AndroidAuto and Settings with modern, responsive tiles.

**Independent Test**: Launch app; only AndroidAuto and Settings tiles appear; resize to 800×480, 1024×600, 1920×1080 and verify clean layout without clipping.

### Implementation for User Story 3

- [X] T019 [P] [US3] Limit home to AndroidAuto and Settings tiles and apply responsive Flow/RowLayout spacing in ui/qml/screens/HomeScreen.qml.
- [X] T020 [P] [US3] Refresh Tile visual style (spacing, typography, icon sizing) using Theme tokens in ui/qml/components/Tile.qml.
- [X] T021 [US3] Remove or hide navigation/routes to non-implemented screens in ui/qml/screens/Main.qml to prevent access to absent features.

**Checkpoint**: User Story 3 independently testable (minimal home surface, responsive tiles).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Hardening, docs, and telemetry covering all stories.

- [X] T022 [P] Add QML/QtTest coverage for layout breakpoints (800×480, 1024×600, 1920×1080), theme swap (≤500 ms), settings persistence, 44×44 px tap-target validation across all interactive elements, and AA launch timing (≤5 s) in tests/ui/test_layouts.qml and tests/ui/test_settings.qml.
- [X] T023 [P] Add structured logging for AA availability/consent and display selection changes in ui/WebSocketClient.cpp and ui/qml/models/AndroidAutoStatus.qml.
- [X] T024 Update specs/005-modern-responsive-ui/quickstart.md with final validation steps for dual-display and consent flows after implementation.
- [X] T025 Run end-to-end validation from quickstart (build, run VNC dual-display, consent flow, settings persistence) and record outcomes in docs/fix_summaries/modern_responsive_ui_fix_summary.md.

---

## Dependencies & Execution Order

- Setup (Phase 1) → Foundational (Phase 2) → US1 (P1) → US2 (P2) → US3 (P3) → Polish.
- User stories can run in parallel after Phase 2 if staffed, but US1 is MVP and should complete first.
- Within each story, follow task order listed; [P] tasks can run in parallel when touching different files.

## Parallel Execution Examples

- Foundational: T003 and T004 can proceed in parallel (different new QML helpers).
- US1: T010 and T011 can run in parallel; T012 depends on T009 and T010.
- US2: T015 and T016 can proceed in parallel; T018 follows theme/token readiness from T003.
- US3: T019 and T020 can proceed in parallel; T021 follows once navigation impacts are understood.

## Implementation Strategy

- MVP: Complete Phases 1–2, then US1; stop to validate AA responsive + consent on single/dual displays.
- Incremental: After MVP, deliver US2 (settings persistence) then US3 (home simplification); polish last.
- Keep each story independently testable; avoid introducing new feature tiles or non-scoped features.
