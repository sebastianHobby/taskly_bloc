# PowerSync + Supabase Data Sync â€” Architecture Overview

> Audience: developers + architects
>
> Scope: the *current* offline-first persistence + sync pipeline in this repo (Drift â†’ PowerSync client â†’ PowerSync server â†’ Supabase/Postgres/PostgREST), plus how we validate it in integration tests.

## 1) Executive Summary

Taskly uses an **offline-first** data architecture:

- **Local source of truth for UI**: a SQLite database accessed via **Drift**.
- **Sync engine**: PowerSync keeps the local DB synchronized with Supabase Postgres.
- **Writes go through Supabase PostgREST** (not direct Postgres from clients).
- **Reads/downloads come from PowerSync replication** (logical replication stream filtered by server-side sync rules).

Key implications:

- The app can work while offline (Drift reads/writes remain available).
- Sync boundaries are explicit:
  - Client â†’ server writes: `SupabaseConnector.uploadData()` calls PostgREST.
  - Server â†’ client reads: PowerSync server replicates Postgres and serves filtered buckets.
- Auth is real (no bypass): the same Supabase session JWT is used for:
  - Calling PostgREST
  - Authenticating to the PowerSync service

Important ownership rule:

- `user_id` is **owned and controlled by Supabase** (derived from the logged-in JWT on the server).
  The local app should **not set `user_id`** in write payloads and should **not rely on it** for access control.

---

## 2) Where Things Live (Folder Map)

### Client: Drift + PowerSync
- PowerSync connector (auth + upload pipeline):
  - [lib/data/infrastructure/powersync/api_connector.dart](../lib/data/infrastructure/powersync/api_connector.dart)
- Local PowerSync schema (client-side tables/columns):
  - [lib/data/infrastructure/powersync/schema.dart](../lib/data/infrastructure/powersync/schema.dart)
- Upload-time JSON normalization (PowerSync TEXT â†’ PostgREST json/jsonb/arrays):
  - [lib/data/infrastructure/powersync/upload_data_normalizer.dart](../lib/data/infrastructure/powersync/upload_data_normalizer.dart)
- DI wiring: PowerSync DB â†” Drift `AppDatabase`:
  - [lib/core/dependency_injection/dependency_injection.dart](../lib/core/dependency_injection/dependency_injection.dart)

### Server (local dev): PowerSync service
- Docker Compose stack:
  - [infra/powersync_local/docker-compose.yml](../infra/powersync_local/docker-compose.yml)
- PowerSync service config:
  - [infra/powersync_local/config/powersync.yaml](../infra/powersync_local/config/powersync.yaml)
- Sync rules (bucket definitions + per-user filters):
  - [supabase/powersync-sync-rules.yaml](../supabase/powersync-sync-rules.yaml)

### Supabase local
- Migrations (schema is maintained via migrations):
  - [supabase/migrations/](../supabase/migrations/)
- PowerSync publication migration (enables logical replication publication):
  - [supabase/migrations/20260111000000_powersync_publication.sql](../supabase/migrations/20260111000000_powersync_publication.sql)

### Local E2E scripts + docs
- Deterministic local stack docs:
  - [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../doc/LOCAL_SUPABASE_POWERSYNC_E2E.md)
- PowerShell helpers:
  - [tool/e2e/Start-LocalE2EStack.ps1](../tool/e2e/Start-LocalE2EStack.ps1)
  - [tool/e2e/Run-LocalE2ETests.ps1](../tool/e2e/Run-LocalE2ETests.ps1)
  - [tool/e2e/New-LocalE2EDefines.ps1](../tool/e2e/New-LocalE2EDefines.ps1)

### Tests + CI
- Pipeline integration test:
  - [test/integration_test/powersync_supabase_pipeline_test.dart](../test/integration_test/powersync_supabase_pipeline_test.dart)
- GitHub Actions workflow that runs only pipeline-tagged tests:
  - [.github/workflows/local-pipeline.yaml](../.github/workflows/local-pipeline.yaml)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                               Flutter App                            â”‚
