# Repo Structure Re-org — Phase 3: Unified Screen Model (USM) Widget Ownership

Created at: 2026-01-16T05:50:49Z
Last updated at: 2026-01-16T05:50:49Z

## Goal
Move USM-specific rendering infrastructure out of the global widget bucket into USM-owned folders to reduce ambiguity.

## Prerequisites
- Phase 1 decisions are complete.
- Verify each file’s existence and current usage with `file_search`, `list_code_usages`, and `grep_search`.

## Proposed scope (requires explicit approval)
1. **STR-003: move `SectionWidget`**
   - Move `lib/presentation/widgets/section_widget.dart` → `lib/presentation/screens/widgets/section_widget.dart`.
   - Update imports from templates (e.g. `lib/presentation/screens/templates/...`) and any tests.
   - Decide whether to keep a re-export in `lib/presentation/widgets/widgets.dart` (prefer: no re-export unless there is broad non-USM usage).

2. **STR-004: move problem widgets (if they are feature-owned)**
   - If problem widgets are only used by Attention: move `lib/presentation/widgets/problem/` → `lib/presentation/features/attention/widgets/problem/`.
   - If multiple features use them: move to `lib/presentation/shared/widgets/problem/`.

## Acceptance criteria
- No presentation layer boundary violations introduced.
- `flutter analyze` clean.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
