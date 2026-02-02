# Local Supabase + PowerSync (Deterministic E2E)

This repo can run a fully local stack for E2E-style tests:
- Supabase local dev (via Supabase CLI + Docker)
- PowerSync self-hosted service (Docker) connected to that local Supabase

The Flutter app uses entrypoint-based build-time configuration:
- Local dev: `lib/main_local.dart`
- Prod: `lib/main_prod.dart`

## Workflow 1: Deterministic local E2E run

### Prereqs
- Docker Desktop running
- Supabase CLI installed (`supabase` on PATH)
- Flutter SDK available (`flutter` on PATH)

### One-time setup
1. Initialize Supabase project (already done in this repo): see `supabase/config.toml`.
2. Create PowerSync local env file:
   - Copy `infra/powersync_local/powersync.env.example` -> `infra/powersync_local/.env`
   - Ensure `PS_SUPABASE_JWT_SECRET` matches `supabase status -o json` (`JWT_SECRET`).

### Start stack (optionally reset DB)
- Start without reset:
  - PowerShell 7: `pwsh -File tool/e2e/Start-LocalE2EStack.ps1`
  - Windows PowerShell: `powershell -File tool/e2e/Start-LocalE2EStack.ps1`
- Start + clean reset (recommended for deterministic runs):
  - PowerShell 7: `pwsh -File tool/e2e/Start-LocalE2EStack.ps1 -ResetDb`
  - Windows PowerShell: `powershell -File tool/e2e/Start-LocalE2EStack.ps1 -ResetDb`

What reset does:
- `supabase db reset` recreates local Postgres and applies the locally generated schema (via `supabase/migrations/`).
  - In this repo, migrations are expected to be generated via `supabase db pull` (CI does this automatically).
  - Developers can run `supabase db pull` before reset when needed.

### Run tests
- PowerShell 7: `pwsh -File tool/e2e/Run-LocalPipelineIntegrationTests.ps1 -ResetDb`
- Windows PowerShell: `powershell -File tool/e2e/Run-LocalPipelineIntegrationTests.ps1 -ResetDb`

Notes:
- The app's local endpoints/keys are selected via `lib/main_local.dart`.
- PowerSync sync rules are mounted from `supabase/powersync-sync-rules.yaml`.
- Pipeline tests are **integration-test-only** and will self-skip unless the
  integration test binding is active; always run them via the entrypoint below
  or the script above (not plain `flutter test -t pipeline`).

What the test script runs:
- `flutter test integration_test/powersync_pipeline_entrypoint_test.dart -d windows`

## Schema notes (prod -> local)

CI (and developers when needed) can pull the latest schema from Supabase Cloud
into the local generated migrations output (`supabase/migrations/`) via `supabase db pull` before starting the local stack.

This keeps the local stack aligned with production without requiring developers
to manually maintain schema drift.

## PowerSync notes

- Local PowerSync compose: `infra/powersync_local/docker-compose.yml`
- PowerSync service config: `infra/powersync_local/config/powersync.yaml`
- Local auth uses the Supabase JWT secret (`PS_SUPABASE_JWT_SECRET`) from `supabase status -o json`.

## Troubleshooting

- If PowerSync cannot reach Postgres:
  - Ensure Supabase is running (`supabase start`).
  - Ensure the compose network name matches `supabase_network_<project_id>`.

- If `supabase status -o json` returns empty values:
  - Start Supabase first (`supabase start`).


