# Local E2E Stack Runbook

## Purpose

Run local Supabase + PowerSync stack and validate app sync behavior end to end.

## Prerequisites

- Docker available
- Supabase CLI available
- Flutter/Dart toolchain installed

## Startup sequence

1. Start Supabase local stack (repo `supabase/` config).
2. Start local PowerSync (`infra/powersync_local/docker-compose.yml`).
3. Confirm sync rules and schema are loaded.
4. Launch app and validate local-first reads and write propagation.

## Smoke checks

- Create/update/delete task and routine locally.
- Confirm changes appear in local watchers.
- Confirm sync convergence after reconnect.

## Common failures

- Schema mismatch between PowerSync and local Drift tables.
- Missing ID generator registration for newly added PowerSync table.
- Invalid local write pattern against view-backed table.
