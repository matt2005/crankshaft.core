# Quickstart — Modern Responsive UI (AndroidAuto + Settings)

## Build & Run

### 1. Checkout the feature branch
```bash
git checkout 005-modern-responsive-ui
```

### 2. Build UI (WSL)
```bash
wsl bash -lc "cd /mnt/c/Users/matth/install/repos/opencardev/oct_2025/crankshaft-mvp && ./scripts/build.sh --component ui --build-type Debug"
```

### 3. Run UI (VNC debug example — 1024×600 default)
```bash
wsl bash -lc "cd /mnt/c/Users/matth/install/repos/opencardev/oct_2025/crankshaft-mvp && QT_DEBUG_PLUGINS=0 ./build/ui/crankshaft-ui -platform vnc:size=1024x600,port=5900"
```

**Alternative sizes for testing:**
- Small (800×480): `-platform vnc:size=800x480,port=5900`
- Large (1920×1080): `-platform vnc:size=1920x1080,port=5900`

Connect with a VNC viewer: `localhost:5900`

## Validation Checklist

### A. Home Screen Simplification ✓
- [ ] **Only AA and Settings tiles visible** on home screen
- [ ] No Navigation, Phone, Media, or Tools tiles present
- [ ] Tiles are responsive 2-column layout; reflow cleanly at 800×480, 1024×600, 1920×1080
- [ ] Tile minimum tap targets are 44×44 px (visually much larger)

**Expected:** Home displays minimal surface with two large, easily tappable cards.

### B. Settings UI & Persistence ✓
1. **Open Settings** (settings cog in header or Settings tile)
2. **Theme Toggle:**
   - [ ] Switch between Light and Dark themes
   - [ ] Change applies within **≤500 ms** (target: ≤150 ms animation)
   - [ ] Observe status bar, tile backgrounds, and text colours update immediately
   - [ ] Close and reopen Settings; theme persists
3. **Language Selection:**
   - [ ] Select different language (e.g. German)
   - [ ] UI labels, buttons, consent messages update without restart
   - [ ] Close and reopen app; language setting persists
4. **Display Layout Preference:**
   - [ ] Select "Auto-responsive", "Primary Only", or other layout modes
   - [ ] Setting persists across restart
5. **Primary Display Selection:**
   - [ ] Available displays are enumerated with name and resolution
   - [ ] Select a different primary display
   - [ ] AA screen follows user selection
   - [ ] Setting persists across restart
6. **AA Data Sharing Consent:**
   - [ ] Toggle acceptance of data sharing
   - [ ] Consent state persists across restart
   - [ ] Blocking AA launch when consent is revoked

**Expected:** Settings apply immediately (no restart needed); persistence verified across app restart.

### C. Android Auto Responsive Layout ✓
1. **Launch Android Auto** (AA tile or programmatic launch)
2. **Single Display (1024×600 or other):**
   - [ ] AA window renders with responsive layout
   - [ ] Tap targets for AA controls are ≥44×44 px
   - [ ] Launch completes within **≤5 s** (observe console timing)
3. **Dual Display (if available):**
   - [ ] Primary display shows AA full-screen (or maximized)
   - [ ] Secondary display shows status bar, quick controls, or complementary UI
   - [ ] Change "Primary Display" in Settings; AA moves to selected primary
4. **Responsive Breakpoints:**
   - [ ] Test at 800×480 (compact), 1024×600 (standard), 1920×1080 (large)
   - [ ] UI elements scale appropriately; no clipping or overflow
   - [ ] Text remains readable at all sizes

**Expected:** AA launches and adapts layout based on primary display size and user preference.

### D. Consent & Safety Gating ✓
1. **Revoke AA Consent** (Settings → Data Sharing Consent toggle OFF)
2. **Attempt AA Launch:**
   - [ ] "Consent Required" message appears
   - [ ] Launch is blocked with clear explanation
3. **Provide Consent** (toggle ON whilst stationary)
4. **Relaunch AA:**
   - [ ] Launch succeeds
   - [ ] AA becomes active

**Note:** Vehicle movement detection is simulated; stationary = true in test environment.

**Expected:** Consent flow is enforced; user cannot bypass requirement.

