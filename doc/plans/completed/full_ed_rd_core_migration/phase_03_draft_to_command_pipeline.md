# full_ed_rd_core_migration — Phase 03: Draft → Command pipeline (core)

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

## Goal
Migrate core editors to an explicit Draft → Command architecture and route all
persistence through domain-owned commands.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by
  the end of the phase.

## Design (locked)
- Draft is explicit and the source of truth (B1a).
- Commands are domain-owned.
- Validation is domain-first, but full mapping is implemented in Phase 04.

## Implementation strategy

### 03.1 Migration order
Proceed in this order to reduce complexity:
1) Value
2) Project
3) Task

### 03.2 Define draft models
Create drafts for each entity.

Drafts should:
- Be plain Dart objects (immutable preferred).
- Have `fromEntity(...)` constructors for edit.
- Support updating individual fields.

Location options:
- Domain-adjacent layer is acceptable, but keep it consistent across entities.

### 03.3 Define command models
Create commands:
- `CreateValueCommand`, `UpdateValueCommand`
- `CreateProjectCommand`, `UpdateProjectCommand`
- `CreateTaskCommand`, `UpdateTaskCommand`

Commands should:
- Match persistence requirements (no UI-only fields).
- Use primitive IDs, DateTime, etc. (avoid UI types like Color).

### 03.4 Command handlers
Introduce a single entry-point per entity for persistence:
- A handler/service that consumes commands.

Rules:
- UI/editor does not write directly to repositories.
- Repository usage is owned by handler.

### 03.5 Presentation integration
Update editor flows to:
- Hydrate draft when loading entity.
- Bind draft to FormBuilder (initial values/patching).
- On every field change: update draft (draft is source of truth).
- On submit: create command from draft and submit via bloc/event.

Keep existing blocs if practical:
- Add `submitCreate(command)` / `submitUpdate(command)` events.
- Internally call handlers.

## Acceptance criteria
- Core editors do not dispatch create/update with primitive parameter lists.
- Core editors submit commands.
- Persistence logic is centralized in command handlers.

## Notes / risks
- Avoid a big-bang rewrite of blocs; adapt incrementally.
- Ensure the command models are stable contracts suitable for domain validation
  in the next phase.
