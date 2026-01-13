# Someday V2 Full Migration — Summary

Implementation date (UTC): 2026-01-12

## What shipped

- Someday system screen cut over to the Unified Screen Model V2 using the `interleaved_list_v2` template.
- Layout uses `hierarchy_value_project_task` with pinned value headers, non-pinned project headers, and a single global Inbox group.
- Inbox semantics match the locked Someday rules: tasks with `projectId == null && startDate == null && deadlineDate == null`.
- Ephemeral section filters implemented (Value dropdown + Projects-only toggle) with the agreed behavior:
  - Selecting a Value hides the Inbox group.
  - Projects-only hides tasks without a project.
- Value ordering in hierarchy groups is stable and matches legacy intent (priority then name).

## Verification

- `flutter analyze`: no issues found.
- Recorded tests (`flutter_test_record`): passed (see `build_out/test_runs/20260112_141001Z/summary.md`).

## Follow-ups / Known gaps

- If other screens or features relied on the legacy `someday_backlog` template, they should now use V2 templates instead.
- Consider adding a focused widget test for the Someday filter bar + Inbox gating behavior if we want extra regression protection.
