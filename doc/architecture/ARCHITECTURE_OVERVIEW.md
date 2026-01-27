# Taskly -- Architecture Overview

> Audience: developers + AI agents
>
> Scope: a **high-level mental model** of Taskly's architecture: layers,
> responsibilities, and how data flows through the app.
>
> This document is **descriptive** (non-normative). All non-negotiable rules
> live in: [INVARIANTS.md](INVARIANTS.md)

## 1) Big picture

Taskly is an offline-first Flutter app with a layered architecture:

- **Presentation**: screens, routing, widgets, BLoCs (screen-shaped reactive
  composition).
- **Domain**: business semantics, use-cases, and repository contracts.
- **Data**: repository implementations, Drift persistence, sync connectors.

Offline-first means the **local SQLite database is the primary source of truth
for UI**, and sync is responsible for convergence with the backend.

## 2) System diagram (conceptual)

```text
+-----------------------------------------------------------------------+
|                              Presentation                             |
|  - routing / pages / widgets / feature state (BLoCs)                   |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                                 Domain                                |
|  - business semantics + use-cases                                      |
|  - repository contracts (interfaces)                                  |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                                  Data                                 |
|  - repository implementations                                          |
|  - local persistence (Drift over PowerSync-backed SQLite)              |
|  - sync connectors / serializers / normalization                       |
+------------------------------------+----------------------------------+
                                     |
                                     v
+-----------------------------------------------------------------------+
|                         Sync + Backend (runtime)                       |
|  PowerSync server <-> Supabase (Postgres + PostgREST + Auth JWT/RLS)   |
+-----------------------------------------------------------------------+
```

## 3) How screens work (typical flow)

```text
User intent -> Widget -> BLoC event -> Domain use-case -> Repository write
Local DB watchers -> Repository stream -> BLoC state -> Widgets render
```

The key architectural move is that **BLoCs own subscriptions** and widgets are
render-only.

Canonical rule: [INVARIANTS.md](INVARIANTS.md) (Presentation
boundary).

### 3.1 Session-shared streams (presentation)

Some data is shared across multiple screens (values list, inbox counts,
incomplete projects). These are provided as **session-shared streams** in the
presentation layer and are kept warm via a session cache manager. Session
streams pause on background unless explicitly exempted, and screens consume
them via query/services rather than direct repository subscriptions.

## 4) Where code goes (feature slice map)

Use this as a quick orientation when adding a new feature or screen. Paths are
examples; follow existing feature naming.

Presentation (screen + BLoC):
- Screen widgets and routing: `lib/presentation/features/<feature>/`
- BLoC + events/state: `lib/presentation/features/<feature>/bloc/`
- Screen-local widgets: `lib/presentation/features/<feature>/widgets/`

Domain (business semantics):
- Use-cases/write facades: `packages/taskly_domain/lib/src/<feature>/use_cases/`
- Domain models/entities: `packages/taskly_domain/lib/src/<feature>/model/`
- Repository contracts: `packages/taskly_domain/lib/src/<feature>/contracts/`

Data (persistence + sync):
- Repository implementations: `packages/taskly_data/lib/src/<feature>/`
- Drift tables/DAOs: `packages/taskly_data/lib/src/persistence/`
- Sync adapters/serializers: `packages/taskly_data/lib/src/sync/`

Shared UI (reusable visuals only):
- Primitives/entities/sections: `packages/taskly_ui/lib/src/`

Related vocabulary: [GLOSSARY.md](GLOSSARY.md)

## 5) Where to read next

- Non-negotiable rules (single source of truth): [INVARIANTS.md](INVARIANTS.md)
- Screen patterns and BLoC guidance: [guides/BLOC_GUIDELINES.md](guides/BLOC_GUIDELINES.md)
- Screen composition and routing notes: [guides/SCREEN_ARCHITECTURE.md](guides/SCREEN_ARCHITECTURE.md)
- Sync deep dive: [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)
- Local E2E stack runbook: [runbooks/LOCAL_E2E_STACK.md](runbooks/LOCAL_E2E_STACK.md)
- Recurrence sync contract: [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)


