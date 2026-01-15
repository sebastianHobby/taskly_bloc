# Phase 4 — Docs, Cleanup, and Verification

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for the phase.
- Exception (last phase): fix **any** `flutter analyze` error or warning (regardless of whether related to the phase).

## Goal

Finalize the change set:
- Ensure docs reflect the new screen meanings.
- Remove any unused code related to the Projects list template/destination.
- Validate behavior via analysis + quick manual smoke checks.

## Steps

1) Update architecture index
- Add a link to `doc/architecture/screen_purpose_concepts.md` from `doc/architecture/README.md`.

2) Cleanup
- Re-check whether the project list template is still referenced.
- Remove dead code only when confirmed unused.

3) Verification checklist (manual)
- Navigation:
  - Projects list is not a destination.
  - Project detail is still reachable from project tiles and links.
- Anytime:
  - Shows tasks + projects.
  - Shows the description line.
  - Filter toggle hides future-start items.
  - Focus cues visible.
  - Focus tasks sorted first within project.
- Scheduled:
  - Includes focus.
  - Focus cues visible.

4) Run `flutter analyze`
- Ensure clean analysis.

## Acceptance criteria

- Docs link exists in architecture README.
- No unused project list template code remains (when safe to remove).
- `flutter analyze` is clean.
- Manual smoke checklist passes.
