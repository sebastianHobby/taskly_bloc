# Phase 04 — Domain: Refactor Unified Screens into `domain/screens` (catalog-first)

## Goal

Refactor the unified screens system into a single domain module with explicit boundaries:

- `catalog/` — system screen definitions (“Screen X”)
- `templates/` — template catalog (params + codec + registry + interpreters)
- `runtime/` — definition → data orchestration pipeline
- `language/` — screen configuration language / AST models

This phase will touch codegen-heavy Freezed/JSON models, so it must include a build_runner run.

## Moves (mechanical)

### Language (screen AST/config)

- Move:
  - `lib/domain/models/screens/**`
    → `lib/domain/screens/language/models/**`

### Template params

- Move:
  - `lib/domain/models/screens/templates/**`
    → `lib/domain/screens/templates/params/**`

### Template interpreters + registries/codecs

- Move:
  - `lib/domain/services/screens/templates/**`
    → `lib/domain/screens/templates/interpreters/**`

(Place registry/codec/interpreter base types alongside interpreters if that’s already how they are authored; the key is they live under `templates/`.)

### Runtime

- Move:
  - `lib/domain/services/screens/**`
    → `lib/domain/screens/runtime/**`

### Catalog (preferred)

- Move system screen definitions out of “models” into catalog:
  - `lib/domain/models/screens/system_screen_definitions.dart`
    → `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`

If you later decide to split it into multiple files (e.g. `my_day.dart`, `inbox.dart`), do it in a follow-up refactor.

## Import updates

Update imports across `lib/**` (leave tests for final phase).

Patterns:

- `package:taskly_bloc/domain/models/screens/...`
  → `package:taskly_bloc/domain/screens/language/models/...`

- `package:taskly_bloc/domain/models/screens/templates/...`
  → `package:taskly_bloc/domain/screens/templates/params/...`

- `package:taskly_bloc/domain/services/screens/...`
  → `package:taskly_bloc/domain/screens/runtime/...`

- `package:taskly_bloc/domain/services/screens/templates/...`
  → `package:taskly_bloc/domain/screens/templates/interpreters/...`

## Codegen (required)

After moving Freezed/JSON models:

- Run `dart run build_runner build --delete-conflicting-outputs`

## Analyze and fix (required at end of phase)

- Run `flutter analyze`.
- Fix all errors/warnings.

## Do NOT do in this phase

- Do not run tests.
- Do not reorganize non-screens domain areas.