â”‚                                                                      â”‚
â”‚  Presentation / Domain uses repositories that read/write Drift        â”‚
â”‚                                                                      â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”      â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚
â”‚  â”‚ Drift (AppDatabase)          â”‚      â”‚ PowerSync client runtime   â”‚ â”‚
â”‚  â”‚ - queries + transactions     â”‚â—„â”€â”€â”€â”€â–ºâ”‚ - downloads buckets        â”‚ â”‚
â”‚  â”‚ - local source of truth      â”‚      â”‚ - queues local CRUD        â”‚ â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜      â”‚ - calls upload connector   â”‚ â”‚
â”‚                  â”‚                     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚
â”‚                  â”‚ local SQLite (PowerSync-backed)                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                   â”‚
                   v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                          PowerSync server (Docker)                    â”‚
â”‚  - validates Supabase JWT via JWKS                                    â”‚
â”‚  - applies sync rules (bucket SQL filtered by token_parameters.user_idâ”‚
â”‚    derived from the JWT; not from client-provided columns)            â”‚
â”‚  - serves deltas to clients                                            â”‚
â”‚  - consumes Postgres logical replication stream                        â”‚
â”‚  - stores state in MongoDB                                             â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚ logical replication (publication: powersync)
                v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                           Supabase Postgres                            â”‚
â”‚  - canonical data store                                                 â”‚
â”‚  - RLS + constraints enforced                                           â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚ HTTPS (PostgREST via Supabase client)
                v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                           Supabase PostgREST                           â”‚
â”‚  - client writes: upsert/update/delete                                  â”‚
â”‚  - uses Supabase Auth JWT for RLS                                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 3.2 Local dev stack topology

When running locally, PowerSync joins the Supabase CLI docker network so it can reach:

- Postgres (replication source)
- Kong (used to access JWKS for JWT validation)

See [infra/powersync_local/docker-compose.yml](../infra/powersync_local/docker-compose.yml).

---

## 4) Core Runtime Flows

### 4.1 Startup + authentication â†’ PowerSync connection

The app opens the PowerSync database first, then wraps it with Drift:

- `setupDependencies()` calls `openDatabase()`
- `openDatabase()` initializes PowerSync, then connects only when a user is authenticated
- Drift uses `SqliteAsyncDriftConnection(syncDb)` as its database connection

Entry points:
- [lib/core/dependency_injection/dependency_injection.dart](../lib/core/dependency_injection/dependency_injection.dart)
- [lib/data/infrastructure/powersync/api_connector.dart](../lib/data/infrastructure/powersync/api_connector.dart)

High-level sequence:

```text
1) App starts
2) loadSupabase() initializes Supabase client
3) openDatabase() initializes PowerSync SQLite file
4) If already logged in:
   - db.connect(connector: SupabaseConnector)
   - onAuthenticated() callback runs (post-auth maintenance)
5) Otherwise, auth listener waits for signedIn event and then connects
6) Drift AppDatabase is created on top of PowerSync DB
```

### 4.2 Upload flow (local â†’ Supabase)

Local writes happen through repositories into Drift. PowerSync captures these changes as queued CRUD operations.

Upload is implemented by `SupabaseConnector.uploadData()`:

- Pull queued operations from PowerSync (`db.getCrudTransactions()`)
- For each `CrudEntry`, call Supabase PostgREST (`rest.from(table)....`)
  - inserts/updates: `.upsert(...)` / `.update(...)`
  - deletes: `.delete()`
- Acknowledge the transaction back to PowerSync (so it wonâ€™t retry) only after success

Important safeguards in the current implementation:

- If there is no Supabase session, upload returns early without consuming data (prevents data loss when logged out).
- JSON fields that are stored as TEXT locally are decoded back into objects/arrays before upload.

Data ownership note:

- The client should treat `user_id` as **server-owned**. `user_id` is determined by Supabase from the logged-in JWT
  when the PostgREST request is executed, and should not be set/overridden by the app.

Key code:
- [lib/data/infrastructure/powersync/api_connector.dart](../lib/data/infrastructure/powersync/api_connector.dart)
- [lib/data/infrastructure/powersync/upload_data_normalizer.dart](../lib/data/infrastructure/powersync/upload_data_normalizer.dart)

### 4.3 Download flow (Supabase â†’ local)

Download is â€œserver-drivenâ€ via PowerSync replication:

- PowerSync server reads Postgres changes via logical replication.
- It evaluates bucket queries from `sync_rules.yaml` with `token_parameters.user_id`.
- The PowerSync client receives filtered changes and applies them to the local SQLite DB.
- Drift then observes the updated local tables and the UI reacts.

