# Phase 03 — Data: Group persistence by bounded context

## Goal

Group persistence and maintenance code by bounded context:

- `lib/data/screens/**`
- `lib/data/attention/**`
- `lib/data/allocation/**`

This makes it obvious where repositories live and keeps infrastructure separate (already done in Phase 02).

## Moves (mechanical)

### Screens persistence

- Move:
  - `lib/data/features/screens/**` → `lib/data/screens/**`

- Move maintenance services referenced by the Unified Screens architecture doc:
  - `lib/data/services/screen_seeder.dart`
    → `lib/data/screens/maintenance/screen_seeder.dart`
  - `lib/data/services/system_data_cleanup_service.dart`
    → `lib/data/screens/maintenance/system_data_cleanup_service.dart`

### Attention persistence

- Move:
  - `lib/data/repositories/attention_repository_v2.dart`
    → `lib/data/attention/repositories/attention_repository_v2.dart`
  - `lib/data/services/attention_seeder.dart`
    → `lib/data/attention/maintenance/attention_seeder.dart`

(Drift generated tables stay under infrastructure drift unless you intentionally keep a `drift/features/*` substructure.)

### Allocation persistence

- Move:
  - `lib/data/repositories/allocation_snapshot_repository.dart`
    → `lib/data/allocation/repositories/allocation_snapshot_repository.dart`

## Import updates

Update imports across `lib/**`.

Patterns:

- `package:taskly_bloc/data/features/screens/...`
  → `package:taskly_bloc/data/screens/...`

- `package:taskly_bloc/data/services/screen_seeder.dart`
  → `package:taskly_bloc/data/screens/maintenance/screen_seeder.dart`

- `package:taskly_bloc/data/repositories/attention_repository_v2.dart`
  → `package:taskly_bloc/data/attention/repositories/attention_repository_v2.dart`

- `package:taskly_bloc/data/services/attention_seeder.dart`
  → `package:taskly_bloc/data/attention/maintenance/attention_seeder.dart`

- `package:taskly_bloc/data/repositories/allocation_snapshot_repository.dart`
  → `package:taskly_bloc/data/allocation/repositories/allocation_snapshot_repository.dart`

Ensure DI wiring is updated to new repository paths.

## Analyze and fix (required at end of phase)

- Run `flutter analyze`.
- Fix all errors/warnings.

## Do NOT do in this phase

- Do not run tests.
- Do not refactor the domain allocation engine yet.
