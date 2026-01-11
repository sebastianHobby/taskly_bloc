# Phase 04 — Remove Workflow Data Layer + Drift Tables

## Goal
Remove workflow persistence (repositories + Drift tables) from the app.

## What gets removed (local DB)
- Tables from `lib/data/infrastructure/drift/features/workflow_tables.drift.dart`:
  - `workflow_definitions`
  - `workflows`

## Target files
- Drift workflow tables:
  - `lib/data/infrastructure/drift/features/workflow_tables.drift.dart`
- Workflow repository:
  - `lib/data/features/workflow/repositories/workflow_repository_impl.dart`
- Drift database wiring:
  - `lib/data/infrastructure/drift/drift_database.dart` (remove workflow imports + tables)
- DI wiring:
  - `lib/core/di/dependency_injection.dart` (remove workflow repository registration)

## Step-by-step
1. Remove `WorkflowRepositoryImpl` and its DI registration.
2. Remove workflow tables (`WorkflowDefinitions`, `Workflows`) from the `@DriftDatabase(tables: [...])` list.
3. Remove the workflow table imports and any converter-only imports in `drift_database.dart` that become unused.
4. Delete `workflow_tables.drift.dart`.

## Verification
- Run `flutter analyze`.
- Fix compilation errors only.

## Runtime/data note (important)
`AppDatabase` uses a non-destructive migration strategy (`onUpgrade` is empty) because PowerSync owns the underlying SQLite schema. Removing tables from Drift stops the app from using them, but it will NOT automatically drop existing tables in user databases.

If you want to actually drop local tables, add an explicit maintenance step (separate phase or follow-up) that executes SQL like:
- `DROP TABLE IF EXISTS workflow_definitions;`
- `DROP TABLE IF EXISTS workflows;`

Only do this if you are sure there is no user data you need to preserve.
