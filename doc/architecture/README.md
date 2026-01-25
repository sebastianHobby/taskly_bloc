# Taskly — Architecture (Starting Point)

> Audience: developers + architects
>
> Scope: a high-level overview of Taskly’s architecture, how key subsystems
> integrate, and where to find deeper documentation.

## 1) Big Picture

Taskly is a Flutter app with a layered architecture and an offline-first data
model:

- **Presentation** renders UI, routes navigation, and hosts feature flows.
- **Domain** implements business semantics and orchestrates use-cases.
- **Data** persists locally (SQLite) and integrates with sync/backends.
- **Offline-first**: the local DB is the primary source of truth for UI; sync is
  responsible for convergence.

Boundary rule of thumb:

- Domain outputs are **view-neutral** (no screen models, no UI strings).
- Presentation owns screen-shaped policy (composition, sectioning, paging,
  # Taskly — Architecture Docs

  > Audience: developers + AI agents
  >
  > Goal: a **clear architectural overview** + a single place for **normative
  > invariants**.

  ## Start here (10 minutes)

  1) Architecture mental model (descriptive): [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
  2) Non-negotiable rules (normative, single source of truth):
     [INVARIANTS.md](INVARIANTS.md)

  If you need to violate a guardrail, follow:
  - [EXCEPTIONS.md](EXCEPTIONS.md)

  ## Guides (how to build)

  These are descriptive playbooks. They must not introduce new “must” rules.

  - BLoC patterns and stream safety: [guides/BLOC_GUIDELINES.md](guides/BLOC_GUIDELINES.md)
  - Screen composition + routing: [guides/SCREEN_ARCHITECTURE.md](guides/SCREEN_ARCHITECTURE.md)
  - Shared UI governance and patterns: [guides/TASKLY_UI_GOVERNANCE.md](guides/TASKLY_UI_GOVERNANCE.md)
- “Style, not config” pattern: [guides/TASKLY_UI_STYLE_NOT_CONFIG.md](guides/TASKLY_UI_STYLE_NOT_CONFIG.md)
  - Testing guide (policy + taxonomy; invariants live in INVARIANTS):
    [guides/TESTING_ARCHITECTURE.md](guides/TESTING_ARCHITECTURE.md)

  ## Deep dives (subsystems)

  - Sync pipeline: [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)
  - Attention system: [deep_dives/ATTENTION_SYSTEM.md](deep_dives/ATTENTION_SYSTEM.md)
  - Journal + analytics: [deep_dives/JOURNAL_AND_STATISTICS.md](deep_dives/JOURNAL_AND_STATISTICS.md)
  - Suggested picks (allocation): [deep_dives/SUGGESTED_PICKS.md](deep_dives/SUGGESTED_PICKS.md)

  ## Specs (locked implementer contracts)

  - Recurrence + sync contract: [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)

  ## Runbooks (operational)

  - Local Supabase + PowerSync E2E stack: [runbooks/LOCAL_E2E_STACK.md](runbooks/LOCAL_E2E_STACK.md)

  ## Product meaning

  Product intent lives outside architecture:
  - [doc/product/README.md](../product/README.md)
### A.2 Project root (supporting folders)

- `test/` — tests (unit/widget/integration), typically organized by layer/feature
- `tool/` — developer scripts and local automation
- `supabase/` — migrations and Supabase-related configuration
- `infra/` — local stack/runtime infrastructure (e.g., docker compose)
- `android/`, `ios/`, `macos/`, `windows/`, `web/` — Flutter platform hosts
- `doc/` — documentation (this folder is the architecture entrypoint)
