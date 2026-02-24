# PMD Decision Events And Debug Stats Spec

## Status

Proposed implementation spec.

## Goals

- Add append-only PMD behavior telemetry without replacing existing outcome tables.
- Support task-level and routine-level behavior stats (keep/defer/remove/snooze/completed).
- Add a debug-only Stats screen to validate and inspect these metrics quickly.
- Preserve architecture invariants: BLoC-only presentation, domain-owned contracts, data-layer persistence.

## Non-goals

- No user-facing production analytics dashboard in this phase.
- No deletion or mutation of historical decision events (append-only only).
- No replacement of `my_day_picks`, `task_completion_history`, `routine_completions`, `task_snooze_events`, `routine_skips`, `checklist_events`.

## Current State And Gaps

Current tables already capture:

- Plan snapshot: `my_day_picks`.
- Task outcomes: `task_completion_history`, `task_snooze_events`.
- Routine outcomes: `routine_completions`, `routine_skips`.
- Checklist outcome snapshot metrics: `checklist_events`.

Gaps for requested PMD analytics:

- No explicit event log for PMD decisions (keep/defer/remove/snooze/completed) by shelf and entity.
- No first-class "deferred then completed" lag fact.
- Routine weekday insights are possible from `completed_day_local` date math, but not optimized.

## Data Model Changes

### 1) New table: `my_day_decision_events` (append-only)

Purpose: record PMD behavior facts as they happen.

Columns:

- `id` TEXT PK (UUID v4).
- `user_id` TEXT NULL (server-owned on remote; read-only client treatment).
- `day_key_utc` DATE (date-only UTC day key for the PMD context day).
- `entity_type` TEXT (`task` | `routine`).
- `entity_id` TEXT (task/routine id).
- `shelf` TEXT (B-Min5 enum, below).
- `action` TEXT (`kept` | `deferred` | `snoozed` | `removed` | `completed`).
- `action_at_utc` TIMESTAMP UTC.
- `defer_kind` TEXT NULL.
- `from_day_key` DATE NULL.
- `to_day_key` DATE NULL.
- `suggestion_rank` INTEGER NULL.
- `meta_json` TEXT NULL (JSON object; optional diagnostics/context).
- `created_at` TIMESTAMP UTC.
- `_metadata` TEXT NULL (PowerSync metadata).

Constraints:

- Append-only policy at repository boundary (no update/delete API).
- Check constraints:
  - `entity_type` in (`task`, `routine`).
  - `action` in (`kept`, `deferred`, `snoozed`, `removed`, `completed`).
  - `shelf` in B-Min5 values.
  - `suggestion_rank IS NULL OR suggestion_rank >= 0`.

B-Min5 shelf enum (canonical):

- `due`
- `planned`
- `routine_scheduled`
- `routine_flexible`
- `suggestion`

Notes:

- Keep the shelf taxonomy minimal and stable.
- Do not add separate `manual` shelf in this phase; map manual picks to `planned` or `suggestion` per current PMD classification rules.

### 2) Routine completion refinement

Add to `routine_completions`:

- `completed_weekday_local` INTEGER NULL (`1=Mon ... 7=Sun`).
- `timezone_offset_minutes` INTEGER NULL (optional, recommended).

Index additions:

- `idx_routine_completions_routine_weekday` on (`routine_id`, `completed_weekday_local`).
- Keep existing completion-time indexes unchanged.

Rationale:

- Supports direct query for "routine most often completed on Tue/Thu" without repeated date transforms.

## Write Boundary Instrumentation

Instrumentation must happen in domain/data write boundaries, never directly in widgets.

### Event emission mapping

1. Plan confirm (`kept`)
- Boundary: `MyDayRepositoryContract.setDayPicks` implementation.
- Emit `kept` for every selected task/routine in confirmed picks.
- `shelf` derived from pick bucket mapping.

2. Plan confirm diff (`removed`)
- Boundary: same `setDayPicks` transaction.
- Before replace, load previous picks for day.
- Emit `removed` for entities present before and absent after.

3. Reschedule due/planned (`deferred`)
- Boundary: `TaskWriteService`/`TaskRepository` bulk/single reschedule writes.
- Emit one `deferred` event per affected task.
- `defer_kind`:
  - due deadline move: `deadline_reschedule`
  - planned start move: `start_reschedule`
- `from_day_key` and `to_day_key` required.

4. Snooze (`snoozed`)
- Boundary: `TaskRepository.setMyDaySnoozedUntil`.
- Emit `snoozed` with `from_day_key`, `to_day_key`, `defer_kind='snooze'`.

5. Completion from PMD context (`completed`)
- Task boundary: `OccurrenceWriteHelper.completeTaskOccurrence`.
- Routine boundary: `RoutineRepository.recordCompletion`.
- Emit `completed` when write `OperationContext` indicates PMD context:
  - `screen` in (`my_day`, `plan_my_day`, `screen_actions` + PMD source flag if added).
- If PMD source is ambiguous for `screen_actions`, use day-pick membership check for today as fallback.

## Domain Contract Additions

Add domain-owned contracts (new interfaces/models):

- `MyDayDecisionEventRepositoryContract` (append-only writes + analytics reads).
- `MyDayDecisionEvent` domain model.
- `MyDayDecisionAction`, `MyDayDecisionShelf`, `MyDayDeferKind` enums.

