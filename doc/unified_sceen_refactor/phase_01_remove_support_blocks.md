# Phase 01 — Remove SupportBlocks (Hard Delete) and Replace With Sections

## Goal

- **Delete** the concept of `supportBlocks` from the codebase.
- Preserve **all existing functionality** by re-introducing each support behavior as a **section template** rendered inline.

## Hard constraints
- No backwards compatibility.
- After phase completion: `flutter analyze` has **0 errors**.

## What this phase must eliminate

- No `supportBlocks` field anywhere (screens, workflows, content configs, DB converters).
- No `SupportBlock` symbols (models, services, renderers).
- No `SupportBlockComputer` or “support-block computation pipeline”.

## Summary of changes

### Delete
- `ScreenDefinition.supportBlocks` field.
- `SupportBlock` model types.
- `SupportBlockComputer` and any support-block computation in `ScreenDataInterpreter`.

Concrete (repo-verified) impact points to remove/update in this phase:

- Models/config
  - `lib/domain/models/screens/screen_definition.dart` (field + JSON)
  - `lib/domain/models/screens/content_config.dart` (`ContentConfig.supportBlocks`)
  - `lib/domain/models/screens/support_block.dart` (delete file)
  - `lib/domain/models/workflow/workflow_definition.dart` (`globalSupportBlocks`)
  - `lib/domain/models/workflow/workflow_step.dart` (`supportBlocks`)
- Domain services
  - `lib/domain/services/screens/screen_data.dart` (`supportBlocks` on `ScreenData`)
  - `lib/domain/services/screens/screen_data_interpreter.dart` (inject/compute support blocks)
  - `lib/domain/services/screens/support_block_computer.dart` (delete file)
  - `lib/domain/services/screens/support_block_result.dart` (delete file)
  - `lib/domain/services/attention/attention_evaluator.dart` (remove doc/comments referencing support blocks)
- Presentation
  - `lib/presentation/features/screens/widgets/support_block_renderer.dart` (delete file)
- DI
  - `lib/core/dependency_injection/dependency_injection.dart` (remove `SupportBlockComputer` registration)
- Persistence
  - `lib/data/features/screens/repositories/screen_definitions_repository_impl.dart` (stop reading/writing support blocks)
  - `lib/data/services/screen_seeder.dart` (stop seeding support blocks)
  - `lib/data/drift/converters/json_converters.dart` (remove any `List<SupportBlock>` converter)
  - `lib/data/drift/features/screen_tables.drift.dart` (remove JSON structure comment mentioning support blocks)
  - Any drift schema/table columns storing `render_mode`/support blocks should be handled per your DB approach (if stored inside JSON, update JSON only; if stored in separate columns, remove column in the later schema phase).

### Add/Replace
Introduce new **support section templates** (still represented temporarily using existing `Section` union if needed for compilation in this phase; later phases convert to `SectionRef`):

- `issues_summary`
- `check_in_summary`
- `allocation_alerts`
- `entity_header`

## Amendments (2026-01-08)

This phase must preserve the previous support-block UX while also enforcing these
updated semantics:

### 1) Everything is attention

- `issues_summary`, `check_in_summary`, and `allocation_alerts` must be driven by the
  attention system (rules + computed items + resolutions) where applicable.
- Do not keep or introduce parallel “evaluated alert” UI surfaces that duplicate the
  same signal.

### 2) Check-in summary becomes a global review ritual

- `check_in_summary` must represent a **single** review ritual due state.
- Review types are still individually toggleable via existing attention rule toggles
  (`AttentionRule.active`).
- The ritual cadence is global (not per-type `frequency_days`).

**Recommended persistence approach (accepted):**

- Add/seed a dedicated rule row (or otherwise ensure it exists) with:
  - `ruleKey: "review_ritual"`
  - `ruleType: review`
  - `triggerConfig: { "cadence_days": <int> }`
- Record completion/snooze resolutions against `entityId: "review_ritual"` so
  `getLatestResolution(ruleId, entityId)` is truly global.
- Continue to seed/keep the existing per-type review rules (e.g. values/progress/etc.)
  but treat them as toggles only.

**Canonical `action_details` keys (accepted):**

- Snoozing the ritual stores: `{ "snooze_until": "<ISO-8601 timestamp>" }`
- Dismissing other attention items stores: `{ "state_hash": "<stable fingerprint>" }`
- Completion-on-open (V2) records a `reviewed` resolution for the ritual against
  `entityId: "review_ritual"`.

**Auto-resolve on view (accepted):**

- The review ritual should be auto-resolved when **Review** is opened
  (screen loaded). This uses the same `reviewed` resolution mechanism so it will not
  re-surface until cadence elapses.

### Allocation evaluation model (accepted)

- Allocation warnings are not computed via the unified streaming attention context.
- Allocation service calls evaluator with allocation engine outputs (settings/excluded
  tasks) and receives a list of allocation attention items.

### 3) Allocation alerts must be dismissable attention items

- `allocation_alerts` must surface allocation warnings as `AttentionItem`s.
- Allocation warnings must support `dismissed` resolutions with state-hash invalidation
  (resurface only when relevant user-facing state changes).

## Step-by-step Implementation

### 0) Pre-flight: confirm search surface

Run searches and keep the result list open while refactoring:

- `SupportBlockComputer|SupportBlock\b|supportBlocks\b|support_blocks\b`

You should end Phase 01 with **zero matches** for those patterns.

