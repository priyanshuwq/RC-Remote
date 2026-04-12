# Smart Rover – Copilot Instructions

## Project Overview
Flutter app ("Smart Rover") that controls a Bluetooth serial robot from a mobile device. Users can send directional commands via a D-pad, select autonomous modes, and issue voice commands.

## Architecture

```
lib/
  main.dart                        # App entry, MultiProvider setup
  bluetooth/bluetooth_service.dart # Core BT logic + robot state (ChangeNotifier)
  voice/voice_commands.dart        # Speech-to-text → BT command mapping (ChangeNotifier)
  screens/home_screen.dart         # Primary (and only) screen; 897 lines
  widgets/dpad_control.dart        # Hold-to-repeat D-pad with per-button animations
  widgets/mode_buttons.dart        # Mode selector (Manual / Avoid / Follow)
```

**State management**: Provider only — `ChangeNotifier` + `MultiProvider`.  
`VoiceCommandService` depends on `BluetoothService` and is wired with `ChangeNotifierProxyProvider`.  
Screens access services via `context.read<T>()` (one-shot) and `context.watch<T>()` / `Consumer<T>` (reactive).

## Robot Commands

All commands are string constants defined in `BluetoothService`:

| Constant | Value | Purpose |
|---|---|---|
| `cmdForward/Backward/Left/Right/Stop` | `F/B/L/R/S` | Movement |
| `cmdModeManual/Obstacle/Follow` | `MODE_MANUAL/…` | Mode switches |
| `cmdPowerOn/Off`, `cmdReset` | `POWER_ON/…` | Power control |

New commands **must** be added as `static const String` in `BluetoothService` and referenced by name everywhere else.

## UI Conventions

- **Theme**: Dark Material 3, portrait-locked. Key colors are constants in `home_screen.dart`:  
  `_kBg = 0xFF121212`, `_kSurface = 0xFF1E1E1E`, `_kBtn = 0xFF2A2A2A`.
- All interactive widgets trigger haptic feedback via `vibration` before sending a BT command.
- Animations use `AnimationController` with `SingleTickerProviderStateMixin` / `TickerProviderStateMixin`.
- Widgets are `StatelessWidget` when possible; use `Consumer<BluetoothService>` inside for reactive state.

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run on connected device (Android primary target)
flutter run

# Build release APK
flutter build apk --release
```

Dart SDK constraint: `^3.11.1`. Target platform is Android; Bluetooth Serial is Android-only (`flutter_bluetooth_serial`).

## Permissions

`BluetoothService.requestPermissions()` requests Bluetooth, BLE scan/connect, Location, and Microphone in a single batch at app start. Any new feature requiring a permission must add it there.

## Integration Points

- **`flutter_bluetooth_serial`** – Classic BT (SPP profile); not BLE. Device pairing must be done in Android system settings; the app lists bonded devices and discovered devices separately.
- **`speech_to_text`** – Voice commands are phrase-matched via static `Map<String, String>` in `VoiceCommandService`. Add new phrases to `_voiceMap` or `_modeMap`.
- **`provider`** – Only state management library in use; do not introduce `riverpod`, `bloc`, or `get`.
