# Phase 03 — B1 Journal hub UI (Today / History / Trackers)

Created at: 2026-01-13T12:16:40Z
Last updated at: 2026-01-13T12:19:51Z

## Goal

Implement the Daylio-first B1 Journal experience:

- One top-level navigation item: **Journal**
- Inside Journal: **Today | History | Trackers**
- Mood is recorded per log event
- Notes are part of the journal entry text (optional)
- Insights is a placeholder surface

## Scope

- New Journal hub page with internal navigation.
- Today page: quick-add events + list of today’s log events.
- History page: date-based browsing of past events.
- Trackers page: manage trackers (system + user), preferences (pin/visibility/order), and creation flow.

## UX requirements

- Fast logging flow:
  - Add Log: choose mood + optional note + optional tracker events.
  - Support “quick add” pinned trackers.
- No split between daily and per-entry trackers.

## Implementation notes

- Reads should come from projection tables for performance.
- Writes should append `tracker_events`.

## Screen model alignment (unified screen system)

This repo’s primary navigation path for system screens is the unified screen model.
For Journal, we should prefer one of these patterns:

1) **Single system screen spec** (recommended): `journal` (or `journal_hub`) renders the hub UI directly via a screen template/module.
2) **Multiple system screen specs**: separate `journal_today`, `journal_history`, `journal_trackers` screens.

Given your earlier decision (“Journal is a single bottom-nav item with internal tabs”), choose (1) and implement Today/History/Trackers as internal tab routes within the Journal hub.

If the unified screen system currently expects `*_dashboard` templates, keep a temporary `journal_dashboard` spec during cutover, but migrate to a `journal_hub` template/module naming in this phase.

## Data flow contract (B1)

Minimum read models needed for UI:

- Today
  - list of today’s log items (timestamp, mood, note)
  - per-log tracker chips (resolved display text + icon)
  - pinned trackers + quick-add config (from `tracker_preferences`)

- History
  - date buckets with counts
  - lazy load day details

- Trackers
  - tracker list (definitions + preferences)
  - create/edit flow for user trackers (definition + choices)

Minimum write commands needed:

- `createJournalLog(...)`:
  - creates a log item (if journal entry is a distinct table) OR uses tracker_events as the canonical log (mood/note can be represented as system trackers)
  - appends `tracker_events` for mood + any selected tracker events

## Concrete touchpoints / file targets

Routing and specs:

- [lib/presentation/routing/routing.dart](../../../lib/presentation/routing/routing.dart)
- [lib/presentation/routing/router.dart](../../../lib/presentation/routing/router.dart)
- [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)
- [lib/presentation/screens/templates/screen_template_widget.dart](../../../lib/presentation/screens/templates/screen_template_widget.dart)

New presentation feature package (post-Phase 01 rename):

- `lib/presentation/features/journal/view/journal_hub_page.dart`
- `lib/presentation/features/journal/view/journal_today_page.dart`
- `lib/presentation/features/journal/view/journal_history_page.dart`
- `lib/presentation/features/journal/view/journal_trackers_page.dart`
- `lib/presentation/features/journal/widgets/add_log_sheet.dart`

State management (suggested):

- `JournalHubBloc` or equivalent (tab state + top-level loading)
- `JournalTodayBloc` (today list + create log)
- `JournalHistoryBloc` (history query)
- `JournalTrackersBloc` (definitions + preferences + create tracker)

Note: keep BLoCs small and prefer repository streams for reactive UI.

## Acceptance criteria

- Journal hub loads and functions end-to-end against local DB.
- Creating an event updates Today immediately.
- Trackers page reflects preferences ordering and visibility.
- `flutter analyze` clean.

## AI instructions

- Review doc/architecture/ before implementing.
- Run `flutter analyze` for this phase.
- Fix any errors or warnings introduced (or discovered) by the end of the phase.
- If screen templates/modules are added, update doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md.

## Verification

- `flutter analyze`
