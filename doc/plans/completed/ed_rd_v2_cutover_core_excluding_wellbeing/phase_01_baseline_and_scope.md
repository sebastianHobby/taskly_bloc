# ED/RD + V2 Cutover (Core) — Phase 01: Baseline & Scope

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal

- Establish the *delta-based* plan baseline: what already exists in this repo for V2 screens and entity ED/RD, and what remains to finish the cutover.

## Scope

- In scope:
  - Confirm the current “V2 screen path” for system screens (routing → spec lookup → unified rendering).
  - Identify remaining legacy/parallel screen stacks that can be removed safely.
  - Confirm the current ED/RD pattern for `task`, `project`, and `value` (editor sheets + route-based details).
  - Identify required route convention deltas (notably the remaining `/label/:id` route).
- Out of scope:
  - Any work related to journals or trackers (UI, domain models, screens, templates, specs).
  - Any new architectural pattern that is not already established in `doc/architecture/`.

## Current State (Observed)

- System screens are routed via a convention-based catch-all route (`/:segment`) and built through `Routing.buildScreen`.
- System screens are defined as typed `ScreenSpec`s (see `SystemScreenSpecs`) and rendered via `UnifiedScreenPageFromSpec`.
- Entity detail routes exist for `/task/:id`, `/project/:id`, `/value/:id`.
- A legacy, parallel screen pipeline existed but was unused by current routing (removed as part of Phase 03 cleanup).

Note (2026-01-14): the legacy pre-`ScreenSpec` screen pipeline referenced by
older drafts is now deleted; only the typed `ScreenSpec` pipeline remains.
- There is still a `/label/:id` route, but the entity builder registry and `Routing.buildEntityDetail` do not include `label`.

## Decisions / Constraints

- This plan is explicitly **delta-based**: it should only propose changes that are required relative to current repo state.
- This plan must exclude all journal/tracker work. If any removal or stubbing is required to complete the core cutover, call it out as a dependency or separate plan.

### Confirmed design decisions (locked)

- **Label route**: Option A — remove `/label/:id` entirely.
- **Legacy pre-`ScreenSpec` screen stack**: delete legacy files from the repo. Note: by the time this plan is implemented, some of these files may already be deleted; implementation should be resilient (delete-if-exists).
- **Task routing semantics**: task is **editor-only**. Visiting `/task/:id` always opens the editor sheet; there is no separate read-only task detail page.
- **Project vs Value UX**: keep them **identical** (same action locations, menu structure, loading/error/empty patterns).
- **Completion definition**: *0 legacy screen-pipeline files remain in the repo* (not just “unreachable”).

## Acceptance Criteria

- A concrete list of remaining deltas is agreed (routing, entity ED/RD, and cleanup).
- Journals/trackers are explicitly excluded from all phases.

## Implementation Notes

- Primary references:
  - `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`
  - Existing cutover summaries under `doc/plans/completed/` (unified screen model V2, template V2 migrations)
  - Backlog decisions already recorded for ED/RD contracts and screen migration.

## AI instructions

- Before implementing this phase:
  - Review `doc/architecture/` for relevant context and constraints.
  - Run `flutter analyze`.
- While implementing:
  - Keep changes aligned with the architecture docs.
  - If this phase changes architecture (boundaries, responsibilities, data flow, storage/sync behavior, cross-feature patterns), update the relevant files in `doc/architecture/` as part of the same change.
- Before finishing the phase:
  - Run `flutter analyze` and fix *all* errors and warnings.
  - Only then run tests (prefer the `flutter_test_record` task).

## Verification

- `flutter analyze`
- Tests: `dart run tool/test_run_recorder.dart -- <args>`
