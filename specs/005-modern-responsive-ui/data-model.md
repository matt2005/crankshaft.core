# Data Model — Modern Responsive UI (AndroidAuto + Settings)

## Entities

### Display
- Fields: `id` (string, required), `role` (enum: primary|secondary), `resolution` (width:int, height:int, required), `orientation` (enum: landscape|portrait), `dpi` (float, optional).
- Validation: width/height > 0; role unique per device; primary must exist.
- Relationships: UI windows target a Display; AA content binds to primary Display; status/controls optionally render on secondary.

### Setting
- Fields: `theme` (enum: light|dark, default light), `language` (locale string, default `en-GB`), `layout_preference` (enum: auto|primary_only|split_status), `primary_display_id` (string|null; user-selected), `aa_consent` (bool, default false), `persisted_at` (timestamp).
- Validation: locale must be supported; layout_preference must be compatible with detected displays (e.g., `split_status` requires secondary Display present); `primary_display_id` must match a detected Display when >1 present.
- Relationships: Settings are global; applied across all Displays.
- State transitions: `aa_consent` moves false -> true after parked consent; not reversible via UI without explicit reset.

### FeatureTile
- Fields: `name` (enum: androidauto|settings), `availability_state` (enum: available|unavailable|blocked), `visibility` (bool), `action` (callback/route id).
- Validation: Only defined tiles permitted; availability_state reflects runtime capability (e.g., AA blocked until consent+available).
- Relationships: Tiles derive state from Settings (consent) and platform signals (AA availability).

### UIState (aggregate)
- Fields: `active_display` (Display.id), `secondary_display` (Display.id|null), `primary_display_id` (Display.id|null), `theme`, `language`, `layout_mode` (derived from Settings + displays), `aa_status` (enum: available|blocked|unavailable|launching|active), `settings_dirty` (bool).
- Derived rules:
  - If only one Display -> layout_mode=primary_only, AA inline status.
  - If two Displays and layout_preference=split_status -> status/controls on secondary.
  - `primary_display_id` determines AA placement when multiple displays are present; falls back to detected primary when unset.
  - If AA unavailable -> `aa_status=unavailable`, tile disabled with message.

## Notes
- No new persistent schemas are introduced beyond existing config files; data model is logical for UI/state handling.
- All user-visible strings derived from these entities must be localised with default en-GB.
