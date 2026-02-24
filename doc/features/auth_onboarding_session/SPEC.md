# Auth, Onboarding, And Session Spec

## Scope

Defines auth states, onboarding progression, startup synchronization gates, and app shell entry behavior.

## Core rules

- Session state transitions are explicit and testable.
- Startup gating must not bypass required sync/ready checks.
- Navigation transitions are deterministic from state.
- Sync connect cycles must emit structured telemetry events for traceability.
- Sign-up paths that require email verification must route to an explicit
  "check email" confirmation state (not a transient snackbar-only message).
- Onboarding values setup requires at least 3 values before progression to
  ratings.

## Sync observability contract

- Each PowerSync connect cycle has a unique `sync_session_id`.
- Connect app metadata includes:
  `client_id`, `app_version`, `build_sha`, `platform`, `env`,
  `sync_session_id`, and optional `user_id_hash`.
- Structured sync events:
  `sync.connect.start`, `sync.connect.success`, `sync.connect.fail`,
  `sync.credentials.fetch`, `sync.token.refresh.start`,
  `sync.token.refresh.success`, `sync.token.refresh.fail`,
  `sync.status.transition`, `sync.upload.queue.high`, `sync.auth.expired`.
- Status telemetry:
  - log transitions only when `connected`/`downloading`/`uploading`/`hasSynced`
    changes.
  - emit throttled snapshots (target: every 60 seconds).

## Sync issue persistence contract

- Upload/runtime anomalies may be persisted to `public.sync_issues` for
  diagnostics.
- Writes are user-scoped and deduplicated by `(user_id, fingerprint)`.
- Repeated anomalies increment `occurrence_count` and update `last_seen_at`.
- Persistence is best-effort and must not block sync upload progress.

## Testing minimums

- Startup gate state machine.
- Auth-to-app and onboarding-to-app transitions.
- Recovery behavior for failed initial sync.
