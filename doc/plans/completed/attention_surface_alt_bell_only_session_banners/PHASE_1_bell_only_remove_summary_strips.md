# Plan Phase 1: Bell-only indicator, remove/disable summary strips

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T02:12:38Z

## Goal

Ensure attention is surfaced via the **AppBar bell only** (badge + halo), and remove/disable any persistent summary strip modules.

## Scope

- Remove summary strip modules (e.g., `attentionBannerV2`) by editing **typed** system `ScreenSpec`s (via the system screen catalog), where present.
- Ensure the bell is present on navigation screens (except inbox if that rule still applies).
- Do not add banners in this phase.

## Architecture notes

- Follow UX-ALT-103: make changes in typed specs (avoid stringly-typed identifiers) and keep shipped `screenKey` values stable.

## Acceptance criteria

- My Day / Anytime / Scheduled do not show a summary strip module.
- Bell shows count + max severity halo consistently.
- No new analyzer issues introduced.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes.
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: 2026-01-16T02:12:38Z

Summary:
- Removed `attentionBannerV2` header modules from typed system screen specs (My Day, Anytime, Scheduled), leaving the bell as the sole persistent attention surface.
