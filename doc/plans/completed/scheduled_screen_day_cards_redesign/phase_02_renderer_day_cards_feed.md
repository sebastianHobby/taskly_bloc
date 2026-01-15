# Phase 02 — Renderer: Day Cards Feed + Grouping + Range

Created at: 2026-01-15T05:07:20Z
Last updated at: 2026-01-15T11:40:16.5322380Z

## Objective
Implement the new Scheduled UI in the agenda renderer when `layout == agendaDayCardsFeed`.

## UX requirements (approved)
- No timeline.
- Day Cards feed grouped into:
  - Today
  - Next 7 days
  - Later (or Later this month) with collapse/expand
- Range control:
  - Presets (Today, Next 7 days, This month, Next month)
  - Jump to specific week
  - Jump to specific month
- Keep Search + Filter entry points (existing bottom sheets are fine).

## Target files (expected)
- `lib/presentation/screens/templates/renderers/agenda_section_renderer.dart`
  - Add a new branch for `agendaDayCardsFeed`.
  - Implement group headers + feed rendering.
  - Introduce range controller state (UI-ephemeral) *only* in renderer/widget layer.

## Required plumbing (must be done before this phase)
- `AgendaSectionRenderer` must receive `AgendaSectionParamsV2 params` from `SectionWidget`.
- Renderer must branch on `params.layout`:
  - `agendaDayCardsFeed` => new UI
  - (temporary) `timelineMonthSections` => legacy UI until Phase 05

## Concrete UI structure (no ambiguity)

### Top bar actions
Keep existing affordances, but in day-cards mode the header must include:
- Search icon => existing search bottom sheet
- Filter icon => existing filter bottom sheet
- Range button (new) => opens range bottom sheet

### Range bottom sheet
Must include:
1) Presets
- Today
- Next 7 days
- This month (default)
- Next month

2) Jump actions
- Jump to week: user picks any date; sheet converts to Monday-start week range
- Jump to month: user picks any date; sheet converts to month range

### State model (in `_AgendaSectionRendererState`)
Add:
- `_DateRangePreset _rangePreset` enum
- `DateTime _rangeStart` (date-only local)
- `DateTime _rangeEndExclusive` (date-only local)
- `bool _laterExpanded`

Initialization:
- In `initState`, set range to “This month” as defined in Phase 00.

### Data source
Use only:
- `widget.data.agendaData.groups` (list of `AgendaDateGroup`)
- `widget.data.agendaData.loadedHorizonEnd` (may be null)

No other reads.

## Search + filter ownership (SCH-003A)
- Keep the existing Search + Filter entry points and their current presentation ownership.
- Search/filter state must be owned by presentation BLoCs (e.g. the existing bottom sheet flows).
- The day-cards renderer/widget consumes that presentation state and applies it when filtering the already-provided `agendaData.groups`.
- The renderer must not introduce any new repository/service reads or domain/data stream subscriptions.

## Filtering algorithm (exact)

1) Start from domain groups
- Let `allGroups = widget.data.agendaData.groups`

2) Clamp selected range to loaded horizon
- If `loadedHorizonEnd != null` and `rangeEndExclusive > dateOnly(loadedHorizonEnd) + 1 day`:
  - Set `effectiveRangeEndExclusive = dateOnly(loadedHorizonEnd) + 1 day`
  - Show inline note: “More dates not loaded yet.”

3) Filter by selected range
- Keep groups where `group.date` is in `[rangeStart, effectiveRangeEndExclusive)`.

4) Apply search + filters
- Search applies to `AgendaItem.name` (case-insensitive contains).
- Entity filter applies to `AgendaItem.isTask`/`AgendaItem.isProject`.
- Tag filter applies to `AgendaItem.tag`.
- If a date group becomes empty after filtering:
  - Omit it from the feed (do not show empty day cards).

## Grouping into Day Cards blocks (exact)
Compute `anchorDay` as defined in Phase 00.

Partition the filtered date groups into:
- `anchorGroups`: dates in `[anchorDay, anchorDay+1 day)`
- `next7Groups`: dates in `[anchorDay+1 day, anchorDay+8 days)`
- `laterGroups`: dates in `[anchorDay+8 days, effectiveRangeEndExclusive)`

Rendering rules:
- Render each block with a header.
- “Later” block:
  - If `laterGroups.length > 7`, default collapsed:
    - show first 3 dates only + an “Show all later (N dates)” button
  - Expanded shows all later dates.

## Day Card rendering (exact)
For each date group:
- Card header must show:
  - Semantic label (Today/Tomorrow) only if it matches real today/tomorrow
  - Always include absolute date (e.g., “Wed, Jan 15”)
- Card body:
  - Render `AgendaItem`s grouped by tag sections in this order:
    1) Due
    2) Starts
    3) In Progress (collapsed section by default)

In-progress collapse:
- If there are > 0 `inProgress` items on the date:
  - Show a one-line “In progress (N)” row with expand/collapse.

## Acceptance criteria
In addition to the existing ones:
- Range preset switching changes the visible day cards deterministically.
- Jump-to-week and jump-to-month produce the exact ranges defined in Phase 00.
- No empty day cards render.

## Legacy timeline renderer removal
- Once the Scheduled spec is migrated and no other screens use it, remove timeline-only rendering paths tied to `timelineMonthSections`.
- If other screens still use timeline, keep the timeline branch only until they are migrated; do not leave dead code.

## Data shaping rules (high level)
- Renderer must not subscribe directly to repos/services; it consumes section view-model data from the USM pipeline.
- Grouping logic should operate on already-provided section entities:
  - Partition by effective date (deadline/start; follow existing Scheduled behavior for what counts as “scheduled”).
  - Apply UI grouping (Today/Next 7/Later) based on selected range anchor.

## Range model
- Internal representation: `DateTimeRange` (UTC-normalized) or `(start, endExclusive)`.
- Presets compute a range relative to “now” (with day-boundary semantics consistent with the app’s day key service if accessible at UI layer).

## Acceptance criteria
- Scheduled renders a scrollable Day Cards feed.
- Group headers and collapsing behave deterministically.
- Search + Filter actions remain accessible.
- No analyzer errors introduced.

## AI instructions (strict)
- Review `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md` and confirm renderer changes remain presentation-only.
- Run `flutter analyze` for this phase.
- Fix analyzer issues caused by this phase’s changes by end of phase.

## Completed
Completed at: 2026-01-15T11:40:16.5322380Z

Summary:
- Implemented the day-cards feed UI in the agenda renderer, including range presets, jump-to-week/month, horizon clamp note, grouping, and in-progress collapse.
