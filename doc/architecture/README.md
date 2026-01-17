# Taskly — Architecture (Starting Point)

> Audience: developers + architects
>
> Scope: a high-level overview of Taskly’s architecture, how key subsystems
> integrate, and where to find deeper documentation.

## 1) Big Picture

Taskly is a Flutter app with a layered architecture and an offline-first data
model:

- **Presentation** renders UI, routes navigation, and hosts feature flows.
- **Domain** implements business rules and orchestrates use-cases.
- **Data** persists locally (SQLite) and integrates with sync/backends.
- **Offline-first**: the local DB is the primary source of truth for UI; sync is
  responsible for convergence.

### 1.1 Presentation boundary rule (BLoC-only)

**Normative rule:** Widgets/pages in the presentation layer must not talk to
repositories or domain/data services directly, and must not subscribe to
non-UI streams directly.

- Presentation widgets/pages may only interact with other layers through a
  **BLoC** that is owned by the presentation layer.
- BLoCs may depend on domain services/use-cases and repository
  contracts.
- Streams belong below the widget layer: any stream subscriptions that produce
  UI state must live in the BLoC (or deeper), and the widget consumes the
  resulting BLoC state.

#### Allowed exceptions (narrow)

- **Ephemeral UI-only state** that does not represent domain/data state, such as
  `AnimationController`s, `TextEditingController`s, focus nodes, scroll
  controllers, and other widget-local concerns.
- **Already-cached UI-only streams** that do not touch repositories/services
  (for example, navigation badge streams that are derived from UI-layer state).

If an exception starts to depend on domain/data or becomes shared across screens,
promote it into a BLoC (or lower layer) and expose a BLoC state instead.

### 1.2 System-level architecture diagram

```text
+-----------------------------------------------------------------------+
|                              Presentation                             |
|  - routing / pages / widgets / feature state                           |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                                 Domain                                |
|  - business services (allocation, attention, etc.)                     |
|  - repository contracts (interfaces)                                  |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                                  Data                                 |
|  - repository implementations                                           |
|  - local persistence (Drift over SQLite/PowerSync DB)                  |
|  - sync connectors / serializers / normalization                       |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                         Sync + Backend (runtime)                       |
|  PowerSync server <-> Supabase (Postgres + PostgREST + Auth JWT/RLS)   |
+-----------------------------------------------------------------------+
```

## 2) Key Subsystems & How They Integrate

This section is intentionally high-level and focuses on *integration points*.

### 2.1 Screens + Routing

Screens are **explicit Flutter pages** with **explicit routes** (no catch-all
route-to-spec mapping). Presentation state and reactive subscriptions are owned
by presentation-layer BLoCs.

For the deeper dive see:
- [SCREEN_ARCHITECTURE.md](SCREEN_ARCHITECTURE.md)

### 2.2 Offline-first persistence + sync (PowerSync + Supabase)

The app reads/writes to a local SQLite database via Drift.

Important: PowerSync applies the client schema using SQLite views, and SQLite cannot
UPSERT (`INSERT ... ON CONFLICT DO UPDATE`) a view. Avoid Drift UPSERT helpers on
PowerSync schema tables; prefer update-then-insert or insert-or-ignore patterns.

- **UI reads**: BLoCs read from the local DB (reactive watchers) and
  drive UI updates.
- **Writes**: recorded locally and uploaded to Supabase via PostgREST.
- **Downloads**: arrive via PowerSync replication and are applied locally.

Note: in this codebase, “UI reads” means **BLoCs read from the local
DB/repositories and expose derived UI state**; widgets do not directly watch the
DB or repository streams.

#### Sync pipeline diagram

```text
Local UI <-> Drift (queries/transactions)
            |
            v
     Local SQLite (PowerSync-backed)
            |
            +--> upload connector -> Supabase PostgREST (writes; RLS enforced)
            |
            +<-- PowerSync server replication (reads; filtered by sync rules)
                              |
                              v
                      Supabase Postgres (canonical)
```

For the deeper dive see:
- [POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)

### 2.3 Attention System (rule evaluation -> support sections)

The attention system evaluates rules into user-facing “attention items” and
surfaces them in screens and settings.

Integration highlights:

- BLoCs build an `AttentionQuery` and subscribe to the engine.
- The engine combines persisted rule config, domain data, and time invalidation
  pulses.
