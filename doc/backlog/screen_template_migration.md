# Screen template migration backlog

Created at: 2026-01-13 (UTC)
Last updated at: 2026-01-13 (UTC)

## Rules
- This file is a **decision log**.
- I will **not** record partial decisions.
- A screen is written here only when you explicitly confirm **ALL decisions for that screen** are final.

Related architecture decisions (editors + entity detail templates):
- `doc/architecture/backlog/editor_detail_template_contracts_formbuilder.md`

## Decision checklist (per screen)
- Migrate to future architecture? (yes/no)
- Target template type:
  - `ScreenTemplateSpec.*` standalone template, or
  - `standardScaffoldV1` + slots/modules, or
  - `EntityDetailTemplateV1(entityType=...)`, or
  - keep bespoke.
- Slot layout (if applicable): `header` modules, `primary` modules.
- Pack policy (if applicable): screen default vs module-only; `standard`/`compact`.
- Navigation semantics: route key/aliases; deep link expectations.
- Editing UX: editor sheet vs dedicated page vs inline.
- Analytics hooks: what events matter (view, create, update, delete).

## Confirmed decisions

### FE-11 — `/task/:id` detail vs editor routes
- Migrate to future architecture: Yes.
- Decision: **Task is editor-only** (no task detail screen).
- Navigation semantics:
  - Create: `/task/new`
  - Edit: `/task/:id/edit`
  - Detail: `/task/:id` is not supported.
- Target template type: `EditorTemplateSpec.taskV1` (create/edit).
- Editing UX: editor-only (modal/page adaptive), no read/composite detail surface.
- Pack policy: N/A (no detail template).

### FE-14 — `/label/:id`
- Migrate to future architecture: No.
- Decision: Remove the route entirely (no redirect).
- Expected behavior if something navigates here: show Not Found.

### FE-12 — `/project/:id`
- Migrate to future architecture: Yes.
- Target template type: `EntityDetailTemplateV1(project)`.
- Slot layout:
  - `header`: `EntityHeaderModule(project)`.
  - `primary`: `TaskListModule(query=forProject)`.
- Pack policy: P1 (screen default pack = `standard`, modules inherit).
- Editing UX: keep app bar edit + delete actions.
- Scope note: remove “next task” block entirely for now.

### FE-13 — `/value/:id`
- Migrate to future architecture: Yes.
- Target template type: `EntityDetailTemplateV1(value)`.
- Slot layout:
  - `header`: `EntityHeaderModule(value)` + `ValueStatsModule(value)`.
  - `primary`: projects → tasks, rendered as a clear hierarchy (parent project → child tasks).
- Pack policy: P1 (screen default pack = `standard`, modules inherit).

### FE-15 — `trackers` (TrackerManagement)
- Migrate to future architecture: Yes.
- Target template type: `ScreenTemplateSpec.trackerManagement` (standalone template; keep bespoke UI for now).
- Slot layout: N/A (bespoke template).
- Pack policy: P1 (screen default pack = `standard`).
- Navigation semantics:
  - System screen key: `trackers`.
  - Segment route: `/trackers`.
- Editing UX:
  - Screen-scoped management (no `/tracker/new` or `/tracker/:id/edit` routes yet).
  - Create: dialog.
  - Edit: rename-only after first use; other tracker properties are immutable after first use.
  - Archive: supported; archived trackers are hidden from journal UI; visible here with unarchive.
  - Delete: supported; cascade-delete all tracker responses (per-entry + daily).
  - Reorder: supported.
- Analytics hooks: view, create, rename, archive, unarchive, delete, reorder.
