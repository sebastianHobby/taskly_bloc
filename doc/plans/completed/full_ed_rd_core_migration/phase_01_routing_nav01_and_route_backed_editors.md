# full_ed_rd_core_migration — Phase 01: Routing (NAV-01 + redirects + route-backed editors)

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Implement NAV-01 create/edit routes for core entities and normalize the task
entity route to the canonical edit URL.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by
  the end of the phase.

## Design (locked)
- Canonical task edit route: `/task/:id/edit`.
- `/task/:id` redirects to `/task/:id/edit`.
- Create/edit routes exist:
  - `/task/new`, `/task/:id/edit`
  - `/project/new`, `/project/:id/edit`
  - `/value/new`, `/value/:id/edit`
- Project/value RD routes remain unchanged:
  - `/project/:id` and `/value/:id`.
- All `/.../edit` and `/.../new` routes are route-backed editor pages:
  - open modal editor on first frame
  - on dismiss: pop if possible else go `/my-day`

## Implementation steps

### 01.1 Router: add NAV-01 routes
Files:
- `lib/presentation/routing/router.dart`

Add routes for:
- Task:
  - `GoRoute(path: '/task/new', builder: ...)`
  - `GoRoute(path: '/task/:id/edit', builder: ...)`
  - `GoRoute(path: '/task/:id', redirect: ...)` → `/task/:id/edit`
- Project:
  - `GoRoute(path: '/project/new', builder: ...)`
  - `GoRoute(path: '/project/:id/edit', builder: ...)`
- Value:
  - `GoRoute(path: '/value/new', builder: ...)`
  - `GoRoute(path: '/value/:id/edit', builder: ...)`

Notes:
- Avoid introducing more route patterns; keep the ShellRoute structure.
- Redirects should preserve `id` and query params if any are later introduced.

### 01.2 Route-backed editor pages
Approach:
- Prefer small, explicit pages (mirroring `TaskEditorRoutePage`) over clever
  abstractions.

Files:
- Task: update/extend `lib/presentation/features/tasks/view/task_editor_route_page.dart`
  - Support both create + edit modes, or create a `TaskCreateRoutePage`.
- Add:
  - `lib/presentation/features/projects/view/project_editor_route_page.dart`
  - `lib/presentation/features/values/view/value_editor_route_page.dart`

Behavior:
- In `initState`, schedule `open...Editor` via `addPostFrameCallback`.
- Ensure the page only opens once (guard boolean).
- After modal returns:
  - if `GoRouter.of(context).canPop()` → `pop()`
  - else → `go(Routing.screenPath('my_day'))`

### 01.3 Routing helpers
Files:
- `lib/presentation/routing/routing.dart`

Add typed helpers:
- `toTaskNew(BuildContext)` / `toTaskEdit(BuildContext, String id)`
- `toProjectNew(...)` / `toProjectEdit(...)`
- `toValueNew(...)` / `toValueEdit(...)`

These helpers are used by UI code; consumers should not hardcode paths.

### 01.4 Call site audit (core only)
- Search for `'/task/'`, `'/project/'`, `'/value/'` and migrate obvious direct
  uses to `Routing.*` helpers.
- Keep changes scoped to core-related files only.

## Acceptance criteria
- `/task/123` navigated directly lands on `/task/123/edit` (redirect).
- `/task/123/edit` opens the task editor modal and returns when dismissed.
- `/task/new` opens create-task editor and returns when dismissed.
- `/project/123/edit` and `/value/123/edit` open editors and return when dismissed.
- If opened as a deep link (no back stack), dismiss navigates to `/my-day`.

## Notes / risks
- Redirect loops: ensure the `/task/:id` redirect only targets `/task/:id/edit`.
- ShellRoute interaction: verify that opening an editor from a route-backed page
  behaves correctly under nested navigation.
