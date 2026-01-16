# Repo Structure Re-org — Phase 2: Low-Risk Cleanups

Created at: 2026-01-16T05:50:49Z
Last updated at: 2026-01-16T05:50:49Z

## Goal
Do the smallest, safest cleanups that reduce confusion without introducing broad import churn.

## Prerequisites
- Phase 1 decisions are complete.
- Confirm each target file/folder still exists via `file_search`/`list_dir`.

## Proposed scope (expected)
1. **STR-001 (if approved): remove unused shim folder**
   - Remove `lib/shared/logging/` if it is purely a re-export and has no direct imports.
   - Ensure `core/logging` remains the canonical import.

2. **STR-007 (if approved): remove dead stub**
   - Remove `lib/presentation/widgets/views/views.dart` if unused.
   - If it is used, replace it with a meaningful barrel (only with explicit approval).

3. **Documentation alignment (if needed)**
   - Update README/docs to match reality (e.g. l10n import path).

## Notes
- Prefer deletions through PowerShell if the user’s workflow requires it.
- Keep changes surgical; avoid opportunistic formatting.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
