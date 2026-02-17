# Taskly Architecture Overview

This document is descriptive. Normative rules are only in [INVARIANTS.md](INVARIANTS.md).

## Layer model

Taskly uses an offline-first layered architecture:

- Presentation: screens, widgets, BLoCs, routing, screen composition.
- Domain: business semantics, contracts, use-cases, recurrence logic.
- Data: repository implementations, Drift persistence, PowerSync sync.

Dependency direction is governed by invariants:
- allowed: `presentation -> domain`, `data -> domain`
- forbidden: `presentation -> data`, `domain -> data`, `domain -> presentation`

## Runtime flow

```text
User intent -> Widget -> BLoC event -> Domain command -> Repository write
Local watchers -> Domain read contracts -> BLoC state -> Widgets render
```

## Source-of-truth boundaries

- Local database is primary UI source of truth.
- Sync converges local and backend state.
- Recurrence keys/window keys are domain-owned and deterministic.

## Where behavior lives

- Architecture invariants: `doc/architecture/INVARIANTS.md`
- Feature behavior contracts: `doc/features/README.md`
- Agent onboarding: `doc/agents/START_HERE.md`
