# Taskly -- Architecture Docs

> Audience: developers + AI agents
>
> Goal: a clear entrypoint to the architectural overview, invariants, and
> implementation guides.

## Start here (10 minutes)

1) Mental model (descriptive): [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
2) Non-negotiable rules (normative, single source of truth):
   [INVARIANTS.md](INVARIANTS.md)

If you need to violate a guardrail, follow:
- [EXCEPTIONS.md](EXCEPTIONS.md)

## Guides (how to build)

These are descriptive playbooks. They must not introduce new "must/shall" rules.

- BLoC patterns and stream safety: [guides/BLOC_GUIDELINES.md](guides/BLOC_GUIDELINES.md)
- Screen composition + routing: [guides/SCREEN_ARCHITECTURE.md](guides/SCREEN_ARCHITECTURE.md)
- Shared UI governance and patterns: [guides/TASKLY_UI_GOVERNANCE.md](guides/TASKLY_UI_GOVERNANCE.md)
- "Style, not config" pattern: [guides/TASKLY_UI_STYLE_NOT_CONFIG.md](guides/TASKLY_UI_STYLE_NOT_CONFIG.md)
- Testing guide (policy + taxonomy; invariants live in INVARIANTS):
  [guides/TESTING_ARCHITECTURE.md](guides/TESTING_ARCHITECTURE.md)
- New feature checklist: [guides/NEW_FEATURE_CHECKLIST.md](guides/NEW_FEATURE_CHECKLIST.md)

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

## Glossary

- [GLOSSARY.md](GLOSSARY.md)