### E. Theme Swap Performance ✓
1. **Monitor Theme Change Latency:**
   - [ ] Open Settings and toggle theme
   - [ ] Visual feedback (colour animation) should be immediate (≤150 ms)
   - [ ] Complete theme swap (all UI elements) should be ≤500 ms
   - [ ] Check browser or app console for log entries with timestamps

**Expected:** Theme swap is smooth and responsive; user sees immediate visual feedback.

### F. Navigation Restrictions ✓
1. **Attempt Deep Links to Non-Existent Screens:**
   ```bash
   # If navigation URLs are exposed, try:
   # /home/navigation, /home/phone, /home/media, etc.
   ```
2. **Expected:** Routes are blocked or hidden; user cannot navigate to unimplemented features
3. **Console:** Look for warnings like `[HomeScreen] Navigation to unavailable route: navigation`

### G. Settings String Translations ✓
- [ ] All settings labels are translated to en-GB
- [ ] No "qsTr()" fallback strings visible in UI
- [ ] Example translations:
  - Theme description: "Use dark theme for the interface"
  - Language description: "Choose the language for the user interface"
  - Layout description: "Choose between auto-responsive or fixed layout"
  - Display description: "Select which display to show main content"
  - AA consent: "Allow Android Auto to access vehicle data for projections"

### H. Logging & Telemetry ✓
1. **Check Console Output for Structured Logs:**
   - [ ] Theme changes log: `[timestamp] [INFO] [settings_changed] Setting updated | Key: ui.theme.dark, Old: light, New: dark`
   - [ ] AA state transitions log: `[timestamp] [INFO] [aa_state_transition] State changed | previousState: available, newState: launching`
   - [ ] Display changes log: `[timestamp] [INFO] [display_changed] Primary display changed | previousDisplayId: hdmi-1, newDisplayId: hdmi-2, displayName: HDMI-2, resolution: 1920x1080`
2. **Expected:** Logs are structured with ISO timestamps, levels (INFO/WARN/ERROR), and JSON context

### I. Unit Tests ✓
```bash
# Run layout tests (breakpoints, tap targets, typography, animations)
wsl bash -lc "cd /mnt/c/Users/matth/install/repos/opencardev/oct_2025/crankshaft-mvp && ctest --test-dir build --output-on-failure -R 'LayoutTests'"

# Run settings tests (model properties, callbacks, persistence, theme animation)
wsl bash -lc "cd /mnt/c/Users/matth/install/repos/opencardev/oct_2025/crankshaft-mvp && ctest --test-dir build --output-on-failure -R 'SettingsTests'"

# Run all tests
wsl bash -lc "cd /mnt/c/Users/matth/install/repos/opencardev/oct_2025/crankshaft-mvp && ctest --test-dir build --output-on-failure"
```

**Expected:** All QML/QtTest cases pass; no failures or warnings.

## Summary of Completed Features

✅ **User Story 1:** Android Auto responsive layout, consent gating, ≤5 s launch time  
✅ **User Story 2:** Settings UI for theme, language, layout, display, AA consent with immediate persistence  
✅ **User Story 3:** Home simplified to AA + Settings only, responsive tiles at 800×480 / 1024×600 / 1920×1080  
✅ **Testing:** QML/QtTest coverage for layout, theme swap (≤500 ms), settings persistence, tap targets, AA timing  
✅ **Logging:** Structured logs for AA state, settings changes, display configuration  
✅ **i18n:** All labels and messages translated to en-GB with Strings singleton  
✅ **Design Tokens:** Theme.qml provides unified palette, spacing, typography, animation durations  

## Troubleshooting

**AA does not launch:**
- Check consent: Settings → Data Sharing Consent should be ON
- Check vehicle status: Should be stationary (default in test)
- View console logs for error details

**Theme change is slow:**
- Ensure all animations use `Theme.animationFeedback` (150 ms) or `Theme.animationDuration` (200 ms)
- Check for blocking operations on main thread (should not occur)

**Settings don't persist:**
- Verify SettingsRegistry paths (typically ~/.local/share/Crankshaft/settings.ini on Linux)
- Check file permissions; registry file should be writable

**Tiles are clipped or overlap:**
- Resize window or change VNC resolution to trigger responsive reflow
- Check that Flow layout is properly configured in HomeScreen.qml

**Translations missing:**
- Ensure `ui/i18n/ui_en_GB.ts` is compiled (run `cmake --build build --target translations`)
- Restart app after translation updates
