# Phase 00 — Scope, Rules, and Safety Rails

## Goal
Remove **workflow feature** (UI + local persistence) from the Flutter app while keeping the codebase compiling and preserving the Attention System behavior.

## Non-goals
- Do not fix failing tests until the final phase.
- Do not change unrelated features.

## Definitions
- **Workflow feature**: the `lib/**/workflow/**` feature surfaces (list/create/run), its BLoCs, repositories, models, and local Drift tables.
- **Attention compatibility**: keep `workflowStep` attention rule type as a no-op unless explicitly purging it.

## Guardrails
- After *every* phase: run `flutter analyze` and fix all compile errors introduced by that phase.
- Prefer deleting code over leaving dead routes/links.
- Keep behavior changes minimal and explicit.

## Verification command (run after every phase)
- `flutter analyze`

## Optional note for maintainers
The repository currently has no Supabase migration files under `supabase/migrations/`. That does not mean production is unaffected; it only means server-side changes are not tracked here.
