# Editor + detail template contracts (FormBuilder-first)

Created at: 2026-01-13 (UTC)
Last updated at: 2026-01-14 (UTC)

## Scope
This document captures **confirmed architecture decisions** for:
- Editor flows (create/edit) implemented with `flutter_form_builder`.
- Read/composite entity detail pages that will be rendered via templates/modules.

These contracts are intended to be referenced by per-screen migration decisions.

## Confirmed decisions

## Current implementation status (snapshot)

This section is descriptive (non-normative): it records what exists in the repo
today so it’s easy to see which parts of the contract are already satisfied and
which are still “target state”.

As of: 2026-01-14 (UTC)

### Core entities (task/project/value)

**Entry points (ED)**
- ✅ Centralized editor launching exists via `EditorLauncher`.
- ✅ All core entity editors use `flutter_form_builder`.

**Surface policy (RD)**
- ✅ Task is effectively `editorOnly` in navigation: `/task/:id` opens the editor
  modal and returns to the previous route.
- ✅ Project and value are `detailAndEdit`: they have a unified detail page and
  launch the editor via `EditorLauncher`.

**Contract alignment checklist**

| Contract item | Task | Project | Value |
| --- | --- | --- | --- |
| ED-A1-A — Explicit `*Draft` → `*Command` | ✅ | ✅ | ✅ |
| ED-A2-A — Domain validation → field-addressable UI mapping | ✅ | ✅ | ✅ |
| ED-A3-A — Typed, centralized field keys | ✅ | ✅ | ✅ |
| ED-B1-A — Single reusable “form module” per entity | ✅ (`TaskForm` reused for create/edit) | ✅ (`ProjectForm` reused for create/edit) | ✅ (`ValueForm` reused for create/edit) |
| ED-B2-A — Template owns actions; form module is fields-only | ❌ (forms currently include close/delete chrome) | ❌ | ❌ |
| RD-C2-B — Detail template does not embed editor UI | ✅ (task has no detail surface; editor-only) | ✅ (detail launches editor) | ✅ (detail launches editor) |

**Key implementation files**
- Task editor route: `lib/presentation/features/tasks/view/task_editor_route_page.dart`
- Editor entry points: `lib/presentation/features/editors/editor_launcher.dart`
- Draft/command/validation core: `lib/domain/core/editing/`
- Validation → FormBuilder mapping: `lib/presentation/shared/mixins/form_submission_mixin.dart`, `lib/presentation/shared/validation/validation_error_message.dart`
- Task editor form: `lib/presentation/features/tasks/view/task_detail_view.dart`, `lib/presentation/features/tasks/widgets/task_form.dart`
- Project detail + editor form: `lib/presentation/features/projects/view/project_detail_unified_page.dart`, `lib/presentation/features/projects/view/project_create_edit_view.dart`, `lib/presentation/features/projects/widgets/project_form.dart`
- Value detail + editor form: `lib/presentation/features/values/view/value_detail_unified_page.dart`, `lib/presentation/features/values/view/value_detail_view.dart`, `lib/presentation/features/values/widgets/value_form.dart`

### ED-A1-A — Draft → Command architecture
- Each editor builds and holds an explicit `*Draft` state.
- On save, the editor produces a `Create*Command` or `Update*Command`.
- Persistence logic consumes commands; UI does not write directly to repositories.

### ED-A2-A — Domain validation + UI mapping
- Domain validation returns a **structured, field-addressable** error model.
- UI maps domain errors to FormBuilder field errors (plus optional form-level errors).
- No stringly-typed “error messages only” contract between domain and UI.

### ED-A3-A — Typed field keys
- Each editor defines typed, centralized field keys (no ad-hoc string literals).
- Field keys are stable identifiers used by:
  - FormBuilder field names
  - validation mapping
  - test assertions

### ED-B1-A — Single form module per entity
- For each entity type, there is a single reusable “form module” widget responsible for:
  - rendering the fields
  - binding the `*Draft` to FormBuilder
  - emitting draft updates
- This module is reused across create/edit entry points (sheet/page).

### ED-B2-A — Template owns actions
- The containing template owns the action surface (save/cancel/delete placement).
- The form module focuses on fields; it does not own app bar actions or CTA layout.
- The editor template interacts with the form via a narrow interface (e.g. validate/save).

### RD-C1-A — Entity detail templates are module-composed
- Entity read/composite pages are built from modules (header/primary slots) rather than bespoke screens.
- Entity detail templates define a stable contract for:
  - required inputs (entity id / entity)
  - supported actions (edit/delete)
  - module composition points

