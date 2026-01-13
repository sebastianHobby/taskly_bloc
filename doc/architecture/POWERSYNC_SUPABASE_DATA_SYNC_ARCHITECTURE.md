# PowerSync + Supabase Data Sync - Architecture Overview

> Audience: developers + architects
>
> Scope: the *current* offline-first persistence + sync pipeline in this repo (Drift -> PowerSync client -> PowerSync server -> Supabase/Postgres/PostgREST), plus how we validate it in integration tests.

## 1) Executive Summary

Taskly uses an **offline-first** data architecture:

- **Local source of truth for UI**: a SQLite database accessed via **Drift**.
- **Sync engine**: PowerSync keeps the local DB synchronized with Supabase Postgres.
- **Writes go through Supabase PostgREST** (not direct Postgres from clients).
- **Reads/downloads come from PowerSync replication** (logical replication stream filtered by server-side sync rules).

Key implications:

- The app can work while offline (Drift reads/writes remain available).
- Sync boundaries are explicit:
  - Client -> server writes: `SupabaseConnector.uploadData()` calls PostgREST.
  - Server -> client reads: PowerSync server replicates Postgres and serves filtered buckets.
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
  - [lib/data/infrastructure/powersync/api_connector.dart](../../lib/data/infrastructure/powersync/api_connector.dart)
- Local PowerSync schema (client-side tables/columns):
  - [lib/data/infrastructure/powersync/schema.dart](../../lib/data/infrastructure/powersync/schema.dart)
- Upload-time JSON normalization (PowerSync TEXT -> PostgREST json/jsonb/arrays):
  - [lib/data/infrastructure/powersync/upload_data_normalizer.dart](../../lib/data/infrastructure/powersync/upload_data_normalizer.dart)
- DI wiring: PowerSync DB <-> Drift `AppDatabase`:
  - [lib/core/di/dependency_injection.dart](../../lib/core/di/dependency_injection.dart)

### Server (local dev): PowerSync service
- Docker Compose stack:
  - [infra/powersync_local/docker-compose.yml](../../infra/powersync_local/docker-compose.yml)
- PowerSync service config:
  - [infra/powersync_local/config/powersync.yaml](../../infra/powersync_local/config/powersync.yaml)
- Sync rules (bucket definitions + per-user filters):
  - [supabase/powersync-sync-rules.yaml](../../supabase/powersync-sync-rules.yaml)

### Supabase local
- Migrations (schema is maintained via migrations):
  - [supabase/migrations/](../../supabase/migrations/)

Note: this repo currently does not ship a dedicated migration for PowerSync replication/publication setup.

### Local E2E scripts + docs
- Deterministic local stack docs:
  - [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../LOCAL_SUPABASE_POWERSYNC_E2E.md)
- PowerShell helpers:
  - [tool/e2e/Start-LocalE2EStack.ps1](../../tool/e2e/Start-LocalE2EStack.ps1)
  - [tool/e2e/Run-LocalE2ETests.ps1](../../tool/e2e/Run-LocalE2ETests.ps1)
  - [tool/e2e/New-LocalE2EDefines.ps1](../../tool/e2e/New-LocalE2EDefines.ps1)

### Tests + CI
- Pipeline integration test:
  - [test/integration_test/powersync_supabase_pipeline_test.dart](../../test/integration_test/powersync_supabase_pipeline_test.dart)
- GitHub Actions workflow that runs only pipeline-tagged tests:
  - [.github/workflows/local-pipeline.yaml](../../.github/workflows/local-pipeline.yaml)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
+----------------------------+
|         Flutter App         |
| presentation/domain + repos |
+--------------+-------------+
     |
     v
+----------------------------+      +-----------------------------+
| Drift (AppDatabase)        | <--> | PowerSync client runtime    |
| - local source of truth    |      | - downloads buckets         |
| - queries + transactions   |      | - queues local CRUD         |
+--------------+-------------+      | - calls upload connector    |
     |                    +--------------+--------------+
     |                                   |
     | (same local SQLite file)          |
     v                                   v
   local SQLite (PowerSync-backed)
     |
     v
+----------------------------+
| PowerSync server (Docker)  |
| - validates Supabase JWT   |
| - applies sync rules       |
| - serves deltas to clients |
| - consumes logical repl    |
| - stores state in MongoDB  |
+--------------+-------------+
     |
     v logical replication (publication: powersync)
+----------------------------+
| Supabase Postgres          |
| - canonical data store     |
| - RLS + constraints        |
+--------------+-------------+
     |
     v HTTPS (PostgREST via Supabase client)
+----------------------------+
| Supabase PostgREST         |
| - client writes            |
| - uses Auth JWT for RLS    |
+----------------------------+
```

### 3.2 Local dev stack topology

When running locally, PowerSync joins the Supabase CLI docker network so it can reach:

- Postgres (replication source)
- Kong (used to access JWKS for JWT validation)

See [infra/powersync_local/docker-compose.yml](../../infra/powersync_local/docker-compose.yml).

---

## 4) Core Runtime Flows

### 4.1 Startup + authentication -> PowerSync connection

The app opens the PowerSync database first, then wraps it with Drift:

- `setupDependencies()` calls `openDatabase()`
- `openDatabase()` initializes PowerSync, then connects only when a user is authenticated
- Drift uses `SqliteAsyncDriftConnection(syncDb)` as its database connection

Entry points:
- [lib/core/di/dependency_injection.dart](../../lib/core/di/dependency_injection.dart)
- [lib/data/infrastructure/powersync/api_connector.dart](../../lib/data/infrastructure/powersync/api_connector.dart)

High-level sequence:

```text
1) App starts
2) loadSupabase() initializes Supabase client
3) openDatabase() initializes PowerSync SQLite file
  - best-effort normalization of legacy attention_rules.rule_type values
    (prevents Supabase enum rejections during upload)
