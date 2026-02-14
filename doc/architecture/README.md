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
- Screen data pipeline (reactive loading pattern): [guides/SCREEN_DATA_PIPELINE.md](guides/SCREEN_DATA_PIPELINE.md)
- Screen composition + routing: [guides/SCREEN_ARCHITECTURE.md](guides/SCREEN_ARCHITECTURE.md)
- Navigation + screen keys: [guides/NAVIGATION_AND_SCREEN_KEYS.md](guides/NAVIGATION_AND_SCREEN_KEYS.md)
- Session stream cache: [guides/SESSION_STREAM_CACHE.md](guides/SESSION_STREAM_CACHE.md)
- Screen actions + tile intents: [guides/SCREEN_ACTIONS_AND_TILE_INTENTS.md](guides/SCREEN_ACTIONS_AND_TILE_INTENTS.md)
- Shared UI governance and patterns: [guides/TASKLY_UI_GOVERNANCE.md](guides/TASKLY_UI_GOVERNANCE.md)
- "Style, not config" pattern: [guides/TASKLY_UI_STYLE_NOT_CONFIG.md](guides/TASKLY_UI_STYLE_NOT_CONFIG.md)
- Error handling + failure mapping: [guides/ERROR_HANDLING_AND_FAILURES.md](guides/ERROR_HANDLING_AND_FAILURES.md)
- Testing guide (policy + taxonomy; invariants live in INVARIANTS):
  [guides/TESTING_ARCHITECTURE.md](guides/TESTING_ARCHITECTURE.md)
- New feature checklist: [guides/NEW_FEATURE_CHECKLIST.md](guides/NEW_FEATURE_CHECKLIST.md)

## Deep dives (subsystems)

- Sync pipeline: [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)
- Attention system: [deep_dives/ATTENTION_SYSTEM.md](deep_dives/ATTENTION_SYSTEM.md)
- Journal + analytics: [deep_dives/JOURNAL_AND_STATISTICS.md](deep_dives/JOURNAL_AND_STATISTICS.md)
- Notifications (pending): [deep_dives/NOTIFICATIONS.md](deep_dives/NOTIFICATIONS.md)
- Suggested picks (allocation): [deep_dives/SUGGESTED_PICKS.md](deep_dives/SUGGESTED_PICKS.md)
- My Day + Plan My Day: [deep_dives/MY_DAY_PLAN_MY_DAY.md](deep_dives/MY_DAY_PLAN_MY_DAY.md)

## Specs (locked implementer contracts)

- Recurrence + sync contract: [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)
- Taskly UI material alignment (Option B):
  [specs/TASKLY_UI_MATERIAL_ALIGNMENT_OPTION_B.md](specs/TASKLY_UI_MATERIAL_ALIGNMENT_OPTION_B.md)

## Runbooks (operational)

- Local Supabase + PowerSync stack: [runbooks/LOCAL_E2E_STACK.md](runbooks/LOCAL_E2E_STACK.md)

## Tooling

- Validate architecture doc links: [tool/validate_arch_doc_links.dart](../../tool/validate_arch_doc_links.dart)

## Product meaning

Product intent lives outside architecture:
- [doc/product/README.md](../product/README.md)

## Glossary

- [GLOSSARY.md](GLOSSARY.md)
