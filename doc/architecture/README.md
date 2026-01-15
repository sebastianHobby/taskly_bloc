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

### 1.2 Presentation boundary rule (BLoC-only)

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

### 1.1 System-level architecture diagram

```text
+-----------------------------------------------------------------------+
|                              Presentation                             |
|  - routing / pages / widgets / feature state                           |
|  - unified screen renderers (template-specific UI)                     |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                                 Domain                                |
|  - screen interpretation pipeline (spec -> section VMs)                |
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

### 2.1 Unified Screen Model (primary UI composition mechanism)

Most screens are assembled from typed, declarative screen specs composed of
screen templates and typed modules.

Key idea:

- Presentation asks the domain layer to interpret a `ScreenSpec`.
- The domain layer executes typed module interpreters to produce section view-models.
- Presentation renders those view-models through template-specific widgets.

#### Unified screen pipeline diagram

```text
Route -> Screen key
  -> load ScreenSpec (system screens + persisted preferences)
  -> interpret modules (domain):
       ScreenModuleSpec + typed params -> interpreter -> SectionVm (stream)
  -> combine all sections into ScreenSpecData (stream)
  -> render (presentation): UnifiedScreenPageFromSpec + SectionWidget switch
```

For the deeper dive see:
- [UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)
  - non-negotiable invariants (how to avoid layering drift)
  - ED/RD outline (routing + editor/detail data contract)
  - decision guide (module vs template vs params/variant vs enrichment)
  - mutations boundary (`ScreenActionsBloc`) and error surfacing

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
surfaces them in unified screen support sections and settings.

Integration highlights:

- Section interpreters build an `AttentionQuery` and subscribe to the engine.
- The engine combines persisted rule config, domain data, and time invalidation
  pulses.
- The output is rendered by template-specific support section widgets.

For the deeper dive see:
- [ATTENTION_SYSTEM_ARCHITECTURE.md](ATTENTION_SYSTEM_ARCHITECTURE.md)

### 2.4 Allocation System (daily focus list -> My Day)

The allocation system computes a daily “focus list” based on user configuration
and task/project signals. The result is usually persisted as a daily snapshot so
“My Day” remains stable throughout the day.

Integration highlights:

- Allocation is invoked by domain orchestration (including time/day boundary
  triggers).
- My Day renders allocation outputs via the shared hierarchy/list primary section,
  with membership/order driven by the allocation snapshot (and optional V2
  enrichment consumed by the renderer).
- Allocation warnings are surfaced via the attention system’s allocation alerts.

For the deeper dive see:
- [ALLOCATION_SYSTEM_ARCHITECTURE.md](ALLOCATION_SYSTEM_ARCHITECTURE.md)

## 3) Architecture Docs Index (This Folder)

- Unified screens: [UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)
- Screen purpose concepts: [screen_purpose_concepts.md](screen_purpose_concepts.md)
- Offline-first + sync: [POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md](POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md)
- Allocation: [ALLOCATION_SYSTEM_ARCHITECTURE.md](ALLOCATION_SYSTEM_ARCHITECTURE.md)
- Attention: [ATTENTION_SYSTEM_ARCHITECTURE.md](ATTENTION_SYSTEM_ARCHITECTURE.md)
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
