# Journal 2.0 Mockup Alignment Spec

> Status: In Implementation
> Owner: TBD
> Date: 2026-03-01

## Summary
This spec defines the agreed UI/UX changes to align Taskly Journal with the mockups in `doc/mockups/**`, plus required supporting changes in presentation, domain, and data layers. It also defines acceptance criteria (AC) and data migration requirements for Supabase. System default trackers are toggle-only in UI and write surfaces, enforced in app logic (no DB hard constraint).

## Implementation Progress (Phased)
- Phase 1 - Routing + tracker flow surfaces: Completed
  - Added route-based tracker creation flow (`type -> templates -> configure`) and wired navigation entry points.
- Phase 2 - Tracker model + persistence updates: Completed
  - Added `aggregationKind` end-to-end (domain model, drift schema, PowerSync schema, repository mapping).
- Phase 3 - Manage/Template UX alignment: Completed
  - Flat template list, system toggle-only language, grouped manage surface with activity/aggregate segment and user group ordering.
- Phase 4 - Aggregation semantics and safety: Completed
  - Added aggregate-value resolution (`sum` vs `avg`) in journal day/history/home summaries.
  - Blocked system tracker deletion in write surface (`deleteTrackerAndData`).
- Phase 5 - Supporting architecture + test hardening: Completed
  - Added presentation query service (`journal_tracker_catalog_query_service`).
  - Updated BLoC tests and fixed reorder edge case (fixed-length list mutation bug).
- Phase 6 - Supabase migration drafts: Completed
  - Added migration SQL files for unit expansion and `aggregation_kind` projection updates.
- Phase 7 - Runtime stability + parity iteration: In Progress
  - Fixed quick-capture dependency injection path for bottom-sheet context.
  - Added one-time local DB upgrade repair (`schemaVersion=24`) to normalize `tracker_definitions.aggregation_kind` nulls and prevent stream mapper crashes.
- Phase 8 - Golden-driven parity iteration: In Progress
  - Added/updated journal visual golden coverage for:
    - Home
    - Quick Capture
    - Filter Sheet
    - Insights
    - Manage Trackers (new)
  - Refined home timeline + summary density and manage trackers composition toward mockup structure while keeping tracker rows data-driven.

## Strict Side-by-Side Parity Pass (2026-03-01)

### Pass Result
- Overall parity: Partial (core flows implemented, visual fidelity still behind mockups on Journal Home and Manage Trackers).

### Fixed in this pass
- Journal runtime error root cause addressed via DB migration path (no legacy runtime fallback logic).
- Applied migrations to remote via Supabase CLI:
  - `20260301193000_expand_tracker_unit_kind.sql`
  - `20260301194000_tracker_aggregation_kind_and_projection.sql`
- Added local one-time upgrade repair for pre-migration local snapshots (`aggregation_kind` null backfill on DB upgrade).
- Journal Home header moved closer to mockup:
  - single-line date title format (`Today, Mar 1` style),
  - history action preserved.
- Journal Home add action now opens quick-capture bottom sheet from FAB (mockup-aligned interaction).

### Remaining Visual Delta (High ROI)
- Journal Home:
  - mockup uses denser uppercased section headers (`DAILY SUMMARY`, `MOMENTS`) and tighter vertical rhythm.
  - timeline rail/left metadata spacing still differs from mockup.
  - insight card presence/placement differs from mockup composition.
- Manage Trackers:
  - current tabs (`Trackers/Groups`) differ from mockup single-surface management with top segmented tracker mode.
  - plus action placement and row action affordances still not mockup-close.
- Quick Capture:
  - current content hierarchy is improved but still not visually identical to mockup chip density and section framing.

### Next Patch Targets for Close Match
- P1: Journal Home density + timeline rail exact spacing and card framing.
- P1: Manage Trackers screen composition refactor to mockup structure.
- P2: Quick Capture section spacing, token sizes, and chip rails to match mockup proportions.

## Goals
- Match mockup visual hierarchy, density, and interaction patterns.
- Maintain BLoC-only presentation boundary and theming constraints.
- Support two tracker classes:
  - Activity trackers (event-based, per moment)
  - Aggregate trackers (running total over day; sum or average)
- Respect user-defined groups, ordering, names, icons, and tracker metadata.
- Ensure all tracker lists are data-backed (no static UI-only templates).

## Non-Goals
- Overhauling domain semantics beyond tracker creation and projection changes.
- Introducing non-theme colors or ad-hoc typography.
- Enforcing system tracker immutability in DB (done in app logic only).

