# Scheduled Screen Redesign (Day Cards Feed)

Created at: 2026-01-15T05:07:20Z
Last updated at: 2026-01-15T11:40:16.5322380Z

## Goal
Redesign the Scheduled screen to the approved non-timeline UX direction:

- UX-102B: Day Cards feed (no timeline)
- UX-102T(A): Full-text tag pills (Due/Start/…)
- UX-102B-G1: Smart grouping (Today / Next 7 / Later)
- UX201B: Range control (presets + jump to specific week/month)
- Keep existing Search + Filter entry points (bottom sheets)

## Non-goals
- No new data access from widgets (must remain BLoC/USM compliant).
- No changes to domain data model semantics beyond what is required to present the approved UI.

## Definitions (implementation must follow these exactly)

### Time basis
- **All UI grouping/range math uses local time** (`DateTime.now()`), and normalizes to date-only boundaries via `DateTime(year, month, day)`.
- **Range boundaries are start-inclusive, end-exclusive**.

### Included entities
The Scheduled feed renders entities that already appear in `AgendaData.groups` from the domain pipeline.

Practically (because the agenda data service already computes these tags), this means:
- Tasks/projects may appear on:
	- `AgendaDateTag.due` dates (deadline)
	- `AgendaDateTag.starts` dates (start)
	- `AgendaDateTag.inProgress` dates (days between start and deadline)

The renderer must NOT invent new agenda dates by re-reading repositories.

### Grouping model (Day Cards feed)
The feed is grouped into three blocks relative to an **anchor day**:

- `anchorDay`:
	- `today = dateOnly(nowLocal)`
	- `anchorDay = (selectedRangeStart.isAfter(today) ? selectedRangeStart : today)`

Group buckets:
1) **Today/Anchor**
	 - Dates in `[anchorDay, anchorDay + 1 day)`
	 - Header label rules:
		 - If `anchorDay == today`: label is `Today`
		 - Else: label is `Starts <EEE, MMM d>` (must include absolute date)
2) **Next 7 days**
	 - Dates in `[anchorDay + 1 day, anchorDay + 8 days)`
3) **Later**
	 - Dates in `[anchorDay + 8 days, selectedRangeEnd)`
	 - Collapsible by default when it contains more than 7 distinct dates.

### Selected range defaults
Default selected range is **This month**:
- `selectedRangeStart = today`
- `selectedRangeEnd = first day of next month (local)`

### Range presets
- Today: `[today, today + 1 day)`
- Next 7 days: `[today, today + 8 days)`
- This month: `[today, firstDayNextMonth)`
- Next month: `[firstDayNextMonth, firstDayAfterNextMonth)`

### Jump behavior
- Jump to week: week starts **Monday**. For a chosen date `d`,
	- `weekStart = dateOnly(d) - Duration(days: d.weekday - DateTime.monday)`
	- range is `[weekStart, weekStart + 7 days)`.
- Jump to month: for chosen year/month `y/m`, range is `[DateTime(y,m,1), DateTime(y,m+1,1))`.

### Loaded-horizon constraint
The UI can only show dates that exist in `agendaData.groups` and within `agendaData.loadedHorizonEnd`.
- If the user selects a range that extends beyond `loadedHorizonEnd`, the UI must:
	- Clamp to `loadedHorizonEnd` for display, AND
	- Show a small inline note: “More dates not loaded yet.”
	- (No repo calls from UI.)

## Approved “unscheduled” definition (attention rule)
For the deadline-risk attention rule:
- Task is unscheduled if it’s missing both start + deadline, OR
- Start date is in the past and no deadline is set.

(Implemented separately as AR-001A + AR-004A.)

## Architecture decision: how to represent the new layout
We need the Scheduled screen to *accurately name what it is* and to replace the timeline model.

### Option A (recommended): add a new USM layout variant
Add a new layout type under `SectionLayoutSpecV2`, e.g.:
- `agendaDayCardsFeed` (approved name)

Then switch Scheduled’s system spec to use this layout.

**Pros**
- Naming is accurate and durable: the spec expresses “day cards feed”, not “timeline”.
- Better USM hygiene: specs describe composition/intent; renderers follow specs.
- Supports future reuse: other screens can opt into the same layout.
- Enables renderer logic to be strongly typed/branch on layout explicitly.

**Cons**
- Requires touching domain params + potential serialization/codegen (`build_runner`).
- Slightly more surface area (new enum/union variant + mapping).

### Option B: keep old spec layout, switch renderer behavior
Keep `timelineMonthSections` in the Scheduled spec, but render it as day-cards anyway.

**Pros**
- Fewer domain changes; potentially faster to ship.

**Cons**
- Misleading naming: the spec says “timeline” but UI is not.
- Makes future maintenance harder: other readers will assume timeline semantics.
- Increases risk of inconsistent behavior across templates/sections.

**Decision**
Proceed with Option A, with a layout name that matches the UX: `agendaDayCardsFeed`.

## Architecture alignment decisions (locked)

These decisions align the plan with the updated USM invariants.

### SCH-001A — Typed params plumbing (no casts)
- Agenda section params must be carried as typed data on the agenda `SectionVm` variant.
- Rendering must not rely on `as AgendaSectionParamsV2` casts from a loosely typed `params` surface.

### SCH-002A — Mutations funnel
- Any task/project row mutations (complete, pin, delete, etc.) must dispatch events through `ScreenActionsBloc`.
- Failures should be surfaced via the standard page/root listener -> `SnackBar` pattern described in the architecture doc.

### SCH-003A — Search/filter ownership
- Search/filter state remains owned by presentation BLoCs (existing bottom sheets + BLoC wiring).
- The day-cards renderer consumes the resulting presentation state and applies it to already-provided section VM data.
- The renderer must not introduce any new repository/service reads.

## Legacy timeline removal policy
This redesign replaces the timeline model. Plan intent:

- Remove `timelineMonthSections` (and any other timeline-specific code paths) if it is no longer referenced anywhere.
- If it is referenced elsewhere, migrate those usages to the new layout (or an appropriate alternative) first, then delete the legacy implementation.
- Avoid leaving misleading names/branches that imply a timeline exists when it does not.

## AI instructions (strict)
- Before implementing any phase: review `doc/architecture/` docs relevant to USM.
- For each phase: run `flutter analyze` and fix any analyzer issues caused by that phase.
- In the last phase: fix any remaining `flutter analyze` issues even if unrelated.
- Do not implement UI/UX changes beyond the scope above without explicit approval.
DO NOT IMPLEMENT THE PLAN WITHOUT USER CONFIRMING THEY KNOW PLAN IS NOT IN LINE WITH CURRENT ARCHITECTURE.

## Completed
Completed at: 2026-01-15T11:40:16.5322380Z

Implementation note:
- The repo did not match the `SectionLayoutSpecV2.timelineMonthSections` assumptions in this plan; the implementation adapted by introducing `AgendaLayoutV2` on `AgendaSectionParamsV2` and branching in the agenda renderer.
