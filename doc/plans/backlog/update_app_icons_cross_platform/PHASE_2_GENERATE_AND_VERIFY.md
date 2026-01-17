# Plan — Update App Icons (Cross-Platform)

Created at: 2026-01-16T06:12:53Z
Last updated at: 2026-01-16T06:12:53Z

## Goal
Generate and verify the new launcher icons across all platforms.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase and follow established conventions.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Exception (last phase): fix ANY `flutter analyze` error or warning (even if unrelated).
- When the phase is complete, update this file immediately (same day) with:
  - Last updated at: (UTC)
  - A short summary of what was done
  - Phase completion timestamp (UTC)

## Steps
1. Run icon generation (typically `dart run flutter_launcher_icons`).
2. Verify outputs:
   - Android: launcher icon + Android 12 splash icon appearance.
   - iOS: app icon in simulator/device.
   - Web: `web/icons/*` and manifest references.
   - Windows/macOS/Linux: platform runner icons.
3. Sanity build/run on at least one target platform (Android emulator is enough for initial verification).
4. Document any required follow-ups (e.g., adaptive icon tuning, padding, background color).