## Source Mockups
- `doc/mockups/taskly_home_high_density_dark_1` (Quick Capture)
- `doc/mockups/taskly_home_high_density_dark_2` (Journal Home)
- `doc/mockups/taskly_home_high_density_dark_5` (Journal Home alt)
- `doc/mockups/add_tracker_step_1_type_selection` (Tracker Type)
- `doc/mockups/add_tracker_step_2_configuration` (Tracker Config)
- `doc/mockups/add_tracker_step_2_templates` (Templates)
- `doc/mockups/taskly_home_high_density_dark_3` (Add Tracker with Groups)
- `doc/mockups/taskly_home_high_density_dark_4` (Manage Trackers)

## Architecture Constraints (must comply)
- BLoC-only presentation boundary.
- Theme-driven colors/typography/tokens only.
- No direct repo calls from widgets.
- Grouped tracker accordion remains single-open.
- System text scaling respected.

## Mockup Fidelity AC (global)
- Every updated screen must closely line up with its paired mockup in layout structure, section order, spacing rhythm, and control placement.
- Visual deltas are only allowed when required by:
  - Dynamic content length/data variability
  - Accessibility requirements (text scale, tap targets)
  - Platform behavior constraints
- Theme adaptation is required: mockup colors are reference intent only; implementation must use theme/token semantics.
- PR validation must include side-by-side screenshots for each updated target screen and a short list of intentional deltas.

---

# UI/UX Changes + Acceptance Criteria

## 1) Journal Home (Today Summary + Moments)

### UI Changes
- Replace current header with single-line `Today, <date>`.
- Daily Summary becomes a compact 2x2 tile grid with:
  - Icon top-left in rounded container
  - Small label/meta top-right (target/avg where applicable)
  - Large value at bottom-left
- Add `View All` action on Daily Summary header.
- Moments become a timeline:
  - Left column: mood icon + time
  - Vertical line between moments
  - Right: compact card with note preview and factor chips
- Floating add button matches mockup size/position.

### AC
- Daily Summary shows 4 tiles max; overflow content appears in `View All` detail.
- Moments render as timeline with left rail, time labels, and mood icons.
- Factor chips are compact and deduplicated per tracker.
- All colors from theme/token semantics; no hardcoded hex values in widgets.
- Screen closely lines up with mockup composition and spacing.

---

## 2) Quick Capture Bottom Sheet (New Moment)

### UI Changes
- Remains a bottom sheet (90% height) with updated layout.
- Header: close icon + title; no Reset action.
- Mood selector: emoji tiles with labels below; selected state highlighted.
- Inline `Time of moment` row with icon + time picker.
- Grouped tracker chips are horizontally scrollable per group.
- Daily trackers section has compact rating bar and quantity stepper.
- Note field shows label + character counter.
- Sticky bottom bar with full-width Save button.

### AC
- Sheet remains a bottom sheet, not full-screen route.
- Reset action is removed.
- Mood and time controls match mockup hierarchy and density.
- Save CTA is pinned to bottom with correct insets.
- No overflow at large text sizes.
- Screen closely lines up with mockup composition and spacing.

---

## 3) Journal History

### UI Changes
- Compact pill-style search bar.
- Applied filter chips match mockup density.
- Day cards show Daily Summary tile style (compact 2x2 grid).

### AC
- Search bar and filter chips render in compact style.
- Day cards match the Daily Summary grid visual language.
- Infinite scroll behavior preserved.
- Screen closely lines up with mockup composition and spacing.

---

## 4) Tracker Creation Flow (New Routes)

### Routes
- `journal_tracker_type_selection`
- `journal_tracker_templates`
- `journal_tracker_configure`

### Type Selection
- Two large cards (Activity vs Aggregate).
- No helper tips.

### Templates
- Flat list of templates (no sectioned Popular card grid).
- System defaults appear preselected with toggle on/off.
- System defaults use user-friendly language and are toggle-only.
- User-created trackers appear in list immediately after creation.

### Configure Tracker
- Tracker name field.
- Icon picker.
- Aggregation type selector for aggregate trackers (Sum/Average).
- Unit dropdown (data-backed catalog).
- Daily goal stepper (optional).
- Advanced settings row/accordion.

### AC
- Flow is route-based; Stepper UI removed from default path.
- Template surface is a flat list.
- System defaults are preselected and toggleable.
- User-created trackers appear without restart.
- Group/order/name/icon reflect user-defined data.
- Screens closely line up with mockup composition and spacing.

---

## 5) Manage Trackers

### UI Changes
- Segmented control: Activity vs Aggregate.
- Trackers grouped by user-defined groups.
- Tracker rows show icon, name, subtitle.
- System trackers show toggle only; delete is hidden/disabled.

