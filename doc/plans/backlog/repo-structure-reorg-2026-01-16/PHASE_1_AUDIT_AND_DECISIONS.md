# Repo Structure Re-org (Chat Proposals) — Phase 1: Audit & Decisions

Created at: 2026-01-16T05:50:49Z
Last updated at: 2026-01-16T05:50:49Z

## Goal
Confirm which of the proposed structure changes are real, safe, and worth doing.
This phase is explicitly about *verification* and *decision-making*.

## Non-goals
- No code moves, no refactors, no formatting-only churn.
- No test changes.

## Guardrails
- **Do not use git commands** (reset/checkout/revert/clean/commit/etc.) unless explicitly requested.
- **Verify file existence before acting**: use `file_search`, `list_dir`, and `grep_search` to confirm paths still exist (avoid stale references).
- **Prefer smallest churn**: move only what’s necessary and keep public APIs/import surfaces stable.

## Work items
1. **Re-review architecture constraints**
   - Re-read `doc/architecture/README.md` and `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`.
   - Reconfirm Presentation boundary rule (widgets/pages → BLoC only; no repo/service subscriptions).

2. **Re-scan key folders (current state)**
   - `lib/presentation/widgets/`
   - `lib/presentation/screens/`
   - `lib/presentation/features/screens/`
   - `lib/shared/` and `lib/core/`
   - `lib/l10n/` and any `core/l10n` remnants

3. **Candidate validation (from chat list)**
   - STR-001: `lib/shared/logging` shim
     - Confirm it is only re-exporting `core/logging` and confirm *no* imports use `package:taskly_bloc/shared/logging/...`.
   - STR-002: naming collision between `presentation/screens/` (USM runtime) and `presentation/features/screens/` (screen management feature)
     - Map route ownership and imports to estimate churn.
   - STR-003: `SectionWidget` ownership
     - Confirm `SectionWidget` is only used by USM templates/screens and tests.
   - STR-004: `presentation/widgets/problem/` ownership
     - Confirm which feature(s) reference it (attention/problems/etc.).
   - STR-005: `presentation/widgets/values_alignment/` and `values_footer.dart`
     - Confirm which feature(s) reference these.
   - STR-006: modal utilities
     - Confirm if `wolt_modal_helpers.dart` and sheets are used across features or tied to one.
   - STR-007: legacy stub `presentation/widgets/views/views.dart`
     - Confirm whether it’s imported anywhere.
   - STR-008: l10n convention
     - Confirm canonical import is `package:taskly_bloc/l10n/l10n.dart` (and update docs if still referencing `core/l10n`).

4. **Add any “new candidates” discovered during audit**
   - Only if they are clearly mis-homed and low risk.
   - Capture each candidate with:
     - Proposed new home
     - Rationale
     - Estimated churn (imports/touch points)
     - Risk level

## Deliverable (end of phase)
A short “decision list” that finalizes which options to implement in phases 2–4.

## AI instructions (required)
- Run `flutter analyze` after any phase change.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
