# Template V2 Migration (Remaining Templates, excluding Someday) — Completion Summary

Implementation date: 2026-01-13 (UTC)

## What shipped
- Kept existing template IDs and specialized `SectionDataResult` variants (no `_v2` ID churn).
- Support blocks (`issues_summary`, `allocation_alerts`, `check_in_summary`):
  - Respect `SectionRef.overrides.title` by plumbing `section.title` into each renderer.
  - Added `templateId` guards in `SectionWidget` so result variants cannot be rendered under the wrong template.
- `allocation`:
  - Added `templateId` guard in `SectionWidget`.
  - Added a dedicated `requiresValueSetup` gateway UI (replaces misleading empty-state messaging).
- `entity_header`:
  - Added `templateId` guard in `SectionWidget`.
  - Implemented `showMetadata` behavior by plumbing through to `EntityHeader`.
- Added focused tests:
  - Strict param decoding for `SectionTemplateParamsCodec`.
  - `SectionWidget` routing guards + title override + allocation gateway + entity header metadata hiding.

## Validation
- `flutter analyze`: clean.
- Recorded tests: success (0 failures). Example run output: `build_out/test_runs/20260112_142451Z/summary.md`.

## Known gaps / follow-ups
- Support-block action callbacks are still hard-coded to `Routing.toScreenKey(...)` inside the renderers (kept for backward compatibility); consider optional callback injection later if/when you want renderer-level decoupling.
- Allocation excluded-task rendering (`showExcludedSection`, `excludedTasks`) is still not surfaced in the UI; implement later if/when the UX calls for it.
