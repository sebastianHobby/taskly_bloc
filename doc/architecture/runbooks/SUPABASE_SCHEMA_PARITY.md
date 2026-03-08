# Supabase Schema Parity Runbook

## Goal

Keep linked Supabase schema, local migrations, PowerSync schema, and Drift schema aligned.

## Policy

- Schema changes are migration-only.
- Do not apply direct DDL in Supabase SQL editor/dashboard for production.
- If an emergency remote change is made, add a migration in the same day to reconcile repo state.

## Canonical Commands

From repo root:

```powershell
dart run tool/validate_supabase_schema_alignment.dart --require-db --linked-only --strict-ddl
```

This command validates:

- PowerSync `schema.dart` <-> Drift tables
- Linked Supabase schema <-> local schema contracts
- Local migration apply/reset integrity
- Local migration history <-> linked migration history
- Linked DDL drift via `supabase db diff --linked --schema public --use-migra`

## Before Push

- Ensure `git_hooks.dart` pre-push remains enabled.
- Pre-push always runs linked schema parity.
- Pre-push runs the strict local replay check only when outgoing commits touch
  schema-relevant paths, currently:
  - `supabase/migrations/**`
  - `packages/taskly_data/lib/src/infrastructure/powersync/**`
  - `packages/taskly_data/lib/src/infrastructure/drift/**`
  - `packages/taskly_data/lib/src/features/**`
  - `tool/validate_supabase_schema_alignment.dart`
  - `doc/architecture/runbooks/SUPABASE_SCHEMA_PARITY.md`
- When those paths are touched, pre-push must run with:
  - `--require-db`
  - `--linked-only`
  - `--strict-ddl`
- When those paths are not touched, pre-push may run the lightweight linked
  parity path without `--require-db` / `--strict-ddl`.
- If pre-push cannot determine the upstream ref or changed paths, it must
  fall back to the strict path.

## Weekly / Release Check

Run:

```powershell
supabase migration list --linked
supabase db diff --linked --schema public --use-migra
dart run tool/validate_supabase_schema_alignment.dart --require-db --linked-only --strict-ddl
```

Expected result:

- migration list has no local/remote divergence (other than intentional pending local migration before push)
- linked diff returns `No schema changes found`
- strict validator passes

## Drift Recovery

If parity fails:

1. Identify mismatch source (`migration list`, linked diff output).
2. Create/patch migration to be idempotent for partially-applied states:
   - `DROP ... IF EXISTS`
   - `CREATE ... IF NOT EXISTS`
   - guard `ADD CONSTRAINT` with `pg_constraint` checks
   - guard policy recreation with `DROP POLICY IF EXISTS`
3. Re-run:
   - `supabase db reset --local --no-seed`
   - `supabase db push --linked`
   - strict validator command