### RD-C2-B — Entity detail template does not embed editor UI
- Detail templates do not contain the editor form itself.
- Editing is launched via the standardized editor entry points (modal/page) and returns updates via state refresh.

## Locked-in per-entity decisions

### ED-01 — Task editor (locked)
- Public entry point remains `EditorLauncher.openTaskEditor(...)`.
- Implementation delegates to `EditorTemplateSpec.taskV1` (one editor template per entity).
- `TaskForm` becomes the reusable `TaskFormModule` (fields only); template owns save/cancel/delete.

### ED-02 — Project surfaces + editor (locked)
- Surface policy: `detailAndEdit`.
- Detail: `EntityDetailTemplateV1(project)` shows project header + linked tasks below.
- Edit: `EditorTemplateSpec.projectV1` edits *only* the project entity (no embedded task editor).
- `EditorLauncher.openProjectEditor(...)` delegates to `EditorTemplateSpec.projectV1`.
- `ProjectForm` becomes the reusable `ProjectFormModule` (fields only); template owns save/cancel/delete.

### ED-03 — Value surfaces + editor (locked)
- Surface policy: `detailAndEdit`.
- Detail: `EntityDetailTemplateV1(value)` shows value header + linked projects + tasks.
- Edit: `EditorTemplateSpec.valueV1` edits *only* the value entity.
- `EditorLauncher.openValueEditor(...)` delegates to `EditorTemplateSpec.valueV1`.
- `ValueForm` becomes the reusable `ValueFormModule` (fields only); template owns save/cancel/delete.
- Open question (confirm before implementation): reuse the existing “value → project → task” hierarchy module with an expanded view variant for this detail surface.

## Entities with partially implemented UI (follow-up required)
Entities listed here have UI already, but requirements are not fully confirmed.

All decisions for entities in this section are **deferred** until requirements are confirmed.

### Decision checklist (per entity)
- [ ] Confirm surface policy: `editorOnly` vs `detailAndEdit`
- [ ] Confirm navigation: screen-scoped launch vs NAV-01 entity routes (`/<type>/new`, `/<type>/:id/edit`)
- [ ] Confirm entry points: where create/edit is launched from (and whether there are multiple launch surfaces)
- [ ] Confirm form(s) required: create, edit, and any sub-flows (e.g., config editors)
- [ ] Confirm FormBuilder migration scope: whether to migrate now; define `*Draft`, `*Command`, and field keys
- [ ] Confirm field set + constraints: required/optional fields, defaults, and when fields are editable
- [ ] Confirm validation + error mapping: domain rules and field-addressable UI mapping
- [ ] Confirm destructive actions: delete vs archive, and any safety/confirmation UX
- [ ] Confirm persistence + side effects: repositories used, ordering rules, and any downstream impacts
- [ ] Confirm test expectations: unit/widget tests needed for the editor flow

| Entity | Current UI surface (observed) | Form tech (current) | Target (proposed) | Key implementation files | Status |
| --- | --- | --- | --- | --- | --- |
| Tracker | `TrackerManagementScreen` (system screen `trackers`) with create/edit flow | Classic `Form` + controllers (not FormBuilder) | Standardize via FormBuilder-first editor contract (draft/command + `TrackerFormModule`) | [tracker_management_screen.dart](../../../lib/presentation/features/journal/view/tracker_management_screen.dart) | Deferred (needs checklist completion) |
| JournalEntry | `JournalScreen` timeline + `JournalNewEntryForm` (create) + `JournalEntryCard` (inline edit) | FormBuilder | Align to editor contract (draft/command + field keys) and standardize entry points (create/edit) | [journal_screen.dart](../../../lib/presentation/features/journal/view/journal_screen.dart), [journal_new_entry_form.dart](../../../lib/presentation/features/journal/view/journal/journal_new_entry_form.dart), [journal_entry_card.dart](../../../lib/presentation/features/journal/widgets/journal_entry_card.dart) | Deferred (needs checklist completion) |
| TrackerResponse | Embedded within journal entry create/edit (`tracker_<trackerId>` fields) | FormBuilder custom fields (`FormBuilderTracker*Field`) | Treat as a sub-entity of `JournalEntry` unless/until a standalone editor is needed | [journal_entry_card.dart](../../../lib/presentation/features/journal/widgets/journal_entry_card.dart), [journal_new_entry_form.dart](../../../lib/presentation/features/journal/view/journal/journal_new_entry_form.dart), [form_builder_tracker_response_fields.dart](../../../lib/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart) | Deferred (needs checklist completion) |
| DailyTrackerResponse | Embedded as “Daily Trackers” fields (`daily_tracker_<trackerId>`) | FormBuilder custom fields (`FormBuilderTracker*Field`) | Clarify whether these are edited only in journal, or also in a dedicated daily surface | [daily_tracker_section.dart](../../../lib/presentation/features/journal/widgets/daily_tracker_section.dart), [journal_new_entry_form.dart](../../../lib/presentation/features/journal/view/journal/journal_new_entry_form.dart), [form_builder_tracker_response_fields.dart](../../../lib/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart) | Deferred (needs checklist completion) |
| AttentionRule | `AttentionRulesSettingsPage` (toggle-only settings UI) | Not FormBuilder (SwitchListTile toggles) | Confirm whether v1 remains toggle-only, or needs a create/edit rule editor | [attention_rules_settings_page.dart](../../../lib/presentation/features/attention/view/attention_rules_settings_page.dart) | Deferred (needs checklist completion) |

