# Local E2E Stack Runbook

## Purpose

Run local Supabase + PowerSync stack and validate app sync behavior end to end.

## Prerequisites

- Docker available
- Supabase CLI available
- Flutter/Dart toolchain installed

## Startup sequence

1. Start your target Supabase environment (local or remote).
2. Start local PowerSync (`infra/powersync_local/docker-compose.yml`).
3. Confirm sync rules and schema are loaded.
4. Launch app and validate local-first reads and write propagation.

## Smoke checks

- Create/update/delete task and routine locally.
- Confirm changes appear in local watchers.
- Confirm sync convergence after reconnect.
- Confirm structured sync telemetry appears in app logs:
  - `sync.connect.start/success`
  - `sync.status.transition`
  - `sync.status.snapshot` (about every 60s while active)
  - `sync.credentials.fetch`
  - `sync.token.refresh.*` when refresh is triggered
  - `sync.upload.queue.high` under heavy local backlog
  - `sync.auth.expired` when credentials are invalidated
- For forced sync anomalies, confirm `public.sync_issues` receives/updates rows
  (dedupe by `fingerprint`, `occurrence_count` increments on repeats).
- Confirm backend diagnostics can be correlated by `sync_session_id`
  from PowerSync `app_metadata`.

## Common failures

- Schema mismatch between PowerSync and local Drift tables.
- Missing ID generator registration for newly added PowerSync table.
- Invalid local write pattern against view-backed table.
