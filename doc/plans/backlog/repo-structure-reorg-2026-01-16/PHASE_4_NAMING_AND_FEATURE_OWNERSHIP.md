# Repo Structure Re-org — Phase 4: Naming & Feature Ownership (Higher Churn)

Created at: 2026-01-16T05:50:49Z
Last updated at: 2026-01-16T05:50:49Z

## Goal
Resolve recurring “where should this live?” confusion caused by naming collisions and feature-specific widgets in global buckets.

## Prerequisites
- Phase 1 decisions are complete.
- Verify each file/folder exists before editing.

## Proposed scope (requires explicit approval per item)
1. **STR-002: rename screen management feature folder**
   - Current: `lib/presentation/features/screens/` (screen management feature)
   - Proposed: rename to `lib/presentation/features/screen_management/` (or similar)
   - Update imports, feature barrel exports, and route wiring.

2. **STR-005: re-home values-alignment UI**
   - Move `lib/presentation/widgets/values_alignment/` and `lib/presentation/widgets/values_footer.dart` into a feature-owned location.
   - Decision point: `features/values/widgets/` vs a shared/widgets/values bucket depending on usage.

3. **STR-006: modals grouping**
   - Option A: create `lib/presentation/widgets/modals/` and move modal helpers + shared sheets.
   - Option B: keep widget sheets in widgets, move only pure helpers into `presentation/shared/utils/`.

## Acceptance criteria
- All moves keep imports consistent and don’t introduce cyclic deps.
- `flutter analyze` clean.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
