# Option L — Dedicated Hierarchy Template — Completion Summary

Implementation date (UTC): 2026-01-13T00:00:00Z

## What shipped
- Added a new Unified Screen template: `hierarchy_value_project_task_v2`.
- Introduced typed params `HierarchyValueProjectTaskSectionParamsV2` and strict decode/encode support.
- Added a dedicated interpreter and presentation routing so the template renders via `SectionWidget`.
- Migrated the Someday screen to use the new dedicated hierarchy template.

## Notes / follow-ups
- This template currently reuses the existing `interleaved_list_v2` runtime pipeline by adapting params; it is primarily a “first-class alias” for hierarchy UX.
- Migrating My Day (allocation) onto the same hierarchy renderer/template is a separate follow-up because allocation currently includes excluded-task UX that this template does not model.
