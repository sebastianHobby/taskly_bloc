# Phase 06 — Tests, Cleanup, and Backend Reminders (final)

## Goal
Finish cleanup, then run tests and fix failures.

## Cleanup checklist
- Run a final repo-wide search for `workflow` and remove any remaining dead references.
- Verify Settings, routing, and screen templates no longer mention workflows.

## Verification (compile)
- Run `flutter analyze` and fix any remaining analyzer issues.

## Tests (only in this final phase)
1. Run fast unit/widget tests:
   - `flutter test --fail-fast`
2. Fix test failures caused by workflow removal.
3. (If applicable) run integration tests:
   - `flutter test test/integration_test --dart-define-from-file=dart_defines.local.json`

## IMPORTANT: Backend + sync reminder for the AI (prompt the user)
When completing this phase, explicitly remind the user:
- Supabase schema/policies/types may still contain workflow tables/types and must be updated to match the removed feature.
- PowerSync sync rules must be reviewed/updated (even if workflows are not currently synced), and any production buckets/queries that reference workflow tables must be removed.

Suggested prompt to user:
"Reminder: if you remove workflows from the app, make sure Supabase schema (tables/types/RLS) and any PowerSync sync rules or server-side queries are updated accordingly, otherwise sync or runtime may break in production."
