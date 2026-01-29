# Task Secondary Values Flag

Status: Implemented (January 29, 2026)

## Summary

Task secondary values are controlled by a build-time feature flag. When the
flag is off (default), task-level additional values are hidden in the UI and
ignored in effective-value calculations. Tasks only surface the project’s
primary value.

## Flag

- Name: `TASKLY_TASK_SECONDARY_VALUES`
- Type: build-time (`--dart-define`)
- Default: `false` (off)

Enable example:

```
--dart-define=TASKLY_TASK_SECONDARY_VALUES=true
```

## Behavior

When `TASKLY_TASK_SECONDARY_VALUES=false`:

- Task create/edit hides the additional value picker (no task-level values).
- Task tiles show only the project primary value chip.
- Task effective values ignore secondary overrides (project primary only).
- Value-based filters/analytics only consider the project primary value.

When `TASKLY_TASK_SECONDARY_VALUES=true`:

- Task create/edit allows up to two additional values.
- Task tiles can show secondary value chips.
- Effective values include project primary + task overrides.

## Implementation Notes

Implemented as a compile-time constant:

- `packages/taskly_domain/lib/feature_flags.dart`
- Used in:
  - `packages/taskly_domain/lib/src/services/values/effective_values.dart`
  - `lib/presentation/features/tasks/widgets/task_form.dart`
  - `lib/presentation/entity_tiles/mappers/task_tile_mapper.dart`
