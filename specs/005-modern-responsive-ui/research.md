# Phase 0 Research — Modern Responsive UI (AndroidAuto + Settings)

## Decisions

1) Decision: Use Qt Quick Controls 6 with Layouts (ColumnLayout/RowLayout/Flow) and responsive breakpoints at 800×480, 1024×600, 1920×1080 for home tiles and AA entry surfaces.
- Rationale: Native Qt layouts adapt to different aspect ratios without custom math; Flow handles wrapping tiles gracefully.
- Alternatives considered: Absolute positioning (rejected: brittle, poor responsiveness); custom grid manager (rejected: higher effort, duplicative of Qt layouts).

2) Decision: Handle multi-display by letting the user pick the primary `QScreen`; bind AA content to that primary and expose status/quick controls on secondary when present; fall back to inline status/controls on single-display setups.
- Rationale: Matches clarified spec, reduces distraction, and avoids mis-detection; uses Qt screen enumeration/window placement APIs with stored preference.
- Alternatives considered: Auto-assign only (rejected: mis-detection risk); spanning AA across both displays (rejected: complexity, distraction); mirroring both screens (rejected: redundant, unclear value).

3) Decision: Apply theming via shared design tokens (palette/spacing/typography) in a central QML singleton; support light/dark toggle and animate theme swap within 500 ms. Default locale en-GB; use `qsTr` with Qt Linguist `.ts` files for i18n.
- Rationale: Central tokens keep UX consistent and meet constitution UX consistency/accessibility; Qt Linguist is the project standard for translations.
- Alternatives considered: Per-component inline styles (rejected: inconsistent); external CSS-like system (rejected: extra dependency, not idiomatic Qt).
- Design token examples: spacing scale (8/16/24/32 px); min font 14 px, max 28 px; contrast ratio ≥4.5:1 for text; 44×44 px minimum tap targets; responsive breakpoints trigger layout reflow at 800×480, 1024×600, 1920×1080 (tile wrapping, margin/padding adjustment).

4) Decision: Persist settings (theme, language, display layout preference, AA consent flag) using existing settings/config service (QSettings-backed if available) with JSON export compatibility for tests.
- Rationale: Reuses existing persistence layer; JSON export makes tests deterministic and debuggable.
- Alternatives considered: New bespoke storage (rejected: needless duplication); storing in AA module only (rejected: settings are global to UI).

5) Decision: Gate AndroidAuto launch on a one-time consent captured while stationary/parked; cache the consent flag and expose a clear blocked state when movement is detected before consent.
- Rationale: Aligns safety/legal needs and spec; reduces friction after first acceptance.
- Alternatives considered: No consent (rejected: risk); always-on consent prompt (rejected: repeated friction).
