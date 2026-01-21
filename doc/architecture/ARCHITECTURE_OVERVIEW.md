# Taskly — Architecture Overview

> Audience: developers + AI agents
>
> Scope: a **high-level mental model** of Taskly’s architecture: layers,
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

## 4) Where to read next

- Non-negotiable rules (single source of truth): [INVARIANTS.md](INVARIANTS.md)
- Screen patterns and BLoC guidance: [guides/BLOC_GUIDELINES.md](guides/BLOC_GUIDELINES.md)
- Screen composition and routing notes: [guides/SCREEN_ARCHITECTURE.md](guides/SCREEN_ARCHITECTURE.md)
- Sync deep dive: [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)
- Local E2E stack runbook: [runbooks/LOCAL_E2E_STACK.md](runbooks/LOCAL_E2E_STACK.md)
- Recurrence sync contract: [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)
