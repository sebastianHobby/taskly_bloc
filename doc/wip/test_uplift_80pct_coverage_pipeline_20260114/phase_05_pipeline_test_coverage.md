# Phase 05 — Local-stack pipeline coverage (smoke + extended)

Created at: 2026-01-14T07:44:19Z
Last updated at: 2026-01-15T00:00:00Z

## AI instructions (required)

- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings **caused by this phase’s changes** by the end of the phase.
- Review `doc/architecture/` before implementing and keep architecture docs updated if this phase changes architecture.
- During the phase: focus on tests that compile (and are safely skipped by default); avoid repeatedly running test/coverage commands while scaffolding.
- End of phase: run **exactly one** pipeline command (smoke or extended) to validate.

## End-of-phase verification (run once)

Recommended VS Code task (smoke tier):

- `pipeline_smoke`

If (and only if) you changed extended-tier scenarios, run instead:

- `pipeline_extended`

## Intent

Add high-confidence end-to-end sync coverage for the real stack:
- local SQLite/Drift
- PowerSync
- Supabase PostgREST + RLS

These tests must be:
- tagged `pipeline`
- safe to run intentionally
- self-skipping unless configured for *local* endpoints

## Current state (good foundation)

- Pipeline test file exists: `test/integration_test/powersync_supabase_pipeline_test.dart`
- Tagged: `@Tags(['integration', 'pipeline'])`
- Local-only guards (`localhost` / `127.0.0.1`)
- Opt-in define is documented: `RUN_POWERSYNC_SUPABASE_PIPELINE_TESTS=true`

## Deliverables

### 1) Split into two tiers

1) Pipeline smoke (fast-ish, minimal flake)
- upload: Drift write -> PowerSync upload -> row visible via PostgREST
- download: PostgREST update -> PowerSync download -> Drift reflects change

2) Pipeline extended (slower, but very high confidence)
- joins rewrite semantics
- RLS boundary behavior
- conflict handling (23505 / deterministic tables)
- disconnect/reconnect resilience
- batching mixed operations

### 2) Deterministic seeding and cleanup

Use consistent scripts/fixtures for:
- truncation/reset (see `supabase/` scripts)
- deterministic IDs where relevant

### 3) Suite entrypoint

Add/standardize the canonical command(s) in docs and VS Code tasks:
- a task for pipeline smoke
- optionally a task for extended

## Acceptance criteria

- Smoke tier runs reliably on a configured local stack.
- Extended tier can run intentionally and provides high diagnostic value.
- Pipeline tests never accidentally run against non-local endpoints.

## Risks & mitigations

- Risk: flakiness due to async replication timing.
  - Mitigation: build bounded polling helpers with timeouts and clear failure output.
