# Phase 02 — New domain API and model (attention bounded context)

## Outcome

- A new, cohesive attention “bounded context” exists under a single root folder.
- Domain API is explicit and stable (so future evaluators/scheduling/notifications can plug in).
- No dual-path runtime behavior: old APIs are removed only when their replacement is wired.

## Scope

- Create new domain types and contracts:
  - A single query object (with filters) to request attention.
  - Stable domain/category axes in outputs.
  - A runtime-state concept in the domain (mirrors DB table).

## Constraints

- Do not touch or run tests.
- Keep compilation and run `flutter analyze` at the end.

## Proposed folder layout

Create a new root:

- `lib/domain/attention/`
  - `model/` (rule, resolution, item, severity, domain/category)
  - `query/` (`AttentionQuery` + filter types)
  - `contracts/` (repository + engine contracts)
  - `services/` (pure domain services, no Flutter)

This is a big-bang end state: once phase 05 lands, legacy attention domain folders should be deleted.

## Steps

1) Define the domain primitives

- `AttentionDomain` (string or enum-like wrapper): persisted in rule.
- `AttentionCategory` (string or enum-like wrapper): persisted in rule.
- `AttentionSeverity` (existing concept; keep consistent with DB).

2) Define the query API (single query, filterable)

- Add `AttentionQuery` with:
  - `Set<String> entityTypes` (or a typed equivalent)
  - `AttentionSeverity? minSeverity`
  - `Set<String>? domains`
  - `Set<String>? categories`
  - Optional “limit” constraints per surface (kept in interpreter/UI policy, not the engine).

The goal is:
- interpreters use one API and do not hardcode rule-type distinctions.
- filtering is explicit and composable.

3) Define the contract surface

- `AttentionEngineContract` (or similarly named):
  - `Stream<List<AttentionItem>> watch(AttentionQuery query)`
  - `Future<void> dismiss(...) / snooze(...) / resolve(...)` (depending on policy)

- `AttentionRepositoryContract`:
  - CRUD for `AttentionRule`
  - persistence for `AttentionResolution`
  - runtime state read/write (`attention_rule_runtime_state`)

4) Prepare the legacy deletion map (not executed yet)

- Document which existing legacy APIs will be deleted in Phase 05 when cutover happens.
- Identify legacy “evaluation entrypoints” that currently exist (e.g. evaluator methods called by section interpreters).

5) Compile + analyze checkpoint

- Run: `flutter analyze`

## Big-bang rule (how to avoid dual-path)

- In this phase, do not wire the new domain API into existing interpreters.
- This phase is about introducing the new stable API surface only.
- Any new classes added must be unused until the cutover phase, to avoid a partial migration.

## Delete list (big-bang rule)

- None yet (we have not replaced runtime behavior).

## Exit criteria

- New domain folder exists with cohesive API.
- No call sites changed yet.
- `flutter analyze` passes.