### 1) Remove `supportBlocks` from screen model

Files:
- `lib/domain/models/screens/screen_definition.dart`

Actions:
- Remove the `supportBlocks` field from the data-driven variant.
- Remove JSON parsing/serialization support for `supportBlocks`.

Also remove (repo-verified):

- `lib/domain/models/screens/content_config.dart`: delete `supportBlocks` from `ContentConfig`.
- `lib/domain/models/workflow/workflow_definition.dart`: delete `globalSupportBlocks`.
- `lib/domain/models/workflow/workflow_step.dart`: delete `supportBlocks`.

Required follow-up:
- Update all callsites constructing `ScreenDefinition.dataDriven(...)`.
  - `lib/domain/models/screens/system_screen_definitions.dart`
  - Anywhere else found via search.

### 2) Delete SupportBlock code

Delete these repo-verified files:

- `lib/domain/models/screens/support_block.dart`
- `lib/domain/services/screens/support_block_computer.dart`
- `lib/domain/services/screens/support_block_result.dart`
- `lib/presentation/features/screens/widgets/support_block_renderer.dart`

Search for remaining references and remove:
- `SupportBlock`
- `supportBlocks`

Also remove:

- `lib/core/dependency_injection/dependency_injection.dart`: any `SupportBlockComputer` wiring.
- `lib/domain/services/attention/attention_evaluator.dart`: comments/mentions referencing support-block computation.

### 3) Add support section variants (temporary; chosen approach)

This plan chooses the **temporary Section-variant** approach for Phase 01 stability.
These variants are intentional scaffolding and must be deleted when Phase 02 replaces
`Section` with `SectionRef` + template registries.

- Add new variants to `lib/domain/models/screens/section.dart`:
  - `Section.issuesSummary({...})`
  - `Section.checkInSummary({...})`
  - `Section.allocationAlerts({...})`
  - `Section.entityHeader({...})`

Params should mirror existing SupportBlock data:
- `issuesSummary`: `entityTypes`, ordering, config
- `entityHeader`: `entityType`, `entityId`, flags (checkbox/metadata)

NOTE: Later phases will replace `Section` with `SectionRef`. This phase keeps compilation and behavior stable.

Important: the behavior currently covered by workflow support blocks must also be represented as sections/templates (even if those templates are only used inside workflow-related screens).

### 4) Teach `SectionDataService` to produce data for these support sections

Files:
- `lib/domain/services/screens/section_data_service.dart`

Add handling:
- `issuesSummary`:
  - compute from repositories with queries. Prefer direct repo calls.
  - do NOT depend on other sections’ computed outputs.
- `checkInSummary`:
  - compute due reviews count (or whatever current behavior is) using existing services.
- `allocationAlerts`:
  - compute allocation warnings using allocation services.
- `entityHeader`:
  - load the entity (project/value) and return a view model.

Add a new `SectionDataResult` variant per support section, or a generic "support" result.

Additionally remove support-block persistence wiring:

- `lib/data/features/screens/repositories/screen_definitions_repository_impl.dart`: stop parsing/writing `supportBlocks`.
- `lib/data/services/screen_seeder.dart`: stop seeding `supportBlocks`.
- `lib/data/drift/converters/json_converters.dart`: remove `List<SupportBlock>` converters.
- `lib/data/drift/features/screen_tables.drift.dart`: remove any docs/comments that claim screen content JSON includes support blocks.

### 5) Update ScreenDataInterpreter

Files:
- `lib/domain/services/screens/screen_data_interpreter.dart`

Actions:
- Remove `_computeSupportBlocks` and all references.
- Just combine section streams.

Also update `lib/domain/services/screens/screen_data.dart` to remove the `supportBlocks` field entirely.

### 6) Update rendering

Files:
- `lib/presentation/widgets/section_widget.dart`

Actions:
- Add rendering branches for the new section results:
  - Issues summary widget
  - Check-in summary widget
  - Allocation alerts widget
  - Entity header widget

Delete the support-block renderer usage entirely (you should have deleted `support_block_renderer.dart`). Any page that previously rendered support blocks must now render the equivalent section(s) in the section list.

Implementation guidance:
- For Phase 01, you can temporarily render these as simple widgets or reuse existing widgets.
- Keep the UI consistent with existing behavior.

### 7) Update system screen definitions

Files:
- `lib/domain/models/screens/system_screen_definitions.dart`

Actions:
- Replace `supportBlocks: [...]` with inline support sections placed at the top of the screen’s `sections: [...]` list.

Examples:
- Inbox: `issues_summary` + `task list`
- My Day: `check_in_summary` + `allocation_alerts` + `allocation`
- Project/Value detail dynamic screens: `entity_header` + lists

## Validation

Run:
- `flutter analyze`

Fix all refactor-caused issues.

## Phase completion checklist
- No `supportBlocks` field exists.
- No `SupportBlock` symbol exists.
- Equivalent behavior exists via support sections.
- `flutter analyze` passes.

## Recommended edit order (minimize analysis breakage)

1. Add support section variants + rendering stubs (compile first).
2. Update `system_screen_definitions.dart` to use support sections.
3. Remove support-block rendering path in presentation.
4. Remove support-block computation in interpreter + remove `ScreenData.supportBlocks`.
5. Delete support-block model + services + DI registrations.
6. Remove persistence support for support blocks.
7. Search again; ensure `SupportBlockComputer|SupportBlock\b|supportBlocks\b` returns zero matches.