4) If already logged in:
   - db.connect(connector: SupabaseConnector)
   - onAuthenticated() callback runs (post-auth maintenance)
5) Otherwise, auth listener waits for signedIn event and then connects
6) Drift AppDatabase is created on top of PowerSync DB
```

### 4.2 Upload flow (local -> Supabase)

Local writes happen through repositories into Drift. PowerSync captures these changes as queued CRUD operations.

Upload is implemented by `SupabaseConnector.uploadData()`:

- Pull the next queued transaction from PowerSync (`database.getNextCrudTransaction()`)
- For each `CrudEntry`, call Supabase PostgREST (`rest.from(table)....`)
  - inserts/updates: `.upsert(...)` / `.update(...)`
  - deletes: `.delete()`
- Acknowledge the transaction back to PowerSync (so it won't retry) only after success

Important safeguards in the current implementation:

- If there is no Supabase session, upload returns early without consuming data (prevents data loss when logged out).
- JSON fields that are stored as TEXT locally are decoded back into objects/arrays before upload.
- Some schema-mismatch operations are discarded (e.g. PostgREST schema cache misses after migrations) to avoid blocking the upload queue.
- Some non-retryable constraint/RLS errors discard the remaining transaction to avoid permanently wedging the queue.

Data ownership note:

- The client should treat `user_id` as **server-owned**. `user_id` is determined by Supabase from the logged-in JWT
  when the PostgREST request is executed, and should not be set/overridden by the app.

Key code:
- [lib/data/infrastructure/powersync/api_connector.dart](../../lib/data/infrastructure/powersync/api_connector.dart)
- [lib/data/infrastructure/powersync/upload_data_normalizer.dart](../../lib/data/infrastructure/powersync/upload_data_normalizer.dart)

### 4.3 Download flow (Supabase -> local)

Download is "server-driven" via PowerSync replication:

- PowerSync server reads Postgres changes via logical replication.
- It evaluates bucket queries from `sync_rules.yaml` with `token_parameters.user_id`.
- The PowerSync client receives filtered changes and applies them to the local SQLite DB.
- Drift then observes the updated local tables and the UI reacts.

Key configuration:
- Sync rules: [supabase/powersync-sync-rules.yaml](../../supabase/powersync-sync-rules.yaml)
- Server replication config: [infra/powersync_local/config/powersync.yaml](../../infra/powersync_local/config/powersync.yaml)

### 4.4 Auth, RLS, and "what enforces access control?"

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

See [infra/powersync_local/config/powersync.yaml](../../infra/powersync_local/config/powersync.yaml).

---

## 5) PowerSync Server: Replication Requirements

PowerSync replication requires logical replication to be enabled/configured on the target Postgres.

In this repo, local stack orchestration lives under:
- [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../LOCAL_SUPABASE_POWERSYNC_E2E.md)
- [infra/powersync_local/](../../infra/powersync_local/)

If replication setup becomes a recurring source of drift, add a Supabase migration under `supabase/migrations/` to make the required publication/permissions explicit and reviewable.

---

## 6) End-to-End Scenarios (Concrete Examples)

### 6.1 Scenario A - Upload: Drift write -> PostgREST row exists

This is the core "local-first write" loop:

```text
1) Repository writes to Drift (local)
2) PowerSync records the CRUD operation
3) PowerSync triggers upload via SupabaseConnector.uploadData()
4) SupabaseConnector upserts via PostgREST
5) Postgres commits; RLS/constraints enforced
6) PowerSync server replication sees the change
7) Device(s) download the latest row state
```

### 6.2 Scenario B - Download: PostgREST update -> Drift reflects change

This proves the "remote change propagates locally" loop:

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
- [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../LOCAL_SUPABASE_POWERSYNC_E2E.md)
- [tool/e2e/Start-LocalE2EStack.ps1](../../tool/e2e/Start-LocalE2EStack.ps1)
- [tool/e2e/Run-LocalE2ETests.ps1](../../tool/e2e/Run-LocalE2ETests.ps1)

### 7.2 Pipeline integration test (ground-truth validation)

The pipeline integration test validates *both directions*:

- Upload: Drift write -> PowerSync upload -> PostgREST read validates row
- Download: PostgREST update -> PowerSync download -> Drift read validates row

See:
- [test/integration_test/powersync_supabase_pipeline_test.dart](../../test/integration_test/powersync_supabase_pipeline_test.dart)

### 7.3 CI workflow

GitHub Actions runs the pipeline-tagged test against a fully local stack on `ubuntu-latest`:

- `supabase start` + `supabase db reset`
- PowerSync compose up + liveness wait
- `flutter test --tags=pipeline ... --dart-define=...`

See:
- [.github/workflows/local-pipeline.yaml](../../.github/workflows/local-pipeline.yaml)

---

## 8) Schema Sync Policy (Prod -> Local)

Local schema is kept in sync with production by updating `supabase/migrations/*` (reviewable, commit-able).

This repo intentionally avoids automatically pulling prod schema on each test run.

See:
- [doc/LOCAL_SUPABASE_POWERSYNC_E2E.md](../LOCAL_SUPABASE_POWERSYNC_E2E.md)
