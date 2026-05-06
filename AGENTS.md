# AGENTS.md — RC Remote Contributor Guidelines

## Project Overview

RC Remote is a Flutter app for controlling a Bluetooth serial robot. It uses a **Nothing OS–inspired dot-matrix aesthetic** — everything visual is built from dots, not solid shapes or lines.

The app runs in **landscape-only** mode on Android.

---

## Architecture

```
lib/
├── main.dart                  # Entry point, orientation lock, BT init
├── app.dart                   # MaterialApp + providers setup
├── bluetooth/
│   └── bluetooth_service.dart # BT connection, command sending, mode switching
├── voice/
│   └── voice_commands.dart    # Speech-to-text → command mapping
├── animations/
│   └── animations.dart        # All dot-matrix animations (center area)
├── screens/
│   └── home_screen.dart       # Main (and only) screen
├── widgets/
│   ├── arrow_button.dart      # Directional control buttons
│   ├── rounded_panel.dart     # Glassmorphic panel container
│   ├── top_bar.dart           # Top bar with BT status + actions
│   └── bluetooth_sheet.dart   # Bottom sheet for device discovery
└── theme/
    └── colors.dart            # Color tokens + dot-arrow patterns
```

### State Management

- **Provider + ChangeNotifier** — `BluetoothService` and `VoiceCommandService` are the two providers.
- Local UI state (active mode, button pressed states) lives in `_HomeScreenState`.
- Do **not** add new state management libraries.

---

## Bluetooth Commands

The Arduino firmware supports **exactly these commands**:

| Command | Char | Description |
|---------|------|-------------|
| Forward | `U`  | Move forward |
| Backward | `D` | Move backward |
| Left | `L`    | Turn left |
| Right | `R`   | Turn right |
| Stop | `S`    | Stop all movement |

**Do NOT add diagonal commands** (forward-left, backward-right, etc.). The Arduino code does not handle them. If you need diagonal behavior in a sensor mode (like gyro), pick the **dominant axis** and send only one of `U`, `D`, `L`, `R`.

Mode commands:
- `MODE_MANUAL` — manual D-pad control
- `MODE_OBSTACLE` — obstacle avoidance
- `MODE_FOLLOW` — human following

---

## Animation Guidelines

### The Dot-Matrix Rule

Every visual element in the center area **must be built from dots** (circles drawn via `canvas.drawCircle`). No solid lines, no rectangles, no built-in Flutter widgets in the animation area.

### Creating New Dot-Matrix Animations

When creating or modifying a dot-matrix animation, follow these rules:

1. **No hard square boundaries** — Dots must NOT be clipped to a rigid square grid. Use a **circular/radial layout** or apply **edge fading** so dots at the corners and edges gradually become transparent. The animation should feel organic and expansive, not boxed in.

   ```dart
   // BAD — hard square grid, all dots have equal visibility
   for (int row = 0; row < rows; row++) {
     for (int col = 0; col < cols; col++) {
       canvas.drawCircle(offset, radius, paint); // same alpha for all
     }
   }

   // GOOD — radial fade, corners dissolve naturally
   for (int row = 0; row < rows; row++) {
     for (int col = 0; col < cols; col++) {
       final dx = (col - center).toDouble();
       final dy = (row - center).toDouble();
       final dist = sqrt(dx * dx + dy * dy);
       final maxDist = center.toDouble();
       
       // Skip dots outside the circular boundary
       if (dist > maxDist) continue;
       
       // Fade alpha as dots approach the edge
       final edgeFade = (1.0 - (dist / maxDist)).clamp(0.0, 1.0);
       final alpha = baseAlpha * edgeFade;
       
       final paint = Paint()..color = color.withValues(alpha: alpha);
       canvas.drawCircle(offset, radius, paint);
     }
   }
   ```

2. **Size should feel generous** — The existing animations use `Size(140, 140)` for square animations and `Size(140, 60)` for wide ones (voice equalizer). Keep new animations in the same range. The animation should breathe within the center column — don't go smaller than `140`.

3. **No solid lines** — Do not use `canvas.drawLine()` for crosshairs, axes, or borders. If you need a visual axis, build it from dots:
   ```dart
   // BAD
   canvas.drawLine(Offset(0, cy), Offset(w, cy), axisPaint);
   
   // GOOD — dotted axis
   for (double x = startX; x <= endX; x += spacing) {
     canvas.drawCircle(Offset(x, cy), 1.0, axisPaint);
   }
   ```

4. **Color rules**:
   - Active/highlighted dots: `AppTheme.accentRed` with varying alpha
   - Inactive/background dots: `Colors.white` with low alpha (0.04–0.2)
   - Never use raw colors like `Colors.red` or `Color(0xFFFF0000)`

5. **Animation controllers**: Use `SingleTickerProviderStateMixin`. Always dispose controllers. Use `repeat(reverse: true)` for pulsing effects.