### Tracker — checklist
- [ ] Surface policy: `editorOnly` vs `detailAndEdit`
- [ ] Navigation: screen-scoped vs NAV-01 entity routes
- [ ] Entry points: Trackers screen only vs additional surfaces
- [ ] Forms: create/edit only, or additional config sub-flows
- [ ] Field set: name/description/response type/entry scope/config
- [x] Edit rules: rename-only after first use; response type/scope/config are immutable after first use
- [x] Archive rules: archived trackers are hidden from journal UI; visible in tracker management with unarchive
- [ ] FormBuilder scope: define `TrackerDraft`, `CreateTrackerCommand`, `UpdateTrackerCommand`, field keys
- [ ] Validation mapping: field-addressable domain validation → UI errors
- [x] Actions: delete cascades to all tracker responses (per-entry + daily); reorder is supported

### JournalEntry — checklist
- [ ] Surface policy: `editorOnly` vs `detailAndEdit` (or “timeline-only”)
- [ ] Navigation: screen-scoped vs NAV-01 entity routes
- [ ] Entry points: where create/edit is launched (timeline, FAB, deep link)
- [ ] Forms: create, edit, and whether inline edit remains supported
- [ ] Field set: mood, journal text, per-entry trackers
- [ ] Edit rules: what is editable post-create (time, date, trackers, mood)
- [ ] FormBuilder scope: define `JournalEntryDraft`, commands, field keys
- [ ] Validation mapping: field-addressable domain validation → UI errors
- [ ] Actions: delete/confirmations and any “discard changes” UX

### TrackerResponse — checklist
- [ ] Ownership: always embedded in `JournalEntry` editor, or standalone editor needed?
- [ ] Field keys: confirm stable naming strategy (avoid ad-hoc `tracker_<id>` strings)
- [ ] Persistence: confirm ID strategy + how updates vs insert are handled
- [ ] Validation: confirm required/optional per tracker and error mapping

### DailyTrackerResponse — checklist
- [ ] Ownership: edited only inside journal flow, or also outside journal?
- [ ] Field keys: confirm stable naming strategy (avoid ad-hoc `daily_tracker_<id>` strings)
- [ ] Semantics: confirm “all day” behavior and whether clearing a response is supported
- [ ] Persistence: confirm upsert rules per (date, trackerId)
- [ ] Validation: confirm required/optional and error mapping

### AttentionRule — checklist
- [ ] Scope: toggle-only v1 vs full create/edit in near term
- [ ] Surface policy: `editorOnly` vs `detailAndEdit` (if user-created rules exist)
- [ ] Navigation: settings-only vs NAV-01 entity routes
- [ ] Forms: if create/edit, confirm which configs are user-editable (trigger, selector, display)
- [ ] Validation mapping: field-addressable domain validation → UI errors

## Navigation conventions (confirmed)

### NAV-01 — Entity create vs edit routing
- Create (editor): `/<entityType>/new` (optional defaults via query params)
- Edit (editor): `/<entityType>/:id/edit`
- Detail (read/composite): `/<entityType>/:id` (only for entities with a detail surface)

Per-entity surface policy:
- `detailAndEdit`: supports all three routes (detail + create + edit)
- `editorOnly`: supports only create + edit; detail route is not implemented

Examples:
- `/task/new?projectId=abc` (create)
- `/task/123/edit` (edit)
- `/project/abc` (detail)

## Notes (non-normative)
- Per-screen decisions (e.g., `/task/:id` vs sheet-only) should reference these IDs.
