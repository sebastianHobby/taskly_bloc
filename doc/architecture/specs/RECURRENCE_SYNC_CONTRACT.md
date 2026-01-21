# Recurrence + PowerSync Sync Contract (MVP)

> Audience: developers + architects
>
> Scope: the recurrence storage + write semantics + sync constraints for Taskly’s
> offline-first (Drift + PowerSync) and Supabase (Postgres + PostgREST + RLS)
> pipeline.
>
> This document consolidates the locked decisions in
> `doc/taskly_migration_outline.md` into an implementer-facing contract.
>
> It does **not** prescribe screen/product behavior such as *which* occurrence a
> user intent should target. That selection belongs in domain-level command
> services (see `doc/architecture/INVARIANTS.md`, section 4.3).

## 1) Core invariants

### 1.1 Offline-first + layering

This contract assumes Taskly’s offline-first model and standard layering.

See:

- [../INVARIANTS.md](../INVARIANTS.md#5-offline-first--powersync-constraints)
- [../INVARIANTS.md](../INVARIANTS.md#2-presentation-boundary-bloc-only)

### 1.2 Date-only semantics

- `localDay` and all recurrence occurrence keys are **date-only** values.
- Encoding: `YYYY-MM-DD`.
- Canonical representation in Dart: UTC-midnight `DateTime` paired with
  date-only codecs/converters.

### 1.3 PowerSync write limitation (SQLite views)

PowerSync applies schema using SQLite views. SQLite does **not** allow
`INSERT ... ON CONFLICT DO UPDATE` (UPSERT) against views.

Canonical rule:

- [../INVARIANTS.md](../INVARIANTS.md#52-sqlite-views-no-local-upsert-against-powersync-tables)

Recommended view-safe patterns:

- **Update-then-insert** for “upsert-like” semantics.
- **Insert-or-ignore** for append-only/idempotent rows.

Reference: `doc/architecture/deep_dives/POWERSYNC_SUPABASE.md`.

## 2) Tables (logical model)

We unify recurrence storage across entity types.

### 2.1 `completion_history`

One row per completion event.

Key points:

- Has an `id` column (UUID in Supabase; TEXT UUID-string locally). PowerSync
  replication requires an `id` column on replicated tables.
- Contains `user_id` for ownership + RLS.
- Contains date-only occurrence keys for repeating completions.

Locked invariants (summary):

- Repeating: `original_occurrence_date` and `occurrence_date` are non-null.
  `occurrence_date` equals displayed date (may differ from `original` if
  rescheduled).
- Non-repeating: both are null.
- Uniqueness (logical):
  - repeating: one completion per `(entity_type, entity_id, original_occurrence_date)`
  - non-repeating: one completion per `(entity_type, entity_id)` where
    occurrence keys are null.

Mutability:

- Only `notes` is editable after the row is written.

Deletion:

- “Uncomplete” is modeled as hard delete of the matching completion row.

### 2.2 `recurrence_exceptions`

One row per exception for a specific original RRULE occurrence.

Key points:

- Has an `id` column (UUID in Supabase; TEXT UUID-string locally).
- Contains `user_id` for ownership + RLS.
- `original_occurrence_date` is required (exceptions apply only to RRULE series).

Kinds:

- `skip`: removes the occurrence from Scheduled.
- `reschedule`: moves the displayed occurrence date and may override due date
  (deadline).

Uniqueness:

- At most one exception per `(entity_type, entity_id, original_occurrence_date)`.
  This makes `skip` vs `reschedule` mutually exclusive.

Edit/undo semantics:

- Edit reschedule = replace: delete the previous reschedule row for the original
  date, then insert a new reschedule row.
- Unskip/unreschedule delete the matching exception row.

## 3) IDs and deterministic idempotency

### 3.1 Deterministic IDs

For idempotent occurrence writes, completion/exception rows use deterministic IDs
(“UUIDv5-like”). The same logical write yields the same `id` across retries.

Guidelines:

- Use an explicit namespace per table + kind.
- Deterministic inputs use canonical identity fields:
  - completion: `(entity_type, entity_id, original_occurrence_date, kind)`
  - reschedule exceptions: include `new_date` in the deterministic input (because
    editing a reschedule is replace-by-delete+insert)

### 3.2 Deterministic ID conflict policy

Treat “same deterministic ID” as “same logical event”.

- Local writes should use view-safe patterns:
  - append-only inserts: `insertOrIgnore`
  - edits: update-then-insert
- If an insert conflicts but the existing row differs materially from the
  attempted payload, emit a diagnostic signal (`SyncAnomaly`) and do not
  overwrite.

## 4) Ownership and RLS (Supabase)

### 4.1 `user_id` is server-owned

- `user_id` is derived from the authenticated Supabase JWT.
- Clients must not set or override `user_id` in write payloads.

### 4.2 RLS policy shape

- `SELECT`: only rows where `user_id = auth.uid()`.
- `INSERT`: allowed for own rows (with `user_id` defaulted/validated on server).
- `UPDATE`: denied except `notes` updates on `completion_history`.
- `DELETE`: allowed for own rows.

### 4.3 DB enforcement

- Prefer default `user_id = auth.uid()` on insert and prevent override.
- Do not add triggers for “completion wins” in MVP; enforce in repository/write
  helper.

## 5) Write operations (domain → data) and collision rules

### 5.1 Supported operations (MVP)

- `SkipOccurrence`: insert skip exception.
- `UnskipOccurrence`: delete skip exception.
- `RescheduleOccurrence`: insert reschedule exception.
- `EditRescheduleOccurrence`: replace exception (delete + insert).
- `UnrescheduleOccurrence`: delete reschedule exception.
- `CompleteOccurrence`: insert completion row.
- `UncompleteOccurrence`: delete completion row.
- `EditCompletionNotes`: update `notes`.

### 5.2 Collision rule (“completion wins”)

If a completion exists for `(entity_type, entity_id, original_occurrence_date)`,
then skip/reschedule writes for that same original date must be rejected/ignored
and produce a `SyncAnomaly`.

Rationale:

- Keeps expansion deterministic.
- Avoids “completed but skipped” contradictions.

## 6) Implementation guidance (PowerSync-safe)

## 6.0 Architecture alignment (see INVARIANTS)

Architecture rules (layering, PowerSync constraints, exception policy, etc.)
live in `doc/architecture/INVARIANTS.md`. This section only covers
recurrence-specific implementation guidance.

### 6.1 Single write surface

To prevent drift:

- All recurrence writes must flow through a single data-layer write helper (or
  repository) that:
  - enforces the invariants
  - uses view-safe local write patterns
  - normalizes payloads
  - emits `SyncAnomaly` when needed

No other code should write directly to recurrence tables.

### 6.2 Local uniqueness enforcement

Do not rely on local unique indexes for exception uniqueness.

- Enforce “one exception per original date” in the write helper:
  - read existing exception for key
  - delete/ignore per policy

### 6.3 PostgREST usage

- Keep direct table endpoints for MVP.
- Inserts use idempotent insert semantics (no overwrite upsert).
- Undo uses deletes.
- Notes edits use update by `id`.

## 7) Diagnostics: `SyncAnomaly`

Because prod UX does not surface sync conflicts, diagnostics are key.

Emit a `SyncAnomaly` when:

- deterministic ID conflicts with materially different payload
- “completion wins” blocks a skip/reschedule
- server rejects a local write that was applied locally

Diagnostics should include:

- `correlationId`
- `entity_type`, `entity_id`
- `original_occurrence_date`
- attempted operation kind

## 8) Checklist (schema + replication)

Before implementing features that depend on recurrence tables:

- Supabase migrations added/updated:
  - tables
  - indexes
  - check constraints
  - RLS policies
  - `user_id` defaults/validation
- PowerSync sync rules updated to include:
  - tables
  - required columns
- Local schema updated:
  - TEXT UUID `id`
  - date-only converters
- Upload normalization updated (if any new JSON/text columns are added).

Guardrail (recommended):

- Run `dart run tool/no_powersync_local_upserts.dart` to ensure Drift UPSERT helpers
  are not used in PowerSync write paths.

## 9) Suggested tests (high leverage)

- Deterministic ID generation (stable across runs).
- Transition tests for one original date:
  - reschedule replace
  - unreschedule delete
  - complete then reject skip/reschedule
  - uncomplete then allow exception
- Notes edit updates only `notes`.
- Local write helper never emits UPSERT SQL (regression test via integration
  assertions around Drift operations, if feasible).
