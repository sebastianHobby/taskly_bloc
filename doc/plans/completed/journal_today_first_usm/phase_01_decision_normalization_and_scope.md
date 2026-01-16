# Phase 01 — Decision normalization + implementation scope

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T14:13:32.9920149Z

## Goal

Turn the locked UX decisions into implementation-ready requirements, confirm screen keys/routes, and define the USM module boundaries for the Journal Today-first screen.

This phase is intentionally “paper + wiring” heavy and “UI build” light.

## Inputs

- Accepted decision doc: [doc/plans/ui_decisions/2026-01-15_journal-ux-ux-001.md](../ui_decisions/2026-01-15_journal-ux-ux-001.md)
- Architecture constraints:
  - Presentation boundary (BLoC-only)
  - Unified Screen Model invariants and screenKey stability

## Deliverables

1) Decision doc updates
- Convert UX-020A, UX-021B, UX-022B, UX-023A, UX-024A into explicit, testable statements.
  - Each must include: “What user does”, “What system does”, and any edge-case notes.
- Confirm and document UX-019C and UX-025A alignment (mood is system tracker; mood required).
- Confirm and document UX-026A alignment:
  - `TrackerDefinition.isOutcome` is the only persisted classification field.
  - Default behavior: new trackers are `isOutcome=false`.
  - Classification UI lives only in Manage Trackers / tracker editing (not in Today logging loop).

2) Screen keys + routing decisions
- Confirm whether Journal uses:
  - `journal` (Today-first)
  - `journal_history` (full history browse)
  - `journal_entry_editor` (full-screen add/edit)
  - `journal_manage_trackers` (manage/archived/outcome classification)
- Confirm whether the existing `trackers` system screen remains separate or becomes a redirect/alias.

3) USM module boundaries (no implementation yet)
- Draft the slotted module breakdown (header + primary sections), including which pieces are interactive and therefore must funnel mutations through BLoCs/actions.

## Normalized decisions (output of this phase)

The implementation-ready wording for UX-019..UX-026 is now captured in:
- `doc/plans/ui_decisions/2026-01-15_journal-ux-ux-001.md`

Screen keys/routing decisions:
- `journal`: Today-first surface (USM).
- `journal_history`: History browse (system screen key, not in main nav).
- `journal_manage_trackers`: Manage Trackers (system screen key, not in main nav).
- Entry editor: dedicated full-screen route (not a system screen key).

Module boundary draft (to implement in Phase 02):
- Header slot:
  - `JournalTodayHeroComposerV1` (mood-first + quick tracker selection + “Add log”).
- Primary slot:
  - `JournalTodayEntriesV1` (today’s entries list; entry tap -> editor route).
  - `JournalPreviousDaysTeaserV1` (last few days + “See all history”).

## Acceptance criteria

- The decision doc contains implementation-ready wording for UX-020..UX-024.
- A clear mapping exists from decisions → screen keys/routes → module boundaries.
- No architecture boundary violations are introduced.

## Risks / notes

- Some decisions are currently recorded as “Accepted but not yet transcribed”; this phase eliminates ambiguity before code work.

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- When the phase is complete, update:
  - `Last updated at:` (UTC)
  - `Completed at:` (UTC)
  - A short summary of what changed

## Completion

Completed at: 2026-01-15T14:13:32.9920149Z
Summary:
- Normalized UX-020..UX-024 into implementation-ready statements.
- Locked routing/screen-key choices and drafted USM module boundaries.