- The output is rendered by feature screens and shared widgets.

For the deeper dive see:
- [ATTENTION_SYSTEM_ARCHITECTURE.md](ATTENTION_SYSTEM_ARCHITECTURE.md)

### 2.4 Allocation System (daily focus list -> My Day)

The allocation system computes a daily “focus list” based on user configuration
and task/project signals. The result is usually persisted as a daily snapshot so
“My Day” remains stable throughout the day.

Integration highlights:

- Allocation is invoked by domain orchestration (including time/day boundary
  triggers).
- My Day renders allocation outputs via explicit presentation widgets driven by
  a My Day BLoC.
- Allocation warnings are surfaced via the attention system.

For the deeper dive see:
- [ALLOCATION_SYSTEM_ARCHITECTURE.md](ALLOCATION_SYSTEM_ARCHITECTURE.md)

### 2.5 Journal + Statistics (entries + trackers -> trends/correlations)

The journal system captures daily qualitative + quantitative signals via:

- **Journal entries** (text + timestamps)
- **Tracker events** (e.g. mood/exercise/meds) attached to entries/days
- **Tracker definitions + preferences** (configuration, pinning, quick add)

The statistics/analytics layer consumes journal + core domain data to produce:

- mood trends and distributions
- tracker value series and correlations (factors ↔ outcomes)
- cached snapshots/insights where appropriate

Integration highlights:

- Journal screens use BLoCs that subscribe to journal repository streams.
- Analytics services query journal repositories for mood/tracker series and
  persist cached results through the analytics repository.

For the deeper dive see:
- [JOURNAL_AND_STATISTICS_ARCHITECTURE.md](JOURNAL_AND_STATISTICS_ARCHITECTURE.md)

## 3) Architecture Docs Index (This Folder)

- Architecture invariants (normative): [ARCHITECTURE_INVARIANTS.md](ARCHITECTURE_INVARIANTS.md)
- Screen architecture (future): [SCREEN_ARCHITECTURE.md](SCREEN_ARCHITECTURE.md)
- Legacy architecture overview: [LEGACY_ARCHITECTURE_OVERVIEW.md](LEGACY_ARCHITECTURE_OVERVIEW.md)
- Journal + statistics: [JOURNAL_AND_STATISTICS_ARCHITECTURE.md](JOURNAL_AND_STATISTICS_ARCHITECTURE.md)
- Screen purpose concepts: [screen_purpose_concepts.md](screen_purpose_concepts.md)
- Offline-first + sync: [POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)
- Local dev / E2E (PowerSync + Supabase): [LOCAL_SUPABASE_POWERSYNC_E2E.md](LOCAL_SUPABASE_POWERSYNC_E2E.md)
- Allocation: [ALLOCATION_SYSTEM_ARCHITECTURE.md](ALLOCATION_SYSTEM_ARCHITECTURE.md)
- Attention: [ATTENTION_SYSTEM_ARCHITECTURE.md](ATTENTION_SYSTEM_ARCHITECTURE.md)
- Recurrence + sync contract: [RECURRENCE_SYNC_CONTRACT.md](RECURRENCE_SYNC_CONTRACT.md)
- Testing: [TESTING_ARCHITECTURE.md](TESTING_ARCHITECTURE.md)

## Appendix A — Directory Layout (Conceptual)

A concise “where does this belong?” map.

### A.1 `lib/` (application source)

- `lib/app/` — app shell composition and app-level wiring
- `lib/core/` — dependency injection + cross-cutting infrastructure
- `lib/domain/` — business rules, domain models, and contracts
- `lib/data/` — repository implementations, persistence, and sync/backends
- `lib/presentation/` — routing, pages, widgets, and state management
- `lib/shared/` — shared utilities/building blocks (keep broadly reusable)
- `lib/l10n/` — localization resources

### A.2 Project root (supporting folders)

- `test/` — tests (unit/widget/integration), typically organized by layer/feature
- `tool/` — developer scripts and local automation
- `supabase/` — migrations and Supabase-related configuration
- `infra/` — local stack/runtime infrastructure (e.g., docker compose)
- `android/`, `ios/`, `macos/`, `windows/`, `web/` — Flutter platform hosts
- `doc/` — documentation (this folder is the architecture entrypoint)