### AC
- Group order and tracker order follow user-defined sort.
- System trackers cannot be deleted in UI.
- User trackers show edit + delete actions.
- Screen closely lines up with mockup composition and spacing.

---

# Implementation Checklist (File-Level)

## Routing and Navigation
- [x] Add new route keys and builders:
  - `lib/presentation/routing/routing.dart`
  - `lib/presentation/routing/app_router.dart` (or equivalent route registration)
- [x] Wire new route entry points from Journal screens:
  - `lib/presentation/features/journal/view/journal_hub_page.dart`
  - `lib/presentation/features/journal/view/journal_manage_factors_page.dart`

## Journal Home
- [x] Restyle header, summary section, and timeline moments:
  - `lib/presentation/features/journal/view/journal_hub_page.dart`
- [x] Add/refine compact timeline and summary tile widgets:
  - `lib/presentation/features/journal/widgets/journal_today_shared_widgets.dart`
  - `lib/presentation/features/journal/widgets/journal_factor_token.dart`

## Quick Capture Bottom Sheet
- [x] Update bottom-sheet editor layout to mockup-aligned structure:
  - `lib/presentation/features/journal/view/journal_entry_editor_route_page.dart`
- [x] Remove reset action from quick-capture UI:
  - `lib/presentation/features/journal/view/journal_entry_editor_route_page.dart`
- [x] Ensure compact tracker controls:
  - `lib/presentation/features/journal/widgets/tracker_input_widgets.dart`

## Journal History
- [x] Restyle search/filter/day cards:
  - `lib/presentation/features/journal/view/journal_history_page.dart`
  - `lib/presentation/features/journal/widgets/journal_filters_sheet.dart`

## Tracker Creation (Route-based)
- [x] Create type-selection screen:
  - `lib/presentation/features/journal/view/journal_tracker_type_selection_page.dart` (new)
- [x] Create templates flat-list screen:
  - `lib/presentation/features/journal/view/journal_tracker_templates_page.dart` (new)
- [x] Refactor configure screen from wizard flow:
  - `lib/presentation/features/journal/view/journal_tracker_wizard_page.dart` (or split new page)
- [x] Update creation BLoC state transitions:
  - `lib/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart`

## Tracker Catalog Query Service (presentation)
- [x] Add unified query service for tracker/group/preference composition:
  - `lib/presentation/features/journal/services/journal_tracker_catalog_query_service.dart` (new)
- [x] Consume service in templates/manage/editor surfaces.

## Domain Contract and Models
- [x] Add `aggregationKind` to tracker definition model:
  - `packages/taskly_domain/lib/src/journal/model/tracker_definition.dart`
- [x] Update serialization tests:
  - `packages/taskly_domain/test/domain/core/model/serialization_misc_models_test.dart`

## Data Layer
- [x] Persist/map `aggregation_kind`:
  - `packages/taskly_data/lib/src/features/journal/repositories/journal_repository_impl.dart`
  - `packages/taskly_data/lib/src/infrastructure/drift/features/tracker_tables.drift.dart`
  - `packages/taskly_data/lib/src/infrastructure/powersync/schema.dart`

## Supabase Migrations
- [x] Migration A: expand `unit_kind` constraint
  - `supabase/migrations/<timestamp>_expand_tracker_unit_kind.sql`
- [x] Migration B: add `aggregation_kind` + projection updates
  - `supabase/migrations/<timestamp>_tracker_aggregation_kind_and_projection.sql`

## Tests and Validation
- [x] Update/add widget tests:
  - `test/presentation/features/journal/**`
- [x] Update/add data-layer tests:
  - `packages/taskly_data/test/unit/features/journal/**`
- [x] Run:
  - `dart analyze`
  - journal widget tests
  - data-layer journal tests

---

# Data & Domain Supporting Changes

## Presentation Query Service (Recommended)
Create a presentation-layer tracker catalog model consumed by:
- Templates list
- Manage Trackers
- Quick Capture/Editor

Model merges:
- Tracker definitions
- Tracker groups
- Tracker preferences
- System flags

### AC
- Single source of truth for ordering/grouping in presentation.
- Widgets do not consume repository streams directly.

## Domain/Contracts
- Extend tracker definition model with `aggregationKind`.
- Keep `opKind` semantics:
  - `add` = running total semantics
  - `set` = point-in-time semantics

---

# Average Projection Design

## Candidate approaches
1. Store `{sum, count}` in `tracker_state_day.value`, derive avg on read.
2. Compute avg from `tracker_events` on every read.

## Recommended approach
Use option 1: store `{sum, count}` projection payload for `aggregation_kind = 'avg'`.