Key configuration:
- Sync rules: [supabase/powersync-sync-rules.yaml](../supabase/powersync-sync-rules.yaml)
- Server replication config: [infra/powersync_local/config/powersync.yaml](../infra/powersync_local/config/powersync.yaml)

### 4.4 Auth, RLS, and â€œwhat enforces access control?â€

Access control is enforced at two layers:

- **PostgREST writes**: Supabase Auth JWT is used when calling `.rest.from(table)`; RLS/constraints apply.
- **PowerSync reads**: PowerSync validates the same JWT against Supabase JWKS and uses `token_parameters.user_id` inside sync rules.

Critically:

- The PowerSync server derives `token_parameters.user_id` from the validated JWT.
- The app should not set `user_id` in payloads (and should not use `user_id` for authorization decisions);
  auth comes from the JWT and server-side policy (RLS + sync rules).

The PowerSync local server config sets:

- `client_auth.supabase: true`
- `jwks_uri: PS_JWKS_URL`
- `audience: ["authenticated"]`

See [infra/powersync_local/config/powersync.yaml](../infra/powersync_local/config/powersync.yaml).

---

## 5) PowerSync Server: Replication Requirements

PowerSync replication requires a Postgres publication named `powersync`.

This repo ensures it exists via a migration:
- [supabase/migrations/20260111000000_powersync_publication.sql](../supabase/migrations/20260111000000_powersync_publication.sql)

That migration is designed to be safe to run multiple times.

---

## 6) End-to-End Scenarios (Concrete Examples)

### 6.1 Scenario A â€” Upload: Drift write â†’ PostgREST row exists

This is the core â€œlocal-first writeâ€ loop:

```text
1) Repository writes to Drift (local)
2) PowerSync records the CRUD operation
3) PowerSync triggers upload via SupabaseConnector.uploadData()
4) SupabaseConnector upserts via PostgREST
5) Postgres commits; RLS/constraints enforced
6) PowerSync server replication sees the change
7) Device(s) download the latest row state
```

### 6.2 Scenario B â€” Download: PostgREST update â†’ Drift reflects change

This proves the â€œremote change propagates locallyâ€ loop:

```text
1) A server-side update happens (e.g., PostgREST update)
2) Postgres commits
3) PowerSync server replication ingests the change
4) The authenticated client downloads deltas for its buckets
5) Drift observes updated local row and UI reacts
```

---

## 7) How We Test This

### 7.1 Local deterministic test run (Windows + Docker)

The repo provides scripts to:

- start Supabase
- optionally reset DB (`supabase db reset` applies migrations + seed)
- start PowerSync (compose)
- generate `dart_defines.local.json` from `supabase status`

Entry points:
- [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../doc/LOCAL_SUPABASE_POWERSYNC_E2E.md)
- [tool/e2e/Start-LocalE2EStack.ps1](../tool/e2e/Start-LocalE2EStack.ps1)
- [tool/e2e/Run-LocalE2ETests.ps1](../tool/e2e/Run-LocalE2ETests.ps1)

### 7.2 Pipeline integration test (ground-truth validation)

The pipeline integration test validates *both directions*:

- Upload: Drift write â†’ PowerSync upload â†’ PostgREST read validates row
- Download: PostgREST update â†’ PowerSync download â†’ Drift read validates row

See:
- [test/integration_test/powersync_supabase_pipeline_test.dart](../test/integration_test/powersync_supabase_pipeline_test.dart)

### 7.3 CI workflow

GitHub Actions runs the pipeline-tagged test against a fully local stack on `ubuntu-latest`:

- `supabase start` + `supabase db reset`
- PowerSync compose up + liveness wait
- `flutter test --tags=pipeline ... --dart-define=...`

See:
- [.github/workflows/local-pipeline.yaml](../.github/workflows/local-pipeline.yaml)

---

## 8) Schema Sync Policy (Prod â†’ Local)

Local schema is kept in sync with production by updating `supabase/migrations/*` (reviewable, commit-able).

This repo intentionally avoids automatically pulling prod schema on each test run.

See:
- [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../doc/LOCAL_SUPABASE_POWERSYNC_E2E.md)
