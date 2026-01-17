# Journal + Statistics — Architecture Overview

> Audience: developers + architects
>
> Scope: the Journal system (entries + trackers) and how it feeds the
> Statistics/Analytics subsystem (trends, distributions, correlations, snapshots).

## 1) Executive Summary

Taskly’s **Journal system** is an offline-first, event-log oriented subsystem
that lets users:

- create **journal entries** (text + timestamps)
- record structured **tracker events** (mood, exercise, meds, etc.) anchored to
  an entry or day
- manage **tracker definitions** and **user preferences** (pinning, ordering,
  quick-add)

The Journal is intentionally designed to support higher-order **statistics**:

- time-series trends (e.g., mood trend)
- distributions (e.g., mood histogram)
- correlations (e.g., “exercise ↔ mood”) and derived insights
- daily snapshots for entities (tasks/projects/values) and/or journal-derived
  metrics

Architecturally:

- **Presentation** renders Journal pages and consumes reactive state from BLoCs.
- **Domain** defines the models, repository contracts, and analytics services.
- **Data** persists locally with Drift (PowerSync-backed) and implements
  repository contracts.

Normative presentation boundary: widgets do not call repositories directly and
must not subscribe to domain/data streams directly. BLoCs own subscriptions and
expose widget-friendly state.

---

## 2) Where Things Live (Folder Map)

### Journal domain (models + system templates)
- Journal models:
  - [lib/domain/journal/model/](../../lib/domain/journal/model/)
- System tracker templates (seed set):
  - [lib/domain/journal/system_trackers.dart](../../lib/domain/journal/system_trackers.dart)

Key model files:
- [lib/domain/journal/model/journal_entry.dart](../../lib/domain/journal/model/journal_entry.dart)
- [lib/domain/journal/model/tracker_definition.dart](../../lib/domain/journal/model/tracker_definition.dart)
- [lib/domain/journal/model/tracker_event.dart](../../lib/domain/journal/model/tracker_event.dart)
- [lib/domain/journal/model/tracker_preference.dart](../../lib/domain/journal/model/tracker_preference.dart)
- [lib/domain/journal/model/tracker_state_day.dart](../../lib/domain/journal/model/tracker_state_day.dart)
- [lib/domain/journal/model/tracker_state_entry.dart](../../lib/domain/journal/model/tracker_state_entry.dart)

### Journal contract + implementation
- Repository contract:
  - [lib/domain/interfaces/journal_repository_contract.dart](../../lib/domain/interfaces/journal_repository_contract.dart)
- Repository implementation:
  - [lib/data/features/journal/repositories/journal_repository_impl.dart](../../lib/data/features/journal/repositories/journal_repository_impl.dart)

### Journal bootstrapping/maintenance
- Seeder (system trackers):
  - [lib/data/features/journal/maintenance/journal_tracker_seeder.dart](../../lib/data/features/journal/maintenance/journal_tracker_seeder.dart)

### Screen integration

Journal is exposed through explicit screens/pages driven by presentation-layer
BLoCs.

### Journal presentation (BLoCs + pages)
- Hub (tabs):
  - [lib/presentation/features/journal/view/journal_hub_page.dart](../../lib/presentation/features/journal/view/journal_hub_page.dart)
- BLoCs/cubits:
  - [lib/presentation/features/journal/bloc/](../../lib/presentation/features/journal/bloc/)

### Analytics/statistics
- Analytics service implementation:
  - [lib/data/features/analytics/services/analytics_service_impl.dart](../../lib/data/features/analytics/services/analytics_service_impl.dart)
- Analytics repository contract + implementation:
  - [lib/domain/interfaces/analytics_repository_contract.dart](../../lib/domain/interfaces/analytics_repository_contract.dart)
  - [lib/data/features/analytics/repositories/analytics_repository_impl.dart](../../lib/data/features/analytics/repositories/analytics_repository_impl.dart)
- Correlation calculation (stats math):
  - [lib/domain/services/analytics/correlation_calculator.dart](../../lib/domain/services/analytics/correlation_calculator.dart)

---

## 3) Journal System Architecture

### 3.1 Core concept: event log + projections

The Journal tracker subsystem follows an **event log** approach:

- **`TrackerEvent`** rows are appended for user interactions (e.g. mood=4)
- **projections** (state tables/views) provide fast read models:
  - **`TrackerStateEntry`**: tracker state anchored to an entry
  - **`TrackerStateDay`**: tracker state aggregated/anchored to a day

This enables:

- immediate UI reflection by reading raw events (useful for “Today”)
- efficient analytics by querying projections (for heavier aggregation)

### 3.2 Persistence model (conceptual)

The exact Drift schema is defined in the Drift database layer, but conceptually:

