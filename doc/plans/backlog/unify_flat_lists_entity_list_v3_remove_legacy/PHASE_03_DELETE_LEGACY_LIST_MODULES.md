# Phase 03 — Delete Legacy List Modules (Full Removal)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Purpose
Remove all legacy list module support from domain + runtime + presentation.

## Work
1) Delete legacy sealed union cases and IDs:
   - Remove `ScreenModuleSpec.taskListV2` and `ScreenModuleSpec.valueListV2`.
   - Remove `SectionTemplateId.task_list_v2` and `SectionTemplateId.value_list_v2`.

2) Remove runtime support:
   - Delete interpreter registry branches for legacy modules.
   - Remove any legacy `SectionVm` variants if they exist.

3) Remove presentation support:
   - Remove renderer registry mapping for legacy modules.
   - Delete `TaskListRendererV2` and `ValueListRendererV2` if no longer referenced.

4) Remove style defaults:
   - Delete `EntityStyleResolver` defaults keyed by legacy IDs.

5) Codegen:
   - Run `build_runner` to regenerate Freezed/JSON outputs after removing union cases.

6) Ensure no legacy references remain:
   - Grep for `task_list_v2|value_list_v2|taskListV2|valueListV2|TaskListRendererV2|ValueListRendererV2`.

## Deliverables
- Legacy list modules no longer exist in the codebase.

## Acceptance Criteria
- Grep confirms no legacy identifiers in `lib/**`.
- App compiles.
- `flutter analyze` is clean.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Fix any analyzer errors/warnings caused by this phase’s changes.
- Run `build_runner` after union deletions.
- When complete, update this file with summary + `Completed at:` (UTC).
