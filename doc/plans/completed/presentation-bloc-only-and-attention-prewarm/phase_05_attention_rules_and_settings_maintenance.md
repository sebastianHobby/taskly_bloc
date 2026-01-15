# Phase 05 — Attention Rules + Settings Maintenance (UI repo-free)

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T10:45:52.1300375Z (UTC)

## Outcome

- Remove non-BLoC domain/data access from UI for:
  - `AttentionRulesSettingsPage`
  - Settings “danger zone” actions (template seeding, clear local data)

## Work

1) `AttentionRulesCubit`
- Load/watch rules.
- Expose `toggleRule(ruleId)`.
- UI uses `BlocBuilder` only.

2) Settings maintenance bloc
- Create a `SettingsMaintenanceCubit` that depends on:
  - a `TemplateDataService` (or a domain-level facade)
  - a `LocalDataMaintenanceService` that wraps PowerSync operations
- UI only dispatches intents and renders state.
- Remove `GetIt.instance<PowerSyncDatabase>()` from widget code.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Ensure any analyzer errors/warnings caused by this phase are fixed by the end of the phase.