```text
journal_entries
  - id
  - entry_date (UTC day bucket)
  - entry_time / occurred_at / local_date
  - journal_text
  - created_at / updated_at / deleted_at

tracker_definitions
  - id
  - name / description
  - scope (entry/day)
  - value_type / value_kind / op_kind
  - config / goal (json)
  - system_key (optional)
  - is_active / deleted_at

tracker_preferences
  - tracker_id
  - pinned / show_in_quick_add / sort_order

tracker_events
  - id
  - tracker_id
  - anchor_type ('entry' today; potentially others)
  - entry_id (optional)
  - anchor_date (optional)
  - value (typed via value_kind, stored in json-ish payload)
  - occurred_at

tracker_state_entry
tracker_state_day
  - projection rows for fast reads
```

Important write constraint (PowerSync + SQLite views): avoid Drift UPSERT helpers
that emit `ON CONFLICT` clauses against PowerSync schema tables. Prefer
update-then-insert or insert-or-ignore patterns.

See:
- [POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)

### 3.3 Seeding system trackers

The Journal seeds a small “safe” system tracker set (e.g. mood/exercise/meds).
The templates live in `SystemTrackers` and are inserted idempotently by a
maintenance/seeding component.

Design intent:

- system trackers provide a stable default UX
- system keys (e.g. `mood`) allow business logic to find key trackers without
  hardcoding DB IDs

### 3.4 Screen integration (Journal)

Journal screens subscribe to repository streams through BLoCs:

- BLoCs combine tracker definitions, entry streams, and event streams.
- Widgets render the BLoC state.

Legacy USM integration details are documented only in:
- [LEGACY_ARCHITECTURE_OVERVIEW.md](LEGACY_ARCHITECTURE_OVERVIEW.md)

---

## 4) Statistics / Analytics Architecture

### 4.1 What “Statistics” means in Taskly

In this repo, “statistics” spans several related concerns:

- **task stats** (e.g., completion rate) computed from task streams
- **value stats** and activity-derived signals
- **journal-derived stats** (mood trend/distribution, tracker correlations)
- **snapshots** (cached daily/periodic metrics) stored in `analytics_snapshots`
- **correlations** and **insights** persisted as cached results

### 4.2 Service layout

The primary orchestration layer is `AnalyticsServiceImpl` which composes:

- repositories for reading raw domain entities (tasks/projects/values)
- `JournalRepositoryContract` for journal/tracker reads
- `AnalyticsRepositoryContract` for caching snapshots/correlations/insights
- calculators (e.g. `TaskStatsCalculator`, `CorrelationCalculator`)

This keeps heavy computation out of widgets and allows caching/persistence where
appropriate.

### 4.3 Correlations (journal factors ↔ outcomes)

Correlation computation uses a dedicated calculator that operates on series
extracted from journal tracker projections or event streams.

Key design points:

- **Outcome vs factor**: trackers can be marked `isOutcome` (e.g. mood)
- **Series alignment**: correlations rely on consistent anchoring and date
  bucketing (typically daily)
- **Caching**: computed correlations are persisted via
  `AnalyticsRepositoryContract.saveCorrelation(s)` for reuse

### 4.4 UI surfaces

Current UI surfaces include:

- Value detail statistics modal(s) (trend charts etc.)
- A system screen `statistics` wired to a `statisticsDashboard` template, which
  is currently a placeholder UI

Entry points:

- [lib/domain/screens/catalog/system_screens/system_screen_specs.dart](../../lib/domain/screens/catalog/system_screens/system_screen_specs.dart)
- [lib/presentation/screens/templates/screen_template_widget.dart](../../lib/presentation/screens/templates/screen_template_widget.dart)

---

## 5) Operational Notes & Invariants

### 5.1 Ownership and layering

- Widgets must not talk to repositories/services directly.
- BLoCs own subscriptions and expose derived state.
- Domain must not import presentation.
- Data implementations must be hidden behind contracts.

### 5.2 Performance

- Prefer projections for analytics-heavy queries.
- Prefer caching (snapshots/correlations) when computations are expensive.
- When streaming, isolate section failures at the module level (do not fail the
  whole screen stream for a single failing section).

---

## 6) Open Edges / Next Steps (Documentation-only)

This document describes the current system as implemented. Likely next steps
for the product/architecture:

- Replace the `statisticsDashboard` placeholder with an explicit statistics
  dashboard screen driven by a presentation-layer BLoC.
- Define stable “journal stats” read models/APIs for commonly requested
  analytics (mood trend, distributions, correlations).
- Decide which computations should be *purely derived* vs *persisted* (snapshots)
  for offline speed and sync friendliness.
