# Phase 00 — Decisions, Rules, and Success Criteria

## Decision summary

- Approach: **Option 2 (limited features)**
- Presentation decision: **Approach B**
  - Unified screens moves to `lib/presentation/screens/**`.
  - Product UI remains under `lib/presentation/features/**`.
- Catalog preference: system screens live under a **catalog** folder.
- Constraint: **No shims**
  - No temporary forwarding libraries.
  - Every phase must leave `main` buildable with `flutter analyze` clean.

## Global rules (apply to every phase)

- After completing a phase:
  - Run `flutter analyze`.
  - Fix **all** errors/warnings that result from that phase.
  - Do **not** proceed until analysis is clean.

- Tests policy:
  - **Do not run tests** (unit/widget/integration) and do **not** fix test failures until the final phase.
  - If analysis requires touching test files due to compilation/import errors (rare), postpone unless analysis is blocked.

- Refactor type:
  - This is a **mechanical move + import rewrite** refactor.
  - Do not change runtime behavior.
  - Do not rename APIs unless required by Dart library/path constraints.

## Target end-state (high level)

- `lib/domain/screens/**` becomes a first-class domain module with:
  - `catalog/` (system screen definitions)
  - `templates/` (params + codec + registry + interpreters)
  - `runtime/` (screen pipeline orchestration)
  - `language/` (screen configuration language / AST models)

- `lib/presentation/screens/**` becomes the unified screens presentation module.

- `lib/data/infrastructure/{drift,powersync,supabase}/**` holds cross-cutting persistence/sync plumbing.

- Persistence grouped by bounded context:
  - `lib/data/screens/**`
  - `lib/data/attention/**`
  - `lib/data/allocation/**`

- Allocation domain becomes consistent with Attention-style modularity:
  - `lib/domain/allocation/{model,engine,contracts}/**`

## Definition of done

- `flutter analyze` clean after every phase.
- `dart run build_runner build --delete-conflicting-outputs` clean when codegen is touched.
- Final phase: tests run and addressed.
- No remaining imports referencing old paths that were migrated.
