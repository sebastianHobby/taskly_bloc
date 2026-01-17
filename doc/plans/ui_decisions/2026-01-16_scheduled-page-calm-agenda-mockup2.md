# Scheduled Page — Calm Agenda (Mockup 2 alignment)

Created at: 2026-01-16 (UTC)
Last updated at: 2026-01-16T06:24:19.2555476Z

## Context

We reviewed the current Scheduled page implementation and compared it to two external agenda mockups (with particular interest in the “mockup 2” flatter, calmer list style).

Key code anchors:
- Screen spec: Scheduled uses `agendaV2` module: `system_screen_specs.scheduled`
- Renderer: `AgendaSectionRenderer` (day-cards feed)
- Entity rows: `TaskViewVariant.agendaCard` and `ProjectViewVariant.agendaCard`
- Metadata chips: `_MetaLine` (task + project variants)

Related implementation plan:
- Full USM tile system (global): `doc/plans/backlog/usm_full_tile_system_global_actions/`

## Product Direction (decision)

Scheduled should express a **calm, value-aligned productivity** experience.

Implications:
- Reduce “dashboard / alert feed” feel.
- Maintain strong **values scanning** (primary value must be easy to identify).
- Keep urgency signals precise and “earned” (strong red reserved for overdue).

## Domain Constraints (confirmed)

- Scheduled is **date-based only** (no time-of-day scheduling).
- Tags are already computed and semantically defined:
  - `starts`: the item’s `startDate` falls on the day.
  - `due`: the item’s `deadlineDate` falls on the day.
  - `inProgress`: the day is strictly between start and deadline.
- Therefore, “in progress” is **span-derived**, not completion-status.

## Decisions (persisted)

### UI-D001 — Rename “In progress” label to “Ongoing”

Decision: Use **Ongoing** in the UI instead of “In progress”.

Rationale:
- Better matches actual semantics (span-derived).
- Calmer tone and avoids implying completion/status.

Scope:
- Applies to the status pill/badge label for `AgendaDateTag.inProgress`.

### UI-D002 — Align Scheduled visual language toward “mockup 2”

Decision: Move toward the flatter, calmer list language:
- Lighter grouping and card chrome.
- Status communicated via a small pill.
- Left accent use is allowed, but should be muted.

Notes:
- Current code already resembles this via agenda cards + left accent bar.
- Main gap is information density and token “chip soup” risk.

### UI-D003 — Values are primary scanning primitive

Decision: Values are a key aspect of Taskly and should remain easily scannable.

Direction:
- Primary value should be visible at a glance.
- Secondary values should be discoverable but less visually dominant.

Proposed encoding:
- Primary value: **icon-only**, **filled** (strongest but still calm).
- Secondary values: icon-only outlined up to a small limit or summarized as `+N`.

### UI-D004 — Priority should be encoded subtly (avoid explicit “P#” by default)

Decision: Explore encoding priority as a subtle UI hint rather than showing `P1/P2/...` directly in the default row presentation.

Rationale:
- Keeps Scheduled calm and avoids turning it into a “status dashboard”.
- Preserves prioritization for users who want it.

Candidate encodings (not yet chosen):
- Slight title weight or opacity.
- Neutral “tick” thickness.
- Small shape (diamond/circle/dot) with tooltip.

## Design Options (tracked, not chosen)

We outlined three implementation-level options for the default row density:

- Option A: **Minimal + expand for full meta** (recommended)
  - Always: status pill, title, primary value icon, project/inbox context.
  - Expand: full `_MetaLine` details.

- Option B: **One-line meta (no wrapping)**
  - Always: primary value + minimal secondary summary, optional repeat icon, one date token.

- Option C: **Value-forward**
  - Values dominate; project and priority become minimal glyphs.

## Open Questions

### UI-Q001 — Row density choice
Which default presentation should Scheduled use?
- A) Minimal + expand
- B) One-line meta
- C) Value-forward

### UI-Q002 — Priority encoding
If we hide explicit `P#`, which subtle encoding should we use (if any) and where should it live?

### UI-Q003 — Ongoing rows: show/hide date chips
Current agenda styling hides date chips on ongoing rows (`showDates=false` for in-progress style). Should ongoing rows still show a deadline hint/date chip for clarity?

### UI-Q004 — Row actions visibility
Should the per-row overflow menu be:
- Always visible (current), or
- Shown on hover/selection (desktop) / long-press (mobile) to reduce chrome?

### UI-Q005 — Grouping structure
Keep existing blocks (Today/This week/Next week/Later) or shift toward a continuous feed with lighter section headers?

## Implementation (record)

### Chosen answers (from “implement full plan”)
- UI-Q001: Option A (Minimal + expand)
- UI-Q002: Priority encoding = subtle dot (default)
- UI-Q003: Ongoing rows show a deadline chip (start date hidden)
- UI-Q004: Overflow actions show on hover/focus for desktop; always visible on touch
- UI-Q005: Keep existing grouping blocks

### New spec-driven knobs (added)
To avoid renderer forks and keep Scheduled configurable, agenda presentation is controlled via `EntityStyleV1`:
- `agendaMetaDensity`
- `agendaPriorityEncoding`
- `agendaActionsVisibility`
- `agendaPrimaryValueIconOnly`
- `agendaMaxSecondaryValues`
- `agendaShowDeadlineChipOnOngoing`

## Next Suggested Steps

1. Choose UI-Q001 (A/B/C) and UI-Q002 (priority encoding approach).
2. Implement UI-D001 (label change) and values icon policy in the agenda card variant.
3. Iterate on group headers + filter/search affordances after density is settled.

## USM Alignment Plan (Option 2 — Full Tile System)

Repo-grounded scope notes:
- Scheduled already uses `ScreenItemTileBuilder` for entity tiles; the remaining USM gap is primarily **mutations inside tiles**.
- `TaskView`/`ProjectView` currently call domain mutation services via DI in overflow menus; these should emit intents and let screens route mutations through `ScreenActionsBloc`.

Effort estimate (engineering): ~2–5 dev days end-to-end, depending on how many non-USM screens also rely on the current tile-internal DI actions.

Long-term maintenance mental model:
- Tiles become “dumb”: rendering + intent emission only.
- `ScreenItemTileBuilder` is the central construction point (mapping `ScreenItem + EntityStyleV1 -> widget variant`).
- `ScreenActionsBloc` becomes the single mutation funnel for pin/delete/complete.
