# Plan Template – Phase 01: <Phase Title>

Created at: 2026-01-12T00:00:00Z
Last updated at: 2026-01-12T00:00:00Z

## Goal

- <What this phase delivers>

## Scope

- In scope:
  - <Item>
- Out of scope:
  - <Item>

## Acceptance Criteria

- <Observable condition that proves the phase is done>

## Implementation Notes

- <Key design/architecture decisions>
- <Files/components expected to change>

## AI instructions

- Before implementing this phase:
  - Review `doc/architecture/` for relevant context and constraints.
  - Run `flutter analyze`.
- While implementing:
  - Keep changes aligned with the architecture docs.
  - If this phase changes architecture (boundaries, responsibilities, data flow, storage/sync behavior, cross-feature patterns), update the relevant files in `doc/architecture/` as part of the same change.
- Before finishing the phase:
  - Run `flutter analyze` and fix *all* errors and warnings.
  - Only then run tests (prefer the `flutter_test_report` task).

## Verification

- `flutter analyze`
- Tests: run the VS Code task `flutter_test_report` (preferred).

