# Plan — Update App Icons (Cross-Platform)

Created at: 2026-01-16T06:12:53Z
Last updated at: 2026-01-16T06:12:53Z

## Goal
Replace the default Very Good Ventures (unicorn) launcher icon with Taskly branding across all supported platforms (Android, iOS, Web, Windows, macOS, Linux).

## Scope (minimal)
- Add a repeatable, repo-friendly way to generate icons.
- Update launcher icons for all platforms produced by Flutter builds.

## Non-goals
- Redesigning the app’s visual identity.
- Changing native splash screen behavior beyond the launcher icon shown on Android 12+.

## Approach (recommended)
Use `flutter_launcher_icons` so icons are generated consistently for all platforms from a single source image.

## Inputs Needed
- Source app icon artwork (ideally 1024×1024 PNG, square, no transparency issues).
- Optional: separate adaptive icon foreground/background for Android.

## Deliverables
- `pubspec.yaml` updated with `flutter_launcher_icons` config.
- One or more icon source images under `assets/`.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase and follow established conventions.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- When the phase is complete, update this file immediately (same day) with:
  - Last updated at: (UTC)
  - A short summary of what was done
  - Phase completion timestamp (UTC)

## Steps
1. Add `flutter_launcher_icons` as a dev dependency.
2. Add minimal `flutter_icons` config in `pubspec.yaml` targeting:
   - Android (including adaptive icon if provided)
   - iOS
   - Web
   - Windows
   - macOS
   - Linux
3. Add/confirm icon source image(s) under `assets/` and ensure they are declared if required.
