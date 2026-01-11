# Design Decisions Summary (Current)

This document records design decisions that are considered *settled* based on
recent architecture work and clarifications. It intentionally excludes
“pending work”, “nice-to-haves”, and speculative ideas.

## Terminology

- **Allocation**: the set of items explicitly selected for “My Day / Focus”.
- **Allocation snapshot**: persisted record of what was allocated for a given
  UTC day.
- **Allocation warning**: an attention item indicating something *should have*
  been allocated (per rules/scoring) but is not in the allocated set.
- **Entity**: an allocatable unit (currently tasks; projects are treated as
  first-class for selection and stats).

## Allocation Snapshots

### Persist allocated membership only

- Allocation persistence stores only the **allocated membership** for the day.
- We do **not** persist “excluded tasks” or any “not chosen” lists.

Rationale:
- “Excluded” sets are unbounded and unstable, making snapshot comparisons noisy.
- The allocated set is the only stable, user-meaningful fact: “what My Day is”.

### Snapshot scope and time basis

- Allocation is scoped as a single, global allocation set (effectively per-user
  global scope).
- The “day” key is based on **UTC day bucketing**.

### Latest snapshot wins + version bump

- A single UTC day can have multiple allocation recalculations (e.g. “load more”).
- The persisted snapshot for a day is **overwritten** when allocation changes.
- Each overwrite increments an **allocation version**.

Rationale:
- The UI and attention system should reflect the most recent allocation.
- The version provides a deterministic “state boundary” for dismissals.

## Allocation Warnings (Attention Integration)

### Warnings = rule matches minus allocated set

Allocation warnings are derived as:

- **Warning candidates** = (entities matching a warning rule)
- **Actual warnings** = (warning candidates) \ (allocated entities)

This makes warnings disappear immediately when the entity becomes allocated.

### Dismissals are forgotten on allocation change

- Allocation warning dismissals are intentionally ephemeral.
- A change in allocation snapshot version should invalidate prior dismissals.

Implementation note (decision-level):
- The attention `state_hash` for allocation warnings must incorporate
  `allocation_date` (UTC day) and `allocation_version` so that dismissals do not
  survive a new snapshot.

## Projects as First-Class

### Projects are first-class for allocation and stats

- Allocation logic and warning rules must support **projects** as entities.
- “My Day” presentation is **task-focused** but projects are a first-class
  conceptual unit for:
  - allocation coverage,
  - progress coaching,
  - “no next action” detection.

### My Day UX: tasks grouped by project

- My Day should present a **flat task list grouped by project** (the “B” shape).
- This aligns with the reality that most work lives under projects; Inbox is for
  sorting, not execution.

## Progress / Analytics (Foundational Rules)

### Authoritative completion source

- Completion-time and “completed today/this week” stats should be computed from
  **completion history** sources (not `occurrence.completedAt` where it is
  optional/unreliable).

### Project progress proxy (v1)

- Project progress (v1) is measured via a proxy:
  - A project is considered “progressed today” if **any task under that project
    was completed today** (UTC day).

This proxy is intentionally minimal and measurable with existing completion
history.

## Scoring Semantics: Value vs Neglect

### “High value” and “neglect” are algorithm outputs

- “High value” and “neglect” are treated as **outputs of a scoring algorithm**
  (not a simple “days since touched” heuristic).

### Value and neglect are separate scores

- Value and neglect are modeled as separate signals.
- Experiences/alerts may combine them (e.g., “high value + high neglect”), but
  neglect is not required to be mathematically derived from value.

## Non-goals (Explicit)

- Persisting an “excluded list” (or types of exclusions) as part of daily
  allocation snapshots.
- Long-lived dismissal state for allocation warnings.
- Adding new UX surfaces beyond the agreed My Day grouping and attention rules.
