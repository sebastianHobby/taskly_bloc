# Phase 03 — JournalToday + AddLogSheet (BLoC-only UI)

Created at: 2026-01-14T10:45:52.1300375Z (UTC)
Last updated at: 2026-01-14T10:45:52.1300375Z (UTC)

## Outcome

- Remove `StreamBuilder` + `repo.watch*()` usage from:
  - `JournalTodayPage`
  - `AddLogSheet`

## Work

1) `JournalTodayBloc`
- Own all subscriptions (defs, prefs, entries, events).
- Emit a single state/view-model:
  - pinned trackers
  - entries list
  - entryId -> events map
  - mood tracker id lookup
- UI becomes a pure renderer via `BlocBuilder`.

2) `AddLogCubit`
- Own local UI state (mood/note/selected trackers) and saving state.
- Provide `loadQuickAdd()` (or keep a watched list) and `save()` command.
- Move all repo access out of the widget.

## Files likely involved

- `lib/presentation/features/journal/view/journal_today_page.dart`
- `lib/presentation/features/journal/widgets/add_log_sheet.dart`
- New bloc files under `lib/presentation/features/journal/bloc/`

## Acceptance criteria

- No `getIt<JournalRepositoryContract>()` in the two widgets.
- No `StreamBuilder` in `JournalTodayPage` or `AddLogSheet`.
- Saving a log behaves exactly the same as before.

## AI instructions

- Review `doc/architecture/` before implementing changes.
- Run `flutter analyze` for this phase.
- Ensure any analyzer errors/warnings caused by this phase are fixed by the end of the phase.