Write API:

- `Future<void> append(MyDayDecisionEvent event, {OperationContext? context});`
- `Future<void> appendAll(List<MyDayDecisionEvent> events, {OperationContext? context});`

Read/query API (for debug stats and future product analytics):

- `Future<Map<String, double>> getKeepRateByShelf({required DateRange range});`
- `Future<Map<String, double>> getDeferRateByShelf({required DateRange range});`
- `Future<Map<String, int>> getDeferCountByEntity({required DateRange range, required String entityType});`
- `Future<Map<String, List<int>>> getRoutineTopWeekdays({required DateRange range});`
- `Future<List<DeferredThenCompletedLagMetric>> getDeferredThenCompletedLag({required DateRange range});`

## Query Semantics

### Keep rate by shelf

- Numerator: count(`action='kept'`).
- Denominator: count(`action IN ('kept','removed','deferred','snoozed')`) for same shelf.

### Defer rate by shelf/entity

- Numerator: count(`action IN ('deferred','snoozed')`).
- Denominator: count(`action IN ('kept','deferred','snoozed','removed')`).

### Per-task/routine defer counts

- Group by (`entity_type`, `entity_id`) where action in (`deferred`, `snoozed`).

### Routine top completion weekdays

- Source of truth: `routine_completions.completed_weekday_local` (fallback derive from `completed_day_local` if null during migration window).
- Return top N weekdays by count per routine.

### Deferred then completed lag

- Pair the nearest subsequent `completed` event for same (`entity_type`, `entity_id`) after each defer.
- Lag = `completed.action_at_utc - deferred.action_at_utc`.
- Aggregate:
  - median lag hours
  - p75 lag hours
  - completion-within-7-days rate

## Debug-Only Stats Screen

## UX scope

- Entry point: Settings -> Developer -> `Stats` (debug build only).
- Route example: `/settings/developer/stats`.
- Not exposed in release mode (`kDebugMode` gate).

## Page content (basic)

- Date range chips: `7d`, `28d`, `90d`.
- Cards/sections:
  - Keep rate by shelf.
  - Defer rate by shelf.
  - Top deferred tasks (count).
  - Top deferred routines (count).
  - Routine top weekdays (top 2 weekdays per routine).
  - Deferred -> completed lag summary.

## Presentation architecture

- New BLoC for debug stats page.
- BLoC depends on domain contracts/services only.
- No direct repository calls from widgets.

## Implementation Touchpoints

Data/schema:

- `packages/taskly_data/lib/src/infrastructure/drift/drift_database.dart`
- `packages/taskly_data/lib/src/infrastructure/powersync/schema.dart`
- `supabase/migrations/<new_migration>.sql`
- `packages/taskly_data/lib/src/id/id_generator.dart`
- `packages/taskly_data/lib/src/services/maintenance/user_data_wipe_service_impl.dart`

Domain:

- `packages/taskly_domain/lib/src/interfaces/` (new PMD decision contract)
- `packages/taskly_domain/lib/src/my_day/` (new models/enums)
- `packages/taskly_domain/lib/src/services/analytics/analytics_service.dart` (or dedicated PMD analytics service contract)

Write boundaries:

- `packages/taskly_data/lib/src/features/my_day/repositories/my_day_repository_impl.dart`
- `packages/taskly_data/lib/src/repositories/task_repository.dart`
- `packages/taskly_data/lib/src/repositories/routine_repository.dart`
- `packages/taskly_data/lib/src/services/occurrence_write_helper.dart`

Presentation:

- `lib/presentation/features/settings/view/settings_developer_page.dart`
- `lib/presentation/routing/routing.dart`
- `lib/presentation/routing/router.dart`
- `lib/presentation/features/statistics/...` (new debug stats bloc/view files)
- `lib/l10n/arb/app_en.arb` (+ localized siblings)

## Migration And Sync Requirements

- Add Drift table and columns.
- Update PowerSync schema with new table/columns.
- Add Supabase migration for parity:
  - table, constraints, indexes, RLS policies, grants.
  - routine completion new columns + index.
- Validate parity with:
  - `dart run tool/validate_supabase_schema_alignment.dart --require-db --linked-only --strict-ddl`

## Testing Plan

Unit/repository tests:

- Event writes for each action type.
- `setDayPicks` diff logic writes `kept` and `removed`.
- Reschedule/snooze writes generate deferred/snoozed events with correct day keys.
- Completion writes generate `completed` in PMD context.
- Weekday local column populated correctly.

Analytics query tests:

- Keep/defer rate by shelf.
- Per-entity defer counts.
- Routine top weekdays.
- Deferred->completed lag pairing and aggregates.

Presentation tests:

- Developer settings shows `Stats` only in debug mode.
- Route navigates to stats page.
- Stats page renders sections for loaded state and empty state.

Regression validation:

- `dart analyze`
- targeted tests under `packages/taskly_data/test` and `test/presentation/...`

## Acceptance Criteria

- Debug-only Developer `Stats` page is accessible and loads metrics.
- `my_day_decision_events` receives append-only facts for keep/defer/snooze/remove/completed at required boundaries.
- Existing outcome tables remain unchanged in behavior.
- Routine weekday stat query works directly from stored weekday column.
- Supabase/PowerSync/Drift schema parity is green.
- New tests cover write instrumentation and metrics queries.