## Rationale
- Stable read latency for Home/History cards.
- Avoids repeated event-log scans.
- Preserves canonical append-only events.
- Works with existing projection rebuild workflow.

## Projected payload shape (avg)
```json
{"sum": 42.0, "count": 12}
```

## Reducer rules (avg)
- `op = add` with numeric value:
  - `sum += value`
  - `count += 1`
- `op = clear`:
  - delete state row (consistent with existing behavior)
- `op = set`:
  - blocked by app write surface for avg trackers

## Read mapping
- Avg trackers: `avg = sum / count` when `count > 0`; otherwise null.
- Sum trackers: keep current numeric behavior.

### AC
- Avg trackers return correct daily averages from projected state.
- Sum trackers remain unchanged.
- Projection rebuild result matches incremental trigger path.

---

# Supabase Schema Changes (Required)

## A) Expand `unit_kind` constraint
Current `tracker_definitions.unit_kind` check allows only:
`count, ml, mg, minutes, steps`.

Change: allow all supported UI units:
- `count, times, reps, ml, l, oz, cup, mg, g, kg, oz_mass, lb, minutes, hours, steps`

### AC
- Creating tracker with any supported unit does not fail sync.

## B) Add `aggregation_kind` (for Average)
Add to `tracker_definitions`:
- `aggregation_kind text not null default 'sum'` with check `sum|avg`.

Behavior:
- `sum`: existing add projection behavior
- `avg`: projection stores `{sum,count}` and UI derives average

### AC
- Aggregate trackers can be configured as Sum or Average.
- Average values are computed correctly in Daily Summary/History.

## C) System tracker deletions
No DB constraint changes. Enforce in app logic and write surface.

### AC
- System tracker delete attempts are blocked in UI and write APIs.

---

# Draft Supabase Migration SQL (A + B)

## Migration A: expand `unit_kind`
```sql
ALTER TABLE public.tracker_definitions
  DROP CONSTRAINT IF EXISTS tracker_definitions_unit_kind_check;

ALTER TABLE public.tracker_definitions
  ADD CONSTRAINT tracker_definitions_unit_kind_check
  CHECK (
    unit_kind IS NULL OR unit_kind = ANY (
      ARRAY[
        'count','times','reps',
        'ml','l','oz','cup',
        'mg','g','kg','oz_mass','lb',
        'minutes','hours','steps'
      ]::text[]
    )
  );
```

