# Future Enhancements — Allocation + Projects as First-Class Citizens

> Audience: developers + architects
>
> Scope: forward-looking enhancements to the allocation system, focused on making
> projects first-class allocated entities alongside tasks.

## 1) Motivation

Today, allocation primarily produces a list of allocated tasks. Projects influence
allocation indirectly (e.g., pinned projects cause their tasks to be pinned), but
projects are not allocated as explicit focus anchors.

Making projects first-class in allocation enables:

- A clearer “themes + actions” day plan: a small set of focus projects plus a
  concrete set of tasks.
- Better value alignment nudges and feedback loops: projects often represent
  longer-term commitments tied to values.
- Richer analytics: measuring not just task completion, but project progress and
  sustained commitment over time.

## 2) Proposed Model: Unified Candidate Pool (Projects + Tasks)

### 2.1 Key principle

Projects and tasks can participate in a unified candidate pool, but should not be
treated identically in evaluation of “success” (projects are rarely completed
same-day).

Instead:

- Tasks are primarily “doables” (success = completion today, or short-horizon).
- Projects are “focus anchors” (success = progress today, not necessarily
  completion).

### 2.2 Shared scoring ingredients

Both tasks and projects can share a scoring framework based on:

- Value alignment weight (value labels / value affinity)
- Neglect/recency (time since last progress)
- Urgency/time sensitivity (mostly tasks)
- User intent (pinned, explicit focus)

### 2.3 Entity-specific progress potential

Projects need a different notion of progress potential than tasks.

Examples:

- Task progress potential: likelihood of completion today (proxy signals such as
  size/complexity if available).
- Project progress potential: likelihood of meaningful progress today
  (e.g., has actionable tasks, has been idle, is blocked).

## 3) Allocation Output UX: Anchors + Doables

Even if allocation uses a unified pool internally, the recommended UX is to
produce two explicit outputs:

- Allocated projects: “Focus anchors” for the day.
- Allocated tasks: “Doables” for the day.

A helpful policy is to enforce output caps:

- Min/max focus projects (e.g. 1–3)
- Min/max tasks (e.g. 5–12)

Optionally:

- Ensure at least one allocated task per allocated project when possible.

This prevents the unified pool from drifting into “all projects” or “all tasks”.

## 4) Persistence: Daily Allocation Snapshot (Versioned)

To support allocation warnings and analytics, persist allocation membership.

Recommended structure:

- A mutable pointer for today’s “current” allocation.
- Immutable versioned snapshots to retain history of changes (e.g., when the
  user requests more tasks).

Use a generic entity identity:

- (entity_type, entity_id) where entity_type is one of: task, project, …

This design supports future entity types without schema changes.

## 5) Allocation Warnings as Attention Rules (Missing-from-Allocation)

Allocation warning rules should evaluate as:

- warning set = rule_matches(entity_type) − allocated_today(entity_type)

Where:

- rule_matches are queried from domain data (tasks, projects, future entities)
- allocated_today is loaded from the persisted allocation snapshot

This replaces “excluded tasks” style warnings and avoids unbounded persistence.

### 5.1 Dismissal semantics

To ensure dismissals are “forgotten” when allocation changes, incorporate the
allocation snapshot version into the attention state hash.

Minimum state hash inputs:

- snapshot_date_utc
- allocation_version
- rule identity
- entity identity
- minimal entity state relevant to the predicate

## 6) Analytics & Feedback (Rich Stats)

### 6.1 Daily stats

Persisted allocation membership enables daily aggregates such as:

- allocated tasks/projects count
- allocated tasks completed same day
- unallocated tasks completed same day
- overdue (or urgent) tasks/projects not allocated
- number of allocation changes (versions) per day

These can be stored as analytics snapshots for fast trend reporting.

### 6.2 “Complex/Overwhelming” tasks signal

Track how often a task is allocated but not completed, e.g.:

- allocated_count_last_N_days
- allocated_not_completed_count_last_N_days
- longest “allocated-but-not-completed” streak

This is a strong signal that a task may need to be broken down.

### 6.3 Project progress signal

Because projects rarely complete same-day, define progress signals such as:

- task completions under a project (recommended v1 proxy)
- project updatedAt changes (secondary proxy; can be noisy)
- explicit project progress events (future enhancement)

Use these to drive positive feedback and “not aligned” nudges.

#### Recommended v1: progress = “any task completed under project today”

For day-based stats, treat a project as having made progress on a given UTC day
if at least one task with `project_id == project.id` has a completion record for
that day.

This keeps the model simple and user-legible:

- Projects are long-lived anchors.
- Progress is evidenced by completing project-linked tasks.

It also works without introducing new schema for project progress events.

## 7) Open Questions (to resolve during implementation)

- Definition of “project progress” beyond completion.
- Whether to allocate projects independently or derive projects from allocated
  tasks (inverse relationship).
- Which predicates should exist for project allocation warnings (idle, overdue
  milestones, no next actions, etc.).
- How to cap and sort warning outputs per rule to avoid overly large result
  sets.
