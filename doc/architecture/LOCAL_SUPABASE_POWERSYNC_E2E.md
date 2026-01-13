# Local Supabase + PowerSync (Deterministic E2E)

This repo can run a fully local stack for E2E-style tests:
- Supabase local dev (via Supabase CLI + Docker)
- PowerSync self-hosted service (Docker) connected to that local Supabase

The Flutter app already supports switching environments via `--dart-define-from-file`.

## Workflow 1: Deterministic local E2E run

### Prereqs
- Docker Desktop running
- Supabase CLI installed (`supabase` on PATH)
- Flutter SDK available (`flutter` on PATH)

### One-time setup
1. Initialize Supabase project (already done in this repo): see `supabase/config.toml`.
2. Create PowerSync local env file:
   - Copy `infra/powersync_local/powersync.env.example` → `infra/powersync_local/.env`

### Start stack (optionally reset DB)
- Start without reset:
  - PowerShell 7: `pwsh -File tool/e2e/Start-LocalE2EStack.ps1`
  - Windows PowerShell: `powershell -File tool/e2e/Start-LocalE2EStack.ps1`
- Start + clean reset (recommended for deterministic runs):
  - PowerShell 7: `pwsh -File tool/e2e/Start-LocalE2EStack.ps1 -ResetDb`
  - Windows PowerShell: `powershell -File tool/e2e/Start-LocalE2EStack.ps1 -ResetDb`

What reset does:
- `supabase db reset` recreates local Postgres and applies `supabase/migrations/*` + `supabase/seed.sql`.

### Run tests
- PowerShell 7: `pwsh -File tool/e2e/Run-LocalE2ETests.ps1 -ResetDb`
- Windows PowerShell: `powershell -File tool/e2e/Run-LocalE2ETests.ps1 -ResetDb`

Notes:
- The scripts generate `dart_defines.local.json` from `supabase status`.
- Prefer `dart_defines.local.json` for local E2E runs. The checked-in `dart_defines.json` may point to non-local (e.g. hosted) environments.
- PowerSync sync rules are mounted from `supabase/powersync-sync-rules.yaml`.

What the test script runs:
- `flutter test test/integration_test --dart-define-from-file=dart_defines.local.json`

## Workflow 2: Schema-only sync from prod (explicit + reviewable)

The goal is to keep local schema aligned with production *via migrations*, not by pulling from prod on every test run.

### Pull prod schema into migrations
- PowerShell 7: `pwsh -File tool/schema/Pull-ProdSchema.ps1 -ProjectRef <your-project-ref>`
- Windows PowerShell: `powershell -File tool/schema/Pull-ProdSchema.ps1 -ProjectRef <your-project-ref>`

Guidelines:
- Treat generated migrations like code: review, run locally, and commit deliberately.
- Avoid using this as an automated pre-test step against prod.

## PowerSync notes

- Local PowerSync compose: `infra/powersync_local/docker-compose.yml`
- PowerSync service config: `infra/powersync_local/config/powersync.yaml`
- We use Supabase JWKS via Kong on the Supabase docker network (`http://kong:8000/.../jwks.json`).

## Troubleshooting

- If PowerSync cannot reach Postgres:
  - Ensure Supabase is running (`supabase start`).
  - Ensure the compose network name matches `supabase_network_<project_id>`.

- If `supabase status -o json` returns empty values:
  - Start Supabase first (`supabase start`).