## Migration B: add `aggregation_kind` + update projection reducer
```sql
-- 1) Add column and backfill
ALTER TABLE public.tracker_definitions
  ADD COLUMN IF NOT EXISTS aggregation_kind text;

UPDATE public.tracker_definitions
SET aggregation_kind = COALESCE(aggregation_kind, 'sum');

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET DEFAULT 'sum';

ALTER TABLE public.tracker_definitions
  ALTER COLUMN aggregation_kind SET NOT NULL;

ALTER TABLE public.tracker_definitions
  DROP CONSTRAINT IF EXISTS tracker_definitions_aggregation_kind_check;

ALTER TABLE public.tracker_definitions
  ADD CONSTRAINT tracker_definitions_aggregation_kind_check
  CHECK (aggregation_kind = ANY (ARRAY['sum','avg']::text[]));

-- 2) Reducer includes aggregation_kind context
CREATE OR REPLACE FUNCTION public.tracker_reduce_jsonb_value(
  p_existing jsonb,
  p_op text,
  p_value jsonb,
  p_aggregation_kind text
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  existing_num numeric;
  incoming_num numeric;
  cur_sum numeric;
  cur_count numeric;
BEGIN
  IF p_op = 'clear' THEN
    RETURN NULL;
  END IF;

  IF p_aggregation_kind = 'avg' THEN
    IF p_op <> 'add' OR p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
      RETURN p_existing;
    END IF;

    incoming_num := (p_value #>> '{}')::numeric;
    cur_sum := COALESCE((p_existing ->> 'sum')::numeric, 0);
    cur_count := COALESCE((p_existing ->> 'count')::numeric, 0);

    RETURN jsonb_build_object(
      'sum', cur_sum + incoming_num,
      'count', cur_count + 1
    );
  END IF;

  IF p_op = 'set' THEN
    RETURN p_value;
  END IF;

  IF p_op <> 'add' THEN
    RETURN p_existing;
  END IF;

  IF p_value IS NULL OR jsonb_typeof(p_value) <> 'number' THEN
    RETURN p_existing;
  END IF;

  incoming_num := (p_value #>> '{}')::numeric;
  IF p_existing IS NULL OR jsonb_typeof(p_existing) <> 'number' THEN
    RETURN to_jsonb(incoming_num);
  END IF;

  existing_num := (p_existing #>> '{}')::numeric;
  RETURN to_jsonb(existing_num + incoming_num);
END;
$$;

-- 3) apply_tracker_event_projection reads definition and passes aggregation_kind
CREATE OR REPLACE FUNCTION public.apply_tracker_event_projection(
  p_event_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  ev public.tracker_events%ROWTYPE;
  def public.tracker_definitions%ROWTYPE;
  current_value jsonb;
  next_value jsonb;
BEGIN
  SELECT * INTO ev
  FROM public.tracker_events
  WHERE id = p_event_id;
  IF NOT FOUND THEN RETURN; END IF;

  SELECT * INTO def
  FROM public.tracker_definitions
  WHERE id = ev.tracker_id;
  IF NOT FOUND THEN RETURN; END IF;

  IF ev.anchor_type = 'entry' THEN
    SELECT value INTO current_value
    FROM public.tracker_state_entry
    WHERE user_id = ev.user_id
      AND entry_id = ev.entry_id
      AND tracker_id = ev.tracker_id;

    next_value := public.tracker_reduce_jsonb_value(
      current_value, ev.op, ev.value, COALESCE(def.aggregation_kind, 'sum')
    );

    IF next_value IS NULL THEN
      DELETE FROM public.tracker_state_entry
      WHERE user_id = ev.user_id
        AND entry_id = ev.entry_id
        AND tracker_id = ev.tracker_id;
      RETURN;
    END IF;

    INSERT INTO public.tracker_state_entry (
      user_id, entry_id, tracker_id, value, last_event_id, updated_at
    )
    VALUES (
      ev.user_id, ev.entry_id, ev.tracker_id, next_value, ev.id, now()
    )
    ON CONFLICT (user_id, entry_id, tracker_id)
    DO UPDATE SET
      value = EXCLUDED.value,
      last_event_id = EXCLUDED.last_event_id,
      updated_at = EXCLUDED.updated_at;

    RETURN;
  END IF;

  IF ev.anchor_type IN ('day', 'sleep_night') THEN
    SELECT value INTO current_value
    FROM public.tracker_state_day
    WHERE user_id = ev.user_id
      AND anchor_type = ev.anchor_type
      AND anchor_date = ev.anchor_date
      AND tracker_id = ev.tracker_id;

    next_value := public.tracker_reduce_jsonb_value(
      current_value, ev.op, ev.value, COALESCE(def.aggregation_kind, 'sum')
    );

    IF next_value IS NULL THEN
      DELETE FROM public.tracker_state_day
      WHERE user_id = ev.user_id
        AND anchor_type = ev.anchor_type
        AND anchor_date = ev.anchor_date
        AND tracker_id = ev.tracker_id;
      RETURN;
    END IF;

    INSERT INTO public.tracker_state_day (
      user_id, anchor_type, anchor_date, tracker_id, value, last_event_id, updated_at
    )
    VALUES (
      ev.user_id, ev.anchor_type, ev.anchor_date, ev.tracker_id, next_value, ev.id, now()
    )
    ON CONFLICT (user_id, anchor_type, anchor_date, tracker_id)
    DO UPDATE SET
      value = EXCLUDED.value,
      last_event_id = EXCLUDED.last_event_id,
      updated_at = EXCLUDED.updated_at;
  END IF;
END;
$$;

-- 4) Rebuild projection state
SELECT public.rebuild_tracker_state_projections();
```

---

# Supabase Migration Requirements

## Migration Files
- Add migration A for `unit_kind` expansion.
- Add migration B for `aggregation_kind` + projection update.

## Production Deployment
- Migrations must run in production.
- Apply A then B in the same release window.
- Run B in low-traffic window due to projection rebuild.
- If destructive reset is required and explicitly approved, wipe only journal-related tables:
  - `tracker_events`
  - `tracker_state_day`
  - `tracker_state_entry`
  - `tracker_preferences`
  - `tracker_definition_choices`
  - `tracker_definitions`
  - `tracker_groups`
  - `journal_entries`

### AC
- Migration applied cleanly in prod.
- No sync failures for existing trackers.
- Projection rebuild completes and data is queryable.
- Any data wipe is explicit, approved, and scoped to journal tables only.

---

# Validation Checklist
- `dart analyze`
- Targeted widget tests for Journal Home, Quick Capture, Tracker Templates
- Regression pass for tracker creation and journal history
- Data-layer journal tests covering:
  - `aggregation_kind` mapping
  - avg reducer behavior
  - sum compatibility regression