6. **`didUpdateWidget` for togglable animations** — If your animation has an `isActive` prop, override `didUpdateWidget` to start/stop the controller when it changes:
   ```dart
   @override
   void didUpdateWidget(MyAnimation oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (widget.isActive != oldWidget.isActive) {
       if (widget.isActive) {
         _ctrl.repeat(reverse: true);
       } else {
         _ctrl.stop();
       }
     }
   }
   ```

### Dot Size & Spacing Reference

These are the actual values used in existing animations — match them for visual consistency:

| Parameter | Radar | Tracker | Car (Normal) | Voice Equalizer |
|-----------|-------|---------|-------------|------------------|
| Dot radius | `1.8` | `2.5` | `3.5` | `3.0` |
| Grid spacing | radial `16.0` per ring | manual offsets | `9.0` gridScale | `9.0` X/Y spacing |
| Inactive alpha | `0.2` | `0.2` | n/a (static white) | edge-faded `0.5–1.0` |
| Active alpha | `0.3–1.0` (sweep) | `0.2–1.0` (pulse) | n/a | `0.5–1.0` |
| Canvas size | `140×140` | `140×140` | `140×140` | `140×60` |

### Existing Animations Reference

| Mode | Animation Class | Style |
|------|----------------|-------|
| Normal | `NormalDotAnimation` | Static white dot-matrix car shape |
| Obstacle Avoiding | `RadarDotAnimation` | Rotating radar sweep across concentric rings |
| Human Following | `TrackerDotAnimation` | Pulsing lock-on brackets around a dot-matrix human figure |
| Voice Control | `DotMatrixVoiceAnimation` | Equalizer-style vertical bars made of dots |
| Background | `DotGrid` | Full-screen faint dot grid |
| Center halo | `RadialDotHaloPainter` | Concentric dot rings behind center animation |

Study these before creating new animations. Match the density, spacing, and alpha patterns.

---

## Code Style

### Comments

- **Do NOT use decorative dividers** like `// ── Section ──────────...──`
- **Do NOT add comments that restate what the code does** — e.g., `// Reset button states` before `_fwdActive = false` is obvious
- **DO add comments that explain WHY** something is done a non-obvious way — e.g., `// Flip sign because landscape mode inverts the X axis`
- **Keep `debugPrint` for command flow** — log what the user presses and what gets sent over Bluetooth (e.g., button press → `U`, voice match → `"forward"`, gyro tilt → `L`). Remove only verbose/spammy logs like per-frame sensor values or repeated status updates

### Haptic Feedback

- **All interactive buttons must have haptic feedback** — use `HapticFeedback.lightImpact()` on press for directional buttons (FWD, BACK, LEFT, RIGHT), and `HapticFeedback.mediumImpact()` for mode changes
- Import: `package:flutter/services.dart`

### Error Messages

- Never show raw SDK error strings to the user (e.g., `error_no_match`, `error_speech_timeout`)
- Always map them to human-readable messages
- Status text in the UI should be concise — `"No voice detected"` not `"Not recognised: \"some raw text\""`

### UI Consistency

- All status labels in the center animation area must use the **same styling**: same `Positioned(bottom: 5)`, same container with `AppTheme.accentRed.withValues(alpha: 0.1)` background, same font size and weight
- Mode switching should happen through the dropdown — do NOT add swipe gestures or hidden gestures for mode changes. All modes must be discoverable in the UI

---

## Mode System

All operating modes live in the `_modes` list in `home_screen.dart` and are selectable via the mode dropdown button. Modes include:

- **Normal** — manual D-pad control (default)
- **Voice Control** — speech-to-text commands
- **Obstacle Avoiding** — autonomous obstacle avoidance
- **Human Following** — autonomous follow mode
- **Gyro Control** — accelerometer-based tilt driving

When adding a new mode:
1. Add the mode string to `_modes` list
2. Add the corresponding animation in `animations.dart`
3. Handle mode-specific UI (extra buttons, labels) in the center column conditionally
4. Ensure switching away from the mode properly cleans up (cancel streams, stop listeners, send stop command)

---

## Testing

Before submitting:
```bash
flutter analyze    # must show: No issues found!
flutter test       # must show: All tests passed!
```

Do not submit PRs with analyzer warnings or test failures.

---

## PR Checklist

- [ ] `flutter analyze` — no issues
- [ ] `flutter test` — all tests pass
- [ ] No diagonal BT commands (only `U`, `D`, `L`, `R`, `S`)
- [ ] No raw SDK errors shown to user
- [ ] No decorative comment dividers
- [ ] Haptic feedback on all interactive buttons
- [ ] Dot-matrix animations use radial fade, no hard square edges
- [ ] No `canvas.drawLine()` in animations
- [ ] All modes accessible via dropdown (no hidden gestures)
- [ ] Tested on physical device in landscape mode
